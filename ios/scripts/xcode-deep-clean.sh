#!/bin/bash
# Nuclear option: Complete Xcode cleanup

set -e

echo "🧹 Deep cleaning Xcode..."
echo ""

# Check if Xcode is running
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  Xcode is currently running!"
    echo "Please quit Xcode first, then run this script again."
    echo ""
    echo "To quit Xcode:"
    echo "  - Press Cmd+Q in Xcode"
    echo "  - Or run: killall Xcode"
    exit 1
fi

echo "Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/

echo "Cleaning Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/

echo "Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/UserData/ModuleCache/

echo "Cleaning build folder in project..."
rm -rf "$(dirname "$0")/../build/"

echo ""
echo "✅ Deep clean complete!"
echo ""
echo "Next steps:"
echo "  1. Open Xcode: open Cafe.xcodeproj"
echo "  2. Clean build: Shift+Cmd+K"
echo "  3. Build: Cmd+B"
