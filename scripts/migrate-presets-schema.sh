#!/bin/bash
set -e

echo "=== Halext Org: Layout Presets Schema Migration ==="
echo ""
echo "This script will add is_system and owner_id columns to layout_presets table."
echo ""

# Detect OS
OS_TYPE="$(uname -s)"
echo "Detected OS: $OS_TYPE"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Source environment variables from .env if it exists
if [ -f "backend/.env" ]; then
    set -a
    source backend/.env
    set +a
fi

# Get DATABASE_URL from environment or use default
DATABASE_URL=${DATABASE_URL:-"sqlite:///halext_dev.db"}

echo "Using DATABASE_URL: ${DATABASE_URL}"
echo ""

# Extract database info (works on both GNU and BSD sed)
if [[ $DATABASE_URL == postgresql* ]]; then
    DB_USER=$(echo "$DATABASE_URL" | sed -E 's|.*://([^:]+):.*|\1|')
    DB_NAME=$(echo "$DATABASE_URL" | sed -E 's|.*/([^?]+).*|\1|')
    echo "Database type: PostgreSQL"
    echo "Database user: $DB_USER"
    echo "Database name: $DB_NAME"
elif [[ $DATABASE_URL == sqlite* ]]; then
    DB_FILE=$(echo "$DATABASE_URL" | sed -E 's|sqlite:///||')
    echo "Database type: SQLite"
    echo "Database file: $DB_FILE"
else
    echo "Unsupported database type"
    exit 1
fi
echo ""

read -p "Continue with migration? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Migration cancelled."
    exit 1
fi

echo ""
echo "Running migration..."

cd backend

# Find Python 3 interpreter
PYTHON_CMD=""

if [ -f "env/bin/python3" ]; then
    # Virtual environment with Python 3
    PYTHON_CMD="env/bin/python3"
elif [ -f "env/bin/python" ]; then
    # Check if it's Python 3
    if env/bin/python --version 2>&1 | grep -q "Python 3"; then
        PYTHON_CMD="env/bin/python"
    fi
fi

# If no venv or venv doesn't have Python 3, try system Python 3
if [ -z "$PYTHON_CMD" ]; then
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        echo "Warning: No virtual environment found, using system Python 3"
        echo "Consider creating a venv: python3 -m venv env"
    else
        echo "Error: Python 3 not found"
        echo "Please install Python 3 or create a virtual environment"
        exit 1
    fi
fi

echo "Using Python: $($PYTHON_CMD --version 2>&1)"
echo ""

$PYTHON_CMD << 'EOF'
import sys
from sqlalchemy import create_engine, text, inspect
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///halext_dev.db")
print(f"Connecting to: {DATABASE_URL.split('@')[0] if '@' in DATABASE_URL else DATABASE_URL}")

try:
    engine = create_engine(DATABASE_URL)
    is_sqlite = DATABASE_URL.startswith('sqlite')

    with engine.connect() as conn:
        # Check if layout_presets table exists
        inspector = inspect(engine)
        tables = inspector.get_table_names()

        if 'layout_presets' not in tables:
            print("✗ Table 'layout_presets' does not exist yet.")
            print("  Run the backend once to create tables, then run this migration.")
            sys.exit(1)

        # Check if columns already exist
        columns = [col['name'] for col in inspector.get_columns('layout_presets')]

        if 'is_system' in columns and 'owner_id' in columns:
            print("✓ Columns already exist. No migration needed.")
        else:
            # Add new columns
            if 'is_system' not in columns:
                print("Adding is_system column...")
                if is_sqlite:
                    # SQLite doesn't support ALTER TABLE ADD COLUMN with DEFAULT on older versions
                    conn.execute(text("ALTER TABLE layout_presets ADD COLUMN is_system INTEGER DEFAULT 0"))
                else:
                    conn.execute(text("ALTER TABLE layout_presets ADD COLUMN is_system BOOLEAN DEFAULT FALSE"))
                conn.commit()
                print("✓ Added is_system column")

            if 'owner_id' not in columns:
                print("Adding owner_id column...")
                conn.execute(text("ALTER TABLE layout_presets ADD COLUMN owner_id INTEGER"))
                conn.commit()
                print("✓ Added owner_id column")

            # Add foreign key constraint (PostgreSQL only)
            if not is_sqlite:
                print("Adding foreign key constraint...")
                try:
                    conn.execute(text("""
                        ALTER TABLE layout_presets
                        ADD CONSTRAINT fk_layout_presets_owner
                        FOREIGN KEY (owner_id) REFERENCES users(id)
                    """))
                    conn.commit()
                    print("✓ Added foreign key constraint")
                except Exception as e:
                    if "already exists" in str(e).lower():
                        print("✓ Foreign key constraint already exists")
                    else:
                        # Non-critical, continue
                        print(f"⚠ Could not add foreign key: {e}")
            else:
                print("⚠ SQLite: Skipping foreign key constraint (not supported in ALTER TABLE)")

            # Mark existing presets as system presets
            print("Marking existing presets as system presets...")
            if is_sqlite:
                result = conn.execute(text("UPDATE layout_presets SET is_system = 1 WHERE owner_id IS NULL"))
            else:
                result = conn.execute(text("UPDATE layout_presets SET is_system = TRUE WHERE owner_id IS NULL"))
            conn.commit()
            print(f"✓ Updated {result.rowcount} existing preset(s) as system presets")

        print("\n=== Migration completed successfully! ===")

except Exception as e:
    print(f"\n✗ Migration failed: {e}")
    import traceback
    traceback.print_exc()

    if "password authentication failed" in str(e):
        print("\nTip: Check your DATABASE_URL in backend/.env")
    elif "could not connect" in str(e).lower():
        print("\nTip: Make sure PostgreSQL is running (sudo systemctl start postgresql)")

    sys.exit(1)
EOF

MIGRATION_EXIT=$?

if [ $MIGRATION_EXIT -eq 0 ]; then
    echo ""
    echo "=== Next Steps ==="

    if [[ "$OS_TYPE" == "Linux" ]]; then
        echo "On Ubuntu/Linux server:"
        echo "1. Restart the backend service:"
        echo "   sudo systemctl restart halext-api.service"
        echo ""
        echo "2. Check the service status:"
        echo "   sudo systemctl status halext-api.service"
        echo ""
        echo "3. View logs if needed:"
        echo "   sudo journalctl -u halext-api.service -n 50 --no-pager"
    else
        echo "On macOS:"
        echo "1. If you're using launchd (see org.halext.api.plist):"
        echo "   launchctl unload ~/Library/LaunchAgents/org.halext.api.plist"
        echo "   launchctl load ~/Library/LaunchAgents/org.halext.api.plist"
        echo ""
        echo "2. Or restart manually:"
        echo "   cd backend && DATABASE_URL=\"sqlite:///halext_dev.db\" ./env/bin/python main.py"
    fi
else
    echo ""
    echo "Migration failed. Please check the error above."
    exit 1
fi
