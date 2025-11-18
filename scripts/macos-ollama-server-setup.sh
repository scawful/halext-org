#!/bin/bash
# macOS Ollama Network Server Setup for Halext Org
# Configures Ollama to serve models to your Ubuntu org.halext.org server

set -e

echo "🚀 Halext Org - macOS Ollama Network Server Setup"
echo "=================================================="
echo ""
echo "This script configures your Mac to serve Ollama models to"
echo "your Ubuntu server at org.halext.org"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get user's home directory
USER_HOME="$HOME"
LOG_DIR="$USER_HOME/Library/Logs/halext"
LAUNCH_AGENTS_DIR="$USER_HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/org.halext.ollama.plist"

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}❌ Ollama not found.${NC}"
    echo ""
    echo "Please install Ollama first:"
    echo "  Option 1: Download from https://ollama.ai"
    echo "  Option 2: brew install ollama"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Ollama found at: $(which ollama)${NC}"
echo ""

# Get Mac's network information
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")
echo -e "${BLUE}🌐 Your Mac's local IP: $LOCAL_IP${NC}"
echo -e "${BLUE}📡 Ubuntu server will connect to: http://$LOCAL_IP:11434${NC}"
echo ""

# Check for existing Ollama processes
echo "🔍 Checking for existing Ollama processes..."
OLLAMA_APP_PID=$(ps aux | grep -i "Ollama.app" | grep -v grep | awk 'NR==1{print $2}')
OLLAMA_SERVE_PIDS=$(pgrep -f "ollama serve" || echo "")

if [ ! -z "$OLLAMA_APP_PID" ]; then
    echo -e "${YELLOW}⚠️  Ollama.app is running (PID: $OLLAMA_APP_PID)${NC}"
    OLLAMA_APP_RUNNING=true
else
    OLLAMA_APP_RUNNING=false
fi

if [ ! -z "$OLLAMA_SERVE_PIDS" ]; then
    echo -e "${YELLOW}⚠️  Ollama serve processes found: $OLLAMA_SERVE_PIDS${NC}"
fi

# Check current network binding
echo ""
echo "🔍 Checking current network binding..."
CURRENT_BINDING=$(lsof -i :11434 -P -n 2>/dev/null | grep LISTEN || echo "")

if echo "$CURRENT_BINDING" | grep -q "\*:11434"; then
    echo -e "${GREEN}✅ Ollama is already listening on all network interfaces (*:11434)${NC}"
    ALREADY_CONFIGURED=true
elif echo "$CURRENT_BINDING" | grep -q "127.0.0.1:11434"; then
    echo -e "${YELLOW}⚠️  Ollama is only listening on localhost (127.0.0.1:11434)${NC}"
    echo "    It needs to be configured for network access."
    ALREADY_CONFIGURED=false
else
    echo -e "${YELLOW}⚠️  No Ollama service detected on port 11434${NC}"
    ALREADY_CONFIGURED=false
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Setup Options:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Use Ollama.app with network access (RECOMMENDED)"
echo "   - Keeps your existing Ollama.app workflow"
echo "   - Configures it to listen on network"
echo "   - System tray icon still works"
echo ""
echo "2. Use Launch Agent (background service)"
echo "   - Stops Ollama.app"
echo "   - Runs Ollama as a background service"
echo "   - Auto-starts on login"
echo ""
echo "3. Check status only (don't change anything)"
echo ""

if [ "$ALREADY_CONFIGURED" = true ]; then
    echo -e "${GREEN}Note: Your Ollama is already configured for network access!${NC}"
    echo "You can choose option 3 to just verify the setup."
    echo ""
fi

read -p "Enter your choice (1-3): " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Option 1: Configuring Ollama.app for Network Access"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Stop any launch agent version
        if launchctl list | grep -q "org.halext.ollama"; then
            echo "🔄 Stopping launch agent version..."
            launchctl unload "$PLIST_PATH" 2>/dev/null || true
        fi

        # Set environment variable for Ollama.app
        echo "📝 Setting up environment for Ollama.app..."

        # Create or update launchd.conf equivalent using launchctl
        launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
        launchctl setenv OLLAMA_ORIGINS "*"
        launchctl setenv OLLAMA_KEEP_ALIVE "24h"

        # Also set in shell profiles for when running from terminal
        for profile in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
            if [ -f "$profile" ]; then
                if ! grep -q "OLLAMA_HOST" "$profile"; then
                    echo "" >> "$profile"
                    echo "# Ollama network configuration for Halext Org" >> "$profile"
                    echo "export OLLAMA_HOST=0.0.0.0:11434" >> "$profile"
                    echo "export OLLAMA_ORIGINS=*" >> "$profile"
                fi
            fi
        done

        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT: You need to restart Ollama.app for changes to take effect${NC}"
        echo ""
        echo "Steps:"
        echo "1. Quit Ollama.app (click menu bar icon → Quit)"
        echo "2. Restart Ollama.app from Applications"
        echo "3. Run this script again to verify"
        echo ""
        read -p "Press Enter when you've restarted Ollama.app..."
        ;;

    2)
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Option 2: Setting up Launch Agent"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # Stop Ollama.app if running
        if [ "$OLLAMA_APP_RUNNING" = true ]; then
            echo "🛑 Stopping Ollama.app..."
            pkill -f "Ollama.app" || true
            sleep 2
        fi

        # Create log directory
        mkdir -p "$LOG_DIR"
        echo "📁 Created log directory: $LOG_DIR"

        # Create the launch agent plist
        mkdir -p "$LAUNCH_AGENTS_DIR"
        echo "📝 Creating launch agent configuration..."

        cat > "$PLIST_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.halext.ollama</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>LOG_DIR_PLACEHOLDER/ollama.log</string>

    <key>StandardErrorPath</key>
    <string>LOG_DIR_PLACEHOLDER/ollama-error.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>0.0.0.0:11434</string>
        <key>OLLAMA_ORIGINS</key>
        <string>*</string>
        <key>OLLAMA_KEEP_ALIVE</key>
        <string>24h</string>
    </dict>

    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

        # Replace placeholders
        OLLAMA_PATH=$(which ollama)
        sed -i '' "s|/usr/local/bin/ollama|$OLLAMA_PATH|g" "$PLIST_PATH"
        sed -i '' "s|LOG_DIR_PLACEHOLDER|$LOG_DIR|g" "$PLIST_PATH"

        echo -e "${GREEN}✅ Launch agent created: $PLIST_PATH${NC}"

        # Unload if already loaded
        if launchctl list | grep -q "org.halext.ollama"; then
            echo "🔄 Reloading service..."
            launchctl unload "$PLIST_PATH" 2>/dev/null || true
        fi

        # Load the launch agent
        echo "🚀 Starting Ollama service..."
        launchctl load "$PLIST_PATH"

        sleep 3
        ;;

    3)
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Status Check Only"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        ;;

    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Verify configuration
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if service is running
if launchctl list | grep -q "org.halext.ollama"; then
    echo -e "${GREEN}✅ Launch agent is loaded${NC}"
fi

# Check network binding
sleep 2
FINAL_BINDING=$(lsof -i :11434 -P -n 2>/dev/null | grep LISTEN || echo "")

echo "🔍 Current network binding:"
if echo "$FINAL_BINDING" | grep -q "\*:11434"; then
    echo -e "${GREEN}✅ Listening on all interfaces (*:11434) - Network accessible${NC}"
    NETWORK_OK=true
elif echo "$FINAL_BINDING" | grep -q "127.0.0.1:11434"; then
    echo -e "${RED}❌ Only listening on localhost (127.0.0.1:11434) - Not network accessible${NC}"
    echo "   Configuration not yet applied. Try restarting Ollama."
    NETWORK_OK=false
else
    echo -e "${RED}❌ Not listening on port 11434${NC}"
    NETWORK_OK=false
fi

# Test local API
echo ""
echo "🧪 Testing local API..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Local API responding${NC}"

    # List models
    echo ""
    echo "📋 Available models:"
    ollama list 2>/dev/null || curl -s http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "  (Unable to list models)"
else
    echo -e "${RED}❌ Local API not responding${NC}"
fi

# Firewall check
echo ""
echo "🔥 Checking macOS Firewall..."
FIREWALL_STATUS=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "unknown")

if [ "$FIREWALL_STATUS" = "0" ]; then
    echo -e "${GREEN}✅ Firewall is disabled (no blocking)${NC}"
elif [ "$FIREWALL_STATUS" = "1" ]; then
    echo -e "${YELLOW}⚠️  Firewall is enabled (may need configuration)${NC}"
    echo "   You may need to allow incoming connections to Ollama"
    echo "   Go to: System Settings → Network → Firewall"
elif [ "$FIREWALL_STATUS" = "2" ]; then
    echo -e "${YELLOW}⚠️  Firewall is enabled with specific services${NC}"
    echo "   You may need to allow Ollama in firewall settings"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$NETWORK_OK" = true ]; then
    echo -e "${GREEN}✅ Your Mac is ready to serve Ollama to your Ubuntu server!${NC}"
    echo ""
    echo "1. From your Ubuntu server, test connectivity:"
    echo "   ${BLUE}curl http://$LOCAL_IP:11434/api/tags${NC}"
    echo ""
    echo "2. If the test works, add your Mac as a client:"
    echo "   - Go to https://org.halext.org admin panel"
    echo "   - Click 'Add Client'"
    echo "   - Name: Mac Studio (or your choice)"
    echo "   - Type: ollama"
    echo "   - Hostname: $LOCAL_IP"
    echo "   - Port: 11434"
    echo ""
    echo "3. Optional: Make this client available to all users:"
    echo "   - Check 'Make public' when adding the client"
    echo ""
else
    echo -e "${YELLOW}⚠️  Network access not yet configured${NC}"
    echo ""
    echo "If you chose Option 1 (Ollama.app):"
    echo "  - Make sure you've quit and restarted Ollama.app"
    echo "  - Run this script again to verify"
    echo ""
    echo "If you chose Option 2 (Launch Agent):"
    echo "  - Check logs: tail -f $LOG_DIR/ollama-error.log"
    echo "  - Try reloading: launchctl unload '$PLIST_PATH' && launchctl load '$PLIST_PATH'"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Useful Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Check what's listening on port 11434:"
echo "  ${BLUE}lsof -i :11434 -P -n${NC}"
echo ""
echo "View Ollama processes:"
echo "  ${BLUE}ps aux | grep ollama${NC}"
echo ""
echo "Test from Ubuntu server:"
echo "  ${BLUE}curl http://$LOCAL_IP:11434/api/tags${NC}"
echo ""
echo "View launch agent logs (if using Option 2):"
echo "  ${BLUE}tail -f $LOG_DIR/ollama.log${NC}"
echo "  ${BLUE}tail -f $LOG_DIR/ollama-error.log${NC}"
echo ""
echo "Restart launch agent (if using Option 2):"
echo "  ${BLUE}launchctl unload '$PLIST_PATH' && launchctl load '$PLIST_PATH'${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
