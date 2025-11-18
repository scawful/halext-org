#!/bin/bash
# Archive and prepare Cafe for TestFlight

set -e

cd "$(dirname "$0")/.."

PROJECT="Cafe.xcodeproj"
SCHEME="Cafe"
ARCHIVE_PATH="./build/Cafe.xcarchive"

echo "🏗️  Building Cafe for TestFlight..."
echo ""

# Clean build folder
echo "Cleaning build folder..."
rm -rf build/
mkdir -p build/

# Archive
echo "Archiving..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates

echo ""
echo "✅ Archive complete!"
echo "📦 Archive location: $ARCHIVE_PATH"
echo ""
echo "Next steps:"
echo "1. Open Xcode Organizer: xcodebuild -list"
echo "2. Or use upload script: ./scripts/upload-to-testflight.sh"
echo ""
echo "Or manually in Xcode:"
echo "- Window > Organizer"
echo "- Select the archive"
echo "- Click 'Distribute App'"
