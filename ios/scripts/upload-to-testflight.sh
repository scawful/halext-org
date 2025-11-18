#!/bin/bash
# Upload archived Cafe app to TestFlight

set -e

cd "$(dirname "$0")/.."

ARCHIVE_PATH="./build/Cafe.xcarchive"
EXPORT_PATH="./build/export"

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found at $ARCHIVE_PATH"
    echo "Run ./scripts/archive-for-testflight.sh first"
    exit 1
fi

echo "📤 Uploading Cafe to TestFlight..."
echo ""

# Create export options
cat > ./build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

# Export archive
echo "Exporting archive..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist ./build/ExportOptions.plist \
    -allowProvisioningUpdates

echo ""
echo "✅ Export complete!"
echo ""
echo "To upload manually:"
echo "  xcrun altool --upload-app -f '$EXPORT_PATH/Cafe.ipa' -t ios -u YOUR_APPLE_ID"
echo ""
echo "Or use Xcode:"
echo "  1. Window > Organizer"
echo "  2. Select archive and click 'Distribute App'"
echo "  3. Choose 'TestFlight & App Store'"
echo "  4. Click 'Upload'"
