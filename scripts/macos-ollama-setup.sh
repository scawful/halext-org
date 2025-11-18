#!/bin/bash
# macOS Ollama Setup Script for Halext Org
# This script configures Ollama to run as a launch agent and connect to the Halext server

set -e

echo "🚀 Halext Org - macOS Ollama Setup"
echo "=================================="
echo ""

# Get user's home directory
USER_HOME="$HOME"
LAUNCH_AGENTS_DIR="$USER_HOME/Library/LaunchAgents"
LOG_DIR="$USER_HOME/Library/Logs/halext"

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama not found. Please install it first:"
    echo "   brew install ollama"
    echo "   or download from https://ollama.ai"
    exit 1
fi

echo "✅ Ollama found at: $(which ollama)"
echo ""

# Create log directory
mkdir -p "$LOG_DIR"
echo "📁 Created log directory: $LOG_DIR"

# Get Mac's local IP for display
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")
echo "🌐 Your Mac's local IP: $LOCAL_IP"
echo ""

# Create the launch agent plist
PLIST_PATH="$LAUNCH_AGENTS_DIR/org.halext.ollama.plist"
mkdir -p "$LAUNCH_AGENTS_DIR"

echo "📝 Creating launch agent configuration..."

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.halext.ollama</string>

    <key>ProgramArguments</key>
    <array>
        <string>$(which ollama)</string>
        <string>serve</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>$LOG_DIR/ollama.log</string>

    <key>StandardErrorPath</key>
    <string>$LOG_DIR/ollama-error.log</string>

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

echo "✅ Launch agent created: $PLIST_PATH"
echo ""

# Unload existing agent if running
if launchctl list | grep -q "org.halext.ollama"; then
    echo "🔄 Stopping existing Ollama service..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# Load the launch agent
echo "🚀 Starting Ollama service..."
launchctl load "$PLIST_PATH"

# Wait a moment for it to start
sleep 3

# Check if it's running
if launchctl list | grep -q "org.halext.ollama"; then
    echo "✅ Ollama service is running!"
else
    echo "⚠️  Ollama service may not have started. Check logs:"
    echo "   tail -f $LOG_DIR/ollama-error.log"
fi

echo ""
echo "📋 Available models:"
ollama list || echo "⚠️  Could not list models. Ollama may still be starting..."

echo ""
echo "🧪 Testing connection..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama API is responding on localhost:11434"
else
    echo "⚠️  Could not connect to Ollama API. It may still be starting up."
    echo "   Wait a minute and test with: curl http://localhost:11434/api/tags"
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Configure your Ubuntu server's .env with:"
echo "   OLLAMA_URL=http://$LOCAL_IP:11434"
echo "   AI_PROVIDER=ollama"
echo ""
echo "2. Test from your server:"
echo "   curl http://$LOCAL_IP:11434/api/tags"
echo ""
echo "3. View logs:"
echo "   tail -f $LOG_DIR/ollama.log"
echo ""
echo "4. Stop service:"
echo "   launchctl unload $PLIST_PATH"
echo ""
echo "5. Start service:"
echo "   launchctl load $PLIST_PATH"
echo ""
echo "📊 Monitor status:"
echo "   launchctl list | grep ollama"
echo ""
