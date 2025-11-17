#!/bin/bash
set -e

echo "=== Halext Org: Layout Presets Schema Migration ==="
echo ""
echo "This script will add is_system and owner_id columns to layout_presets table."
echo ""

# Source environment variables from .env if it exists
if [ -f "backend/.env" ]; then
    export $(cat backend/.env | grep -v '^#' | xargs)
fi

# Get DATABASE_URL from environment or use default
DATABASE_URL=${DATABASE_URL:-"postgresql://halext_user:password@localhost/halext_org"}

echo "Using DATABASE_URL: ${DATABASE_URL}"
echo ""

# Extract database connection info
DB_USER=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*\/\([^?]*\).*/\1/p')

echo "Database user: $DB_USER"
echo "Database name: $DB_NAME"
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
source env/bin/activate

python3 << 'EOF'
from sqlalchemy import create_engine, text, inspect
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://halext_user:password@localhost/halext_org")
engine = create_engine(DATABASE_URL)

try:
    with engine.connect() as conn:
        # Check if columns already exist
        inspector = inspect(engine)
        columns = [col['name'] for col in inspector.get_columns('layout_presets')]

        if 'is_system' in columns and 'owner_id' in columns:
            print("✓ Columns already exist. No migration needed.")
        else:
            # Add new columns
            if 'is_system' not in columns:
                print("Adding is_system column...")
                conn.execute(text("ALTER TABLE layout_presets ADD COLUMN is_system BOOLEAN DEFAULT FALSE"))
                conn.commit()
                print("✓ Added is_system column")

            if 'owner_id' not in columns:
                print("Adding owner_id column...")
                conn.execute(text("ALTER TABLE layout_presets ADD COLUMN owner_id INTEGER"))
                conn.commit()
                print("✓ Added owner_id column")

            # Add foreign key constraint
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
                if "already exists" in str(e):
                    print("✓ Foreign key constraint already exists")
                else:
                    raise

            # Mark existing presets as system presets
            print("Marking existing presets as system presets...")
            result = conn.execute(text("UPDATE layout_presets SET is_system = TRUE WHERE owner_id IS NULL"))
            conn.commit()
            print(f"✓ Updated {result.rowcount} existing preset(s) as system presets")

        print("\n=== Migration completed successfully! ===")

except Exception as e:
    print(f"\n✗ Migration failed: {e}")
    print("\nIf you see a password authentication error, check your DATABASE_URL in backend/.env")
    exit(1)
EOF

MIGRATION_EXIT=$?

if [ $MIGRATION_EXIT -eq 0 ]; then
    echo ""
    echo "=== Next Steps ==="
    echo "1. Restart the backend service:"
    echo "   sudo systemctl restart halext-api.service"
    echo ""
    echo "2. Check the service status:"
    echo "   sudo systemctl status halext-api.service"
    echo ""
    echo "3. View logs if needed:"
    echo "   sudo journalctl -u halext-api.service -n 50 --no-pager"
else
    echo ""
    echo "Migration failed. Please check the error above."
    exit 1
fi
