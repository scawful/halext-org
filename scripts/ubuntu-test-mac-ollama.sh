#!/bin/bash
# Ubuntu Server Script - Test Connectivity to macOS Ollama Server
# Run this from your Ubuntu org.halext.org server

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🧪 Halext Org - Test macOS Ollama Connectivity"
echo "=============================================="
echo ""

# Check if MAC_IP is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <mac-ip-address>${NC}"
    echo ""
    echo "Example:"
    echo "  $0 192.168.1.204"
    echo ""
    exit 1
fi

MAC_IP="$1"
OLLAMA_URL="http://$MAC_IP:11434"

echo -e "${BLUE}Testing connection to: $OLLAMA_URL${NC}"
echo ""

# Test 1: Basic connectivity
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Network Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ping -c 3 "$MAC_IP" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Can ping Mac at $MAC_IP${NC}"
else
    echo -e "${RED}❌ Cannot ping Mac at $MAC_IP${NC}"
    echo "   Check if Mac is on the same network"
    echo "   Check firewall settings"
    exit 1
fi

# Test 2: Port accessibility
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Port 11434 Accessibility"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if nc -zv "$MAC_IP" 11434 2>&1 | grep -q "succeeded\|open"; then
    echo -e "${GREEN}✅ Port 11434 is accessible${NC}"
else
    echo -e "${RED}❌ Port 11434 is not accessible${NC}"
    echo "   Make sure Ollama is configured to listen on 0.0.0.0:11434"
    echo "   Run the macOS setup script on your Mac"
    exit 1
fi

# Test 3: API endpoint
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Ollama API Response"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" "$OLLAMA_URL/api/tags" 2>&1)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Ollama API is responding (HTTP $HTTP_CODE)${NC}"
    echo ""

    # Parse and display models
    echo "📋 Available models on Mac:"
    echo "$BODY" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = data.get('models', [])
    if models:
        for model in models:
            name = model.get('name', 'unknown')
            size_bytes = model.get('size', 0)
            size_gb = size_bytes / (1024**3)
            print(f'  • {name} ({size_gb:.2f} GB)')
    else:
        print('  (No models found)')
except:
    print('  (Unable to parse models)')
" 2>/dev/null || echo "  (Unable to list models - install python3 for better output)"

    echo ""
    MODEL_COUNT=$(echo "$BODY" | grep -o '"name"' | wc -l | tr -d ' ')
    echo -e "${GREEN}Found $MODEL_COUNT model(s)${NC}"

else
    echo -e "${RED}❌ Ollama API not responding properly (HTTP $HTTP_CODE)${NC}"
    echo ""
    echo "Response:"
    echo "$BODY"
    exit 1
fi

# Test 4: Generate test
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Model Generation Test (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get first model name
FIRST_MODEL=$(echo "$BODY" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = data.get('models', [])
    if models:
        print(models[0].get('name', ''))
except:
    pass
" 2>/dev/null)

if [ ! -z "$FIRST_MODEL" ]; then
    read -p "Test generation with model '$FIRST_MODEL'? (y/N): " TEST_GEN

    if [[ "$TEST_GEN" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Sending test prompt to $FIRST_MODEL..."
        echo "(This may take a few seconds)"
        echo ""

        GEN_RESPONSE=$(curl -s "$OLLAMA_URL/api/generate" \
            -H "Content-Type: application/json" \
            -d "{\"model\": \"$FIRST_MODEL\", \"prompt\": \"Hello! Respond with just 'Hi from Ollama'\", \"stream\": false}" 2>&1)

        if echo "$GEN_RESPONSE" | grep -q "response"; then
            GENERATED_TEXT=$(echo "$GEN_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('response', ''))
except:
    print('(parsing error)')
" 2>/dev/null)

            echo -e "${GREEN}✅ Model generated response:${NC}"
            echo "  $GENERATED_TEXT"
        else
            echo -e "${YELLOW}⚠️  Generation test failed or timed out${NC}"
            echo "  This is OK - API is working, model may be loading"
        fi
    fi
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary & Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✅ Your Mac Ollama server is accessible from Ubuntu!${NC}"
echo ""
echo "Connection Details:"
echo "  Mac IP: $MAC_IP"
echo "  Ollama URL: $OLLAMA_URL"
echo "  Models: $MODEL_COUNT available"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Add Mac to org.halext.org Admin Panel"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Method 1: Using the Web Admin UI"
echo "  1. Go to https://org.halext.org"
echo "  2. Login and click the Admin Panel icon"
echo "  3. Click 'Add Client'"
echo "  4. Fill in:"
echo "     - Name: Mac Studio (or your choice)"
echo "     - Type: ollama"
echo "     - Hostname: $MAC_IP"
echo "     - Port: 11434"
echo "     - Public: ✓ (if you want all users to access it)"
echo ""
echo "Method 2: Using curl (from this Ubuntu server)"
echo ""
echo "First, get your auth token by logging in, then:"
echo ""
echo -e "${BLUE}curl -X POST https://org.halext.org/admin/ai-clients \\
  -H \"Authorization: Bearer \$YOUR_TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '{
    \"name\": \"Mac Studio\",
    \"node_type\": \"ollama\",
    \"hostname\": \"$MAC_IP\",
    \"port\": 11434,
    \"is_public\": true
  }'${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
