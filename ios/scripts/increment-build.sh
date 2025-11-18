#!/bin/bash
# Increment build number for new TestFlight upload

set -e

cd "$(dirname "$0")/.."

PROJECT="Cafe/Cafe.xcodeproj/project.pbxproj"

# Get current build number
CURRENT_BUILD=$(grep -m 1 "CURRENT_PROJECT_VERSION" "$PROJECT" | sed 's/.*= \(.*\);/\1/' | tr -d ' ')

if [ -z "$CURRENT_BUILD" ]; then
    CURRENT_BUILD=1
fi

NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Current build number: $CURRENT_BUILD"
echo "New build number: $NEW_BUILD"

# Update build number
sed -i '' "s/CURRENT_PROJECT_VERSION = $CURRENT_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PROJECT"

echo "✅ Build number incremented: $CURRENT_BUILD → $NEW_BUILD"
echo ""
echo "Don't forget to commit this change:"
echo "  git add Cafe/Cafe.xcodeproj/project.pbxproj"
echo "  git commit -m 'Bump build number to $NEW_BUILD'"
