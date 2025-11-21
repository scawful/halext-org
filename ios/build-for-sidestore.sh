#!/bin/bash

# Build UNSIGNED IPA for SideStore (tetherless sideload)
# SideStore will sign it on-device with your Apple ID; no AltServer/USB once SideStore is configured

set -euo pipefail

echo "🏗️  Building unsigned IPA for SideStore..."
echo "📝 SideStore will sign this on-device using your Apple ID (no AltServer/tether required once set up)"
echo ""

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"
PAYLOAD_DIR="$BUILD_DIR/Payload"
LOG_FILE="$BUILD_DIR/sidestore-build.log"
SCHEME="Cafe"

run_build() {
  local attempt_label="$1"
  echo "📦 Building app bundle (${attempt_label})..."

  # Capture full logs for debugging (including .pcm/module cache hiccups)
  set +e
  xcodebuild build \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -sdk iphoneos \
    -derivedDataPath "$DERIVED_DATA" \
    SUPPORTED_PLATFORMS=iphoneos \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    AD_HOC_CODE_SIGNING_ALLOWED=NO \
    | tee "$LOG_FILE"
  local status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

ensure_clean_build_dir() {
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"
}

detect_module_cache_failure() {
  [[ -f "$LOG_FILE" ]] && grep -E "ModuleCache\\.noindex|\\.pcm|Cafe-dependencies" "$LOG_FILE" >/dev/null
}

echo "🧹 Cleaning previous builds..."
ensure_clean_build_dir
xcodebuild clean -scheme "$SCHEME" -quiet -derivedDataPath "$DERIVED_DATA" 2>/dev/null || true

build_status=0
run_build "attempt 1" || build_status=$?

# Auto-retry once after nuking DerivedData if we see .pcm/module cache flakiness
if [[ $build_status -ne 0 ]] && detect_module_cache_failure; then
  echo "♻️  Detected module cache/pcm errors. Cleaning DerivedData and retrying..."
  rm -rf "$DERIVED_DATA"
  run_build "retry after cache clean" || build_status=$?
fi

if [[ $build_status -ne 0 ]]; then
  if [[ -f "$LOG_FILE" ]] && grep -q "No available simulator runtimes for platform" "$LOG_FILE"; then
    echo "ℹ️  Xcode can't see any simulator runtimes. Install one via Xcode Settings → Platforms or run 'xcodebuild -downloadAllSimulatorRuntimes' if needed."
  fi
  echo "❌ Build failed. Full log: $LOG_FILE"
  exit "$build_status"
fi

echo "✅ Build succeeded. Log: $LOG_FILE"

# Find the built app
APP_PATH=$(find "$DERIVED_DATA" -name "*.app" -path "*/Build/Products/*" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find built .app bundle"
    exit 1
fi

echo "✅ Built app at: $APP_PATH"

# Create Payload directory structure
echo "📦 Creating IPA structure..."
mkdir -p "$PAYLOAD_DIR"
cp -r "$APP_PATH" "$PAYLOAD_DIR/"

# Copy entitlements file for SideStore to use during signing
echo "📋 Including entitlements for SideStore..."
cp "$PROJECT_DIR/Cafe/Cafe.entitlements" "$BUILD_DIR/" || echo "⚠️  Warning: Could not find entitlements file"

# Create IPA (it's just a zip file)
echo "🗜️  Creating IPA file..."
cd "$BUILD_DIR"
zip -qr "Cafe.ipa" Payload
# Add entitlements to the IPA root (for SideStore/AltStore)
if [ -f "Cafe.entitlements" ]; then
    zip -q "Cafe.ipa" Cafe.entitlements
fi

# Cleanup
rm -rf Payload DerivedData

# Success!
if [ -f "$BUILD_DIR/Cafe.ipa" ]; then
    IPA_SIZE=$(du -h "$BUILD_DIR/Cafe.ipa" | cut -f1)
    echo ""
    echo "✅ SUCCESS! Unsigned IPA created for SideStore"
    echo "📍 Location: $BUILD_DIR/Cafe.ipa"
    echo "📊 Size: $IPA_SIZE"
    echo ""
    echo "📱 Next steps:"
    echo "1. AirDrop Cafe.ipa to your iPhone"
    echo "2. On iPhone: Tap the file → 'Share' or 'Open in SideStore'"
    echo "3. Sign with your SideStore Apple ID session (ensure SideStore anisette/VPN setup is complete)"
    echo "4. SideStore installs and auto-refreshes without a Mac/AltServer"
    echo ""

    # Open in Finder
    open -R "$BUILD_DIR/Cafe.ipa"
else
    echo "❌ Build failed - IPA not created"
    exit 1
fi
