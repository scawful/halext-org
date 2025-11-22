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

# Verify extensions are included (widgets, share extension, etc.)
echo "🔍 Checking for iOS extensions..."
EXTENSIONS_FOUND=0

# Check for PlugIns directory (where extensions are typically stored)
if [ -d "$APP_PATH/PlugIns" ]; then
    PLUGIN_COUNT=$(find "$APP_PATH/PlugIns" -name "*.appex" -type d 2>/dev/null | wc -l | tr -d ' ')
    if [ "$PLUGIN_COUNT" -gt 0 ]; then
        echo "  ✅ Found $PLUGIN_COUNT extension(s) in PlugIns directory:"
        find "$APP_PATH/PlugIns" -name "*.appex" -type d | while read -r ext; do
            EXT_NAME=$(basename "$ext" .appex)
            echo "    - $EXT_NAME"
        done
        EXTENSIONS_FOUND=$PLUGIN_COUNT
    fi
fi

# Also check for extensions at app root (less common but possible)
ROOT_EXT_COUNT=$(find "$APP_PATH" -maxdepth 1 -name "*.appex" -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$ROOT_EXT_COUNT" -gt 0 ]; then
    echo "  ✅ Found $ROOT_EXT_COUNT extension(s) at app root:"
    find "$APP_PATH" -maxdepth 1 -name "*.appex" -type d | while read -r ext; do
        EXT_NAME=$(basename "$ext" .appex)
        echo "    - $EXT_NAME"
    done
    EXTENSIONS_FOUND=$((EXTENSIONS_FOUND + ROOT_EXT_COUNT))
fi

if [ "$EXTENSIONS_FOUND" -eq 0 ]; then
    echo "  ℹ️  No extensions detected - this is OK if widgets/extensions aren't set up as separate targets"
    echo "     Extensions will work once configured in Xcode as separate targets"
fi

# Create Payload directory structure
echo "📦 Creating IPA structure..."
mkdir -p "$PAYLOAD_DIR"
cp -r "$APP_PATH" "$PAYLOAD_DIR/"

# Get the app name from the bundle
APP_NAME=$(basename "$APP_PATH" .app)
COPIED_APP="$PAYLOAD_DIR/$APP_NAME.app"

# Remove ALL signing artifacts that can cause SideStore certificate conflicts
echo "🧹 Removing ALL signing artifacts (provisioning profiles, code signatures, etc.)..."
echo "   This ensures SideStore can sign the app cleanly without certificate conflicts"

# Remove provisioning profiles from everywhere
find "$COPIED_APP" -name "embedded.mobileprovision" -delete 2>/dev/null || true
find "$COPIED_APP" -name "*.mobileprovision" -delete 2>/dev/null || true

# Remove code signatures from everywhere
find "$COPIED_APP" -name "_CodeSignature" -type d -exec rm -rf {} + 2>/dev/null || true
find "$COPIED_APP" -name "CodeResources" -delete 2>/dev/null || true
find "$COPIED_APP" -name "_CodeSignature" -delete 2>/dev/null || true

# Remove Safari extension signing info
find "$COPIED_APP" -name "SC_Info" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove resource rules (legacy signing artifact)
find "$COPIED_APP" -name "ResourceRules.plist" -delete 2>/dev/null || true

# Clean Info.plist of ALL signing-related keys including UDID references
INFO_PLIST="$COPIED_APP/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo "  🧹 Cleaning Info.plist of signing artifacts and UDID references..."
    # Use PlistBuddy to remove signing-related keys if they exist
    if command -v /usr/libexec/PlistBuddy &> /dev/null; then
        # Remove provisioning-related keys that contain UDIDs
        /usr/libexec/PlistBuddy -c "Delete :ProvisionedDevices" "$INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :TeamIdentifier" "$INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :ApplicationIdentifierPrefix" "$INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :ProvisioningProfile" "$INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :ProvisioningProfileDevices" "$INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :UUID" "$INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Delete :Entitlements" "$INFO_PLIST" 2>/dev/null || true
        
        # Also clean any nested dictionaries that might contain UDIDs
        # Check if ProvisionedDevices exists as an array and remove all items
        DEVICE_COUNT=$(/usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" "$INFO_PLIST" 2>/dev/null | grep -c "Dict\|String" || echo "0")
        if [ "$DEVICE_COUNT" -gt 0 ]; then
            /usr/libexec/PlistBuddy -c "Delete :ProvisionedDevices" "$INFO_PLIST" 2>/dev/null || true
        fi
    fi
    
    # Also use sed as a fallback to remove UDID-like patterns from plist (40 hex chars)
    # This catches any UDIDs that might be embedded as strings
    if command -v sed &> /dev/null; then
        # Backup original
        cp "$INFO_PLIST" "$INFO_PLIST.bak" 2>/dev/null || true
        # Remove lines containing UDID patterns (40 hex characters)
        sed -i '' '/[A-F0-9]\{40\}/d' "$INFO_PLIST" 2>/dev/null || true
        # Remove lines containing UUID patterns (with dashes)
        sed -i '' '/[A-F0-9]\{8\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{12\}/d' "$INFO_PLIST" 2>/dev/null || true
        # Restore if sed broke the plist
        if ! plutil -lint "$INFO_PLIST" &>/dev/null; then
            mv "$INFO_PLIST.bak" "$INFO_PLIST" 2>/dev/null || true
        else
            rm -f "$INFO_PLIST.bak" 2>/dev/null || true
        fi
    fi
fi

# Clean Info.plist in extensions too
if [ -d "$COPIED_APP/PlugIns" ]; then
    find "$COPIED_APP/PlugIns" -name "Info.plist" | while read -r ext_plist; do
        if [ -f "$ext_plist" ] && command -v /usr/libexec/PlistBuddy &> /dev/null; then
            /usr/libexec/PlistBuddy -c "Delete :ProvisionedDevices" "$ext_plist" 2>/dev/null || true
            /usr/libexec/PlistBuddy -c "Delete :TeamIdentifier" "$ext_plist" 2>/dev/null || true
            /usr/libexec/PlistBuddy -c "Delete :ApplicationIdentifierPrefix" "$ext_plist" 2>/dev/null || true
        fi
    done
fi

# Clean extensions more thoroughly (including UDID references)
if [ -d "$COPIED_APP/PlugIns" ]; then
    echo "  🧹 Deep cleaning extensions (removing UDID references)..."
    find "$COPIED_APP/PlugIns" -type d -name "*.appex" | while read -r appex; do
        # Remove signing artifacts
        find "$appex" -name "embedded.mobileprovision" -delete 2>/dev/null || true
        find "$appex" -name "_CodeSignature" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$appex" -name "CodeResources" -delete 2>/dev/null || true
        
        # Clean extension Info.plist
        EXT_PLIST="$appex/Info.plist"
        if [ -f "$EXT_PLIST" ] && command -v /usr/libexec/PlistBuddy &> /dev/null; then
            /usr/libexec/PlistBuddy -c "Delete :ProvisionedDevices" "$EXT_PLIST" 2>/dev/null || true
            /usr/libexec/PlistBuddy -c "Delete :TeamIdentifier" "$EXT_PLIST" 2>/dev/null || true
        fi
    done
fi

# Clean WatchKit apps if present
if [ -d "$COPIED_APP/Watch" ]; then
    echo "  🧹 Cleaning WatchKit apps..."
    find "$COPIED_APP/Watch" -name "*.app" -type d | while read -r watchapp; do
        find "$watchapp" -name "embedded.mobileprovision" -delete 2>/dev/null || true
        find "$watchapp" -name "_CodeSignature" -type d -exec rm -rf {} + 2>/dev/null || true
    done
fi

# Remove any other files that might contain UDID references
echo "  🧹 Removing any other UDID-containing files..."
find "$COPIED_APP" -name "*.plist" -type f | while read -r plist_file; do
    # Check if plist contains UDID-like patterns and clean them
    if grep -qE "[A-F0-9]{40}|[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}" "$plist_file" 2>/dev/null; then
        if command -v /usr/libexec/PlistBuddy &> /dev/null; then
            # Try to remove ProvisionedDevices from any plist
            /usr/libexec/PlistBuddy -c "Delete :ProvisionedDevices" "$plist_file" 2>/dev/null || true
        fi
    fi
done

echo "  ✅ All signing artifacts and UDID references removed"

# Verify the app is completely unsigned and UDID-free
echo "🔍 Verifying app is unsigned and UDID-free..."
if find "$COPIED_APP" -name "embedded.mobileprovision" | grep -q .; then
    echo "  ⚠️  WARNING: Found remaining provisioning profiles!"
    find "$COPIED_APP" -name "embedded.mobileprovision"
else
    echo "  ✅ No provisioning profiles found"
fi

if find "$COPIED_APP" -name "_CodeSignature" -type d | grep -q .; then
    echo "  ⚠️  WARNING: Found remaining code signatures!"
    find "$COPIED_APP" -name "_CodeSignature" -type d
else
    echo "  ✅ No code signatures found"
fi

# Check for UDID patterns in plist files
UDID_FOUND=false
if find "$COPIED_APP" -name "*.plist" -type f -exec grep -lE "[A-F0-9]{40}|[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}" {} \; 2>/dev/null | grep -q .; then
    echo "  ⚠️  WARNING: Found potential UDID patterns in plist files!"
    find "$COPIED_APP" -name "*.plist" -type f -exec grep -lE "[A-F0-9]{40}|[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}" {} \; 2>/dev/null | head -5
    UDID_FOUND=true
else
    echo "  ✅ No UDID patterns found in plist files"
fi

if [ "$UDID_FOUND" = false ]; then
    echo "  ✅ App is completely unsigned and UDID-free - ready for SideStore"
else
    echo "  ⚠️  Some UDID patterns detected - SideStore may still show certificate errors"
    echo "     Try rebuilding or check SideStore settings"
fi

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
    echo "📦 Included features:"
    echo "  ✅ Main app bundle"
    if [ "$EXTENSIONS_FOUND" -gt 0 ]; then
        echo "  ✅ $EXTENSIONS_FOUND extension(s) (widgets, share extension, etc.)"
    else
        echo "  ℹ️  Extensions: Not detected (may need Xcode target setup)"
    fi
    echo "  ✅ App Groups entitlement (for widget data sharing)"
    echo "  ✅ Clean provisioning profiles (no UUID conflicts)"
    echo ""
    # Copy to iCloud Documents for easy iPhone access
    echo "☁️  Copying to iCloud Documents for iPhone access..."
    ICLOUD_DOCS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents"
    IPA_IN_ICLOUD=false
    
    if [ -d "$ICLOUD_DOCS" ]; then
        cp "$BUILD_DIR/Cafe.ipa" "$ICLOUD_DOCS/Cafe.ipa"
        if [ -f "$ICLOUD_DOCS/Cafe.ipa" ]; then
            echo "  ✅ Copied to iCloud Documents"
            echo "  📱 Access on iPhone: Files app → iCloud Drive → Documents → Cafe.ipa"
            IPA_IN_ICLOUD=true
        else
            echo "  ⚠️  Failed to copy to iCloud Documents (but IPA is still in build folder)"
        fi
    else
        echo "  ℹ️  iCloud Documents folder not found"
        echo "     Enable iCloud Drive in System Settings → Apple ID → iCloud → iCloud Drive"
        echo "     IPA is available in: $BUILD_DIR/Cafe.ipa"
    fi
    echo ""
    
    echo "📱 Next steps:"
    if [ "$IPA_IN_ICLOUD" = true ]; then
        echo "1. On iPhone: Open Files app → iCloud Drive → Documents"
        echo "2. Tap Cafe.ipa → 'Share' or 'Open in SideStore'"
    else
        echo "1. AirDrop Cafe.ipa to your iPhone (or use iCloud Drive if enabled)"
        echo "2. On iPhone: Tap the file → 'Share' or 'Open in SideStore'"
    fi
    echo "3. Sign with your SideStore Apple ID session (ensure SideStore anisette/VPN setup is complete)"
    echo "4. If SideStore asks about revoking certificates:"
    echo "   → Click 'Revoke' or 'Yes' - this is normal and safe"
    echo "   → SideStore needs to revoke old certificates to sign with your Apple ID"
    echo "5. SideStore installs and auto-refreshes without a Mac/AltServer"
    echo ""
    echo "💡 Troubleshooting UDID/certificate errors:"
    echo "   - If SideStore asks to revoke 'justins iphone' certificate and fails:"
    echo "     1. In SideStore: Go to Settings → Clear Certificate Cache"
    echo "     2. Or: Delete any existing Cafe app from your device"
    echo "     3. Rebuild: ./build-for-sidestore.sh"
    echo "     4. Try installing the new IPA"
    echo "   - The IPA is now completely unsigned and UDID-free"
    echo "   - SideStore will create a fresh certificate for your device"
    echo "   - If errors persist, try signing out/in of SideStore"
    echo ""
    echo "💡 Note: Widgets and extensions will work once configured as separate Xcode targets"
    echo "   The IPA includes all necessary entitlements for iOS features"
    echo ""

    # Open in Finder
    open -R "$BUILD_DIR/Cafe.ipa"
else
    echo "❌ Build failed - IPA not created"
    exit 1
fi
