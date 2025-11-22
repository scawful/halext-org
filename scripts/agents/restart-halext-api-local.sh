#!/bin/bash
# Restart the halext-api service locally (run this ON the server)
# For remote restarts from Mac, use restart-halext-api.sh instead

set -e

echo "🔄 Restarting halext-api.service locally..."
echo ""

# Restart the service
sudo systemctl restart halext-api.service

# Wait a moment for it to start
sleep 2

# Show status
echo "📊 Service status:"
systemctl status halext-api.service --no-pager | head -20
echo ""

# Health check
echo "🏥 Health check:"
curl -s http://localhost:8000/api/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8000/api/health
echo ""

# Database check
echo "🗄️  Database verification:"
cd /srv/halext.org/halext-org/backend
./env/bin/python3 -c "from dotenv import load_dotenv; load_dotenv(); from app.database import engine; print('Database URL:', engine.url)"
echo ""

# Process check
echo "🔍 Process check:"
ps aux | grep "[u]vicorn main:app" | grep -v grep
echo ""

echo "✅ Backend service restarted successfully!"
echo ""
echo "🧪 Test authentication with:"
echo "   curl -X POST 'https://org.halext.org/api/token' \\"
echo "     -H 'Content-Type: application/x-www-form-urlencoded' \\"
echo "     -d 'username=YOUR_USER&password=YOUR_PASS'"
echo ""

