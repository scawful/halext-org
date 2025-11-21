#!/bin/bash

# Build IPA for SideStore with FREE Apple ID
# This creates a development-signed IPA that SideStore (or AltStore) will re-sign on-device

set -e

echo "🏗️  Building Cafe IPA for SideStore (Free Apple ID method)..."

# Configuration
SCHEME="Cafe"
BUNDLE_ID="org.halext.Cafe"  # Change this if you modified it
TEAM_ID=""  # Leave empty for automatic

# Clean
echo "🧹 Cleaning..."
rm -rf build/
xcodebuild clean -scheme "$SCHEME" -quiet

# Archive with development signing
echo "📦 Archiving..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -archivePath ./build/Cafe.xcarchive \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates

# Export for development (this works with free Apple ID)
echo "📤 Exporting IPA..."
cat > ./build/ExportOptionsDevelopment.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string></string>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath ./build/Cafe.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ./build/ExportOptionsDevelopment.plist \
  -allowProvisioningUpdates

# Check result
if [ -f "./build/Cafe.ipa" ]; then
    echo "✅ IPA built successfully!"
    echo "📍 Location: $(pwd)/build/Cafe.ipa"
    echo "📊 Size: $(du -h ./build/Cafe.ipa | cut -f1)"
    echo ""
    echo "📱 Next steps:"
    echo "1. AirDrop Cafe.ipa to your iPhone"
    echo "2. Tap the file → Open in SideStore (or share > Copy to SideStore)"
    echo "3. SideStore will install it (enters YOUR Apple ID; no tether once configured)"
    echo ""
    open -R ./build/Cafe.ipa
else
    echo "❌ Build failed - IPA not found"
    echo "💡 Try Option 3 below instead"
    exit 1
fi
