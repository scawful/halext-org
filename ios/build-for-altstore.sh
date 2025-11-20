#!/bin/bash

# Build UNSIGNED IPA for AltStore
# AltStore will sign it with your free Apple ID when installing

set -e

echo "🏗️  Building unsigned IPA for AltStore..."
echo "📝 AltStore will sign this with your Apple ID when you install it"
echo ""

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="Cafe"

# Clean
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
xcodebuild clean -scheme "$SCHEME" -quiet -derivedDataPath "$BUILD_DIR/DerivedData" 2>/dev/null || true

# Build for device (unsigned)
echo "📦 Building app bundle..."
xcodebuild build \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  AD_HOC_CODE_SIGNING_ALLOWED=NO

# Find the built app
APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "*.app" -path "*/Build/Products/*" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built .app bundle"
    exit 1
fi

echo "✅ Built app at: $APP_PATH"

# Create Payload directory structure
echo "📦 Creating IPA structure..."
PAYLOAD_DIR="$BUILD_DIR/Payload"
mkdir -p "$PAYLOAD_DIR"
cp -r "$APP_PATH" "$PAYLOAD_DIR/"

# Copy entitlements file for AltStore to use during signing
echo "📋 Including entitlements for AltStore..."
cp "$PROJECT_DIR/Cafe/Cafe.entitlements" "$BUILD_DIR/" || echo "⚠️  Warning: Could not find entitlements file"

# Create IPA (it's just a zip file)
echo "🗜️  Creating IPA file..."
cd "$BUILD_DIR"
zip -qr "Cafe.ipa" Payload
# Add entitlements to the IPA root (for AltStore)
if [ -f "Cafe.entitlements" ]; then
    zip -q "Cafe.ipa" Cafe.entitlements
fi

# Cleanup
rm -rf Payload DerivedData

# Success!
if [ -f "$BUILD_DIR/Cafe.ipa" ]; then
    IPA_SIZE=$(du -h "$BUILD_DIR/Cafe.ipa" | cut -f1)
    echo ""
    echo "✅ SUCCESS! Unsigned IPA created for AltStore"
    echo "📍 Location: $BUILD_DIR/Cafe.ipa"
    echo "📊 Size: $IPA_SIZE"
    echo ""
    echo "📱 Next steps:"
    echo "1. AirDrop Cafe.ipa to your iPhone"
    echo "2. On iPhone: Tap the file → 'Open in AltStore'"
    echo "3. AltStore will ask for your Apple ID"
    echo "4. AltStore signs and installs it automatically"
    echo "5. App refreshes automatically every 7 days!"
    echo ""

    # Open in Finder
    open -R "$BUILD_DIR/Cafe.ipa"
else
    echo "❌ Build failed - IPA not created"
    exit 1
fi
