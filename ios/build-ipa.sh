#!/bin/bash

# Build IPA script for AltStore distribution
# Usage: ./build-ipa.sh

set -e

echo "🏗️  Building Cafe IPA for AltStore..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
xcodebuild clean -scheme Cafe -quiet

# Archive the app
echo "📦 Creating archive..."
xcodebuild archive \
  -scheme Cafe \
  -archivePath ./build/Cafe.xcarchive \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Export IPA
echo "📤 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath ./build/Cafe.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist

# Success!
if [ -f "./build/Cafe.ipa" ]; then
    echo "✅ IPA built successfully!"
    echo "📍 Location: $(pwd)/build/Cafe.ipa"
    echo "📊 Size: $(du -h ./build/Cafe.ipa | cut -f1)"

    # Optional: Open in Finder
    open -R ./build/Cafe.ipa
else
    echo "❌ Build failed - IPA not found"
    exit 1
fi
