#!/bin/bash
# Fix backend environment loading issue
# This script addresses the critical database configuration mismatch

set -e

echo "🔧 Halext Backend Environment Fix Script"
echo "=========================================="
echo ""

# Change to backend directory
cd "$(dirname "$0")/../backend"

echo "📍 Current directory: $(pwd)"
echo ""

# Kill duplicate uvicorn process on port 8020 if running
echo "1️⃣  Checking for duplicate backend processes..."
DUPLICATE_PID=$(lsof -ti:8020 2>/dev/null || true)
if [ -n "$DUPLICATE_PID" ]; then
    echo "   Found duplicate process on port 8020 (PID: $DUPLICATE_PID)"
    echo "   Killing process..."
    kill $DUPLICATE_PID
    echo "   ✅ Duplicate process terminated"
else
    echo "   ✅ No duplicate processes found"
fi
echo ""

# Install python-dotenv if not already installed
echo "2️⃣  Installing python-dotenv..."
./env/bin/pip install python-dotenv -q
echo "   ✅ python-dotenv installed"
echo ""

# Verify .env file exists and is readable
echo "3️⃣  Verifying .env file..."
if [ -f ".env" ]; then
    echo "   ✅ .env file exists"
    echo "   DATABASE_URL: $(grep DATABASE_URL .env | cut -d'=' -f1)"
    echo "   ACCESS_CODE: $(grep ACCESS_CODE .env | cut -d'=' -f1)"
else
    echo "   ❌ .env file not found!"
    exit 1
fi
echo ""

# Test environment loading
echo "4️⃣  Testing environment loading..."
DB_URL=$(./env/bin/python3 -c 'from dotenv import load_dotenv; load_dotenv(); import os; print(os.getenv("DATABASE_URL", "NOT SET"))')
if [[ "$DB_URL" == *"postgresql"* ]]; then
    echo "   ✅ PostgreSQL URL loaded correctly"
else
    echo "   ❌ Failed to load PostgreSQL URL: $DB_URL"
    exit 1
fi
echo ""

# Test database connection
echo "5️⃣  Testing database connection..."
./env/bin/python3 -c "
from dotenv import load_dotenv
load_dotenv()
from app.database import engine
print('   Database engine:', engine.url)
if 'postgresql' in str(engine.url):
    print('   ✅ Using PostgreSQL')
else:
    print('   ❌ Still using SQLite!')
    exit(1)
" || exit 1
echo ""

echo "✅ All local checks passed!"
echo ""
echo "📋 Next steps:"
echo "   1. Commit and push the changes (main.py, requirements.txt)"
echo "   2. On the server, run:"
echo "      ssh halext-server"
echo "      cd /srv/halext.org/halext-org"
echo "      git pull"
echo "      cd backend"
echo "      ./env/bin/pip install -r requirements.txt"
echo "      sudo systemctl restart halext-api.service"
echo "      curl -s http://localhost:8000/api/health | grep database"
echo ""
echo "   3. Verify authentication works:"
echo "      curl -X POST 'https://org.halext.org/api/token' \\"
echo "        -H 'Content-Type: application/x-www-form-urlencoded' \\"
echo "        -d 'username=YOUR_USER&password=YOUR_PASS'"
echo ""

