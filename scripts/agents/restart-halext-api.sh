#!/bin/bash
# Restart the halext-api service on the server
# This is a helper script for agents to restart the backend service

echo "🔄 Restarting halext-api.service..."
ssh halext-server "sudo systemctl restart halext-api.service && sleep 2 && systemctl status halext-api.service --no-pager | head -20"
echo ""
echo "✅ Service restarted"
echo ""
echo "📊 Health check:"
ssh halext-server "curl -s http://localhost:8000/api/health"
echo ""

