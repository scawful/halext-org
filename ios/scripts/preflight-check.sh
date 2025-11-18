#!/bin/bash
# Pre-flight checklist before archiving for TestFlight

set -e

cd "$(dirname "$0")/.."

echo "🔍 Running pre-flight checks for TestFlight..."
echo ""

ERRORS=0
WARNINGS=0

# Check 1: Xcode project exists
echo "✓ Checking Xcode project..."
if [ ! -d "Cafe.xcodeproj" ]; then
    echo "  ❌ Cafe.xcodeproj not found"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✅ Project found"
fi

# Check 2: Swift files exist
echo ""
echo "✓ Checking Swift files..."
SWIFT_COUNT=$(find Cafe -name "*.swift" -type f | wc -l | tr -d ' ')
echo "  ✅ Found $SWIFT_COUNT Swift files"

REQUIRED_FILES=(
    "Cafe/CafeApp.swift"
    "Cafe/App/AppState.swift"
    "Cafe/App/RootView.swift"
    "Cafe/Core/API/APIClient.swift"
    "Cafe/Core/Auth/KeychainManager.swift"
    "Cafe/Core/Models/Models.swift"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ⚠️  Missing: $file"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# Check 3: Bundle identifier
echo ""
echo "✓ Checking bundle identifier..."
BUNDLE_ID=$(grep -m 1 "PRODUCT_BUNDLE_IDENTIFIER" Cafe.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
echo "  Bundle ID: $BUNDLE_ID"
if [ "$BUNDLE_ID" = "org.halext.Cafe" ]; then
    echo "  ✅ Bundle ID is set"
else
    echo "  ⚠️  Unexpected bundle ID: $BUNDLE_ID"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 4: Version and build number
echo ""
echo "✓ Checking version info..."
VERSION=$(grep -m 1 "MARKETING_VERSION" Cafe.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
BUILD=$(grep -m 1 "CURRENT_PROJECT_VERSION" Cafe.xcodeproj/project.pbxproj | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
echo "  Version: $VERSION"
echo "  Build: $BUILD"

# Check 5: Backend URL configuration
echo ""
echo "✓ Checking API configuration..."
if grep -q "org.halext.org/api" Cafe/Core/API/APIClient.swift; then
    echo "  ✅ Production URL configured"
else
    echo "  ⚠️  Production URL may not be set in APIClient.swift"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 6: Signing capability
echo ""
echo "✓ Checking code signing..."
if grep -q "CODE_SIGN_STYLE = Automatic" Cafe.xcodeproj/project.pbxproj; then
    echo "  ✅ Automatic signing enabled"
else
    echo "  ⚠️  Automatic signing may not be configured"
    WARNINGS=$((WARNINGS + 1))
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary:"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo "❌ Pre-flight check FAILED"
    echo "   Fix errors before archiving"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo "⚠️  Pre-flight check passed with warnings"
    echo "   Review warnings before archiving"
    echo ""
    echo "Proceed? (y/n)"
    read -r response
    if [ "$response" != "y" ]; then
        echo "Aborted"
        exit 0
    fi
else
    echo "✅ Pre-flight check PASSED"
    echo "   Ready to archive!"
fi

echo ""
echo "Next steps:"
echo "  1. Open Xcode and build (Cmd+B) to verify compilation"
echo "  2. Run: ./scripts/archive-for-testflight.sh"
echo "  3. Or use Xcode: Product > Archive"
