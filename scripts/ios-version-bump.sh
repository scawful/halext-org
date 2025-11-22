#!/bin/bash
# ==============================================================================
# iOS Version Bump Utility
# ==============================================================================
# Manages semantic versioning and build numbers for the Cafe iOS app.
#
# Usage:
#   ./scripts/ios-version-bump.sh [command] [options]
#
# Commands:
#   patch        Bump patch version (1.0.0 -> 1.0.1)
#   minor        Bump minor version (1.0.0 -> 1.1.0)
#   major        Bump major version (1.0.0 -> 2.0.0)
#   build        Increment build number only
#   set VERSION  Set specific version (e.g., set 2.0.0)
#   show         Display current version info
#
# Options:
#   --no-commit  Skip git commit
#   --dry-run    Show what would change without making changes
#
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$PROJECT_ROOT/ios"
PBXPROJ="$IOS_DIR/Cafe.xcodeproj/project.pbxproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
NO_COMMIT=false
DRY_RUN=false
COMMAND=""
SET_VERSION=""

# ==============================================================================
# Helper Functions
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "iOS Version Bump Utility"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  patch        Bump patch version (1.0.0 -> 1.0.1)"
    echo "  minor        Bump minor version (1.0.0 -> 1.1.0)"
    echo "  major        Bump major version (1.0.0 -> 2.0.0)"
    echo "  build        Increment build number only"
    echo "  set VERSION  Set specific version (e.g., set 2.0.0)"
    echo "  show         Display current version info"
    echo ""
    echo "Options:"
    echo "  --no-commit  Skip git commit"
    echo "  --dry-run    Show what would change without making changes"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 show                 # Show current version"
    echo "  $0 build                # Increment build (1.0.0 (5) -> 1.0.0 (6))"
    echo "  $0 patch                # Bump patch (1.0.0 -> 1.0.1)"
    echo "  $0 minor --no-commit    # Bump minor, skip git commit"
    echo "  $0 set 2.0.0            # Set version to 2.0.0"
    echo ""
}

get_current_version() {
    grep -m 1 "MARKETING_VERSION" "$PBXPROJ" | sed 's/.*= \(.*\);/\1/' | tr -d ' '
}

get_current_build() {
    grep -m 1 "CURRENT_PROJECT_VERSION" "$PBXPROJ" | sed 's/.*= \(.*\);/\1/' | tr -d ' '
}

set_version() {
    local new_version="$1"
    local current_version
    current_version=$(get_current_version)

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would change MARKETING_VERSION: $current_version -> $new_version"
        return
    fi

    # Update all occurrences of MARKETING_VERSION
    sed -i '' "s/MARKETING_VERSION = $current_version;/MARKETING_VERSION = $new_version;/g" "$PBXPROJ"
}

set_build_number() {
    local new_build="$1"
    local current_build
    current_build=$(get_current_build)

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would change CURRENT_PROJECT_VERSION: $current_build -> $new_build"
        return
    fi

    # Update all occurrences of CURRENT_PROJECT_VERSION
    sed -i '' "s/CURRENT_PROJECT_VERSION = $current_build;/CURRENT_PROJECT_VERSION = $new_build;/g" "$PBXPROJ"
}

bump_version() {
    local bump_type="$1"
    local current_version
    current_version=$(get_current_version)

    # Parse semantic version
    local major minor patch
    IFS='.' read -r major minor patch <<< "$current_version"

    # Handle missing components
    major=${major:-0}
    minor=${minor:-0}
    patch=${patch:-0}

    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac

    echo "$major.$minor.$patch"
}

commit_changes() {
    local version="$1"
    local build="$2"

    if [ "$NO_COMMIT" = true ]; then
        log_info "Skipping git commit (--no-commit flag)"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would commit: 'chore(ios): bump version to $version ($build)'"
        return
    fi

    cd "$PROJECT_ROOT"

    if git diff --quiet "$PBXPROJ"; then
        log_warning "No changes to commit"
        return
    fi

    git add "$PBXPROJ"
    git commit -m "chore(ios): bump version to $version ($build)"
    log_success "Committed version bump"
}

show_version_info() {
    local version build
    version=$(get_current_version)
    build=$(get_current_build)

    echo ""
    echo "============================================"
    echo "  Cafe iOS App Version Info"
    echo "============================================"
    echo ""
    echo "  Marketing Version: $version"
    echo "  Build Number:      $build"
    echo "  Full Version:      $version ($build)"
    echo ""
    echo "  Project File:      $PBXPROJ"
    echo ""

    # Show git info if available
    if git -C "$PROJECT_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
        local branch commit_count last_tag
        branch=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD)
        commit_count=$(git -C "$PROJECT_ROOT" rev-list --count HEAD)
        last_tag=$(git -C "$PROJECT_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "none")

        echo "  Git Branch:        $branch"
        echo "  Total Commits:     $commit_count"
        echo "  Last Tag:          $last_tag"
        echo ""
    fi
}

# ==============================================================================
# Parse Arguments
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        patch|minor|major|build|show)
            COMMAND="$1"
            shift
            ;;
        set)
            COMMAND="set"
            shift
            SET_VERSION="$1"
            shift
            ;;
        --no-commit)
            NO_COMMIT=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# ==============================================================================
# Main Execution
# ==============================================================================

# Verify project exists
if [ ! -f "$PBXPROJ" ]; then
    log_error "Xcode project not found at $PBXPROJ"
    exit 1
fi

# Execute command
case "$COMMAND" in
    show)
        show_version_info
        ;;
    build)
        current_version=$(get_current_version)
        current_build=$(get_current_build)
        new_build=$((current_build + 1))

        log_info "Incrementing build number..."
        log_info "  Version:    $current_version"
        log_info "  Build:      $current_build -> $new_build"

        set_build_number "$new_build"

        if [ "$DRY_RUN" != true ]; then
            commit_changes "$current_version" "$new_build"
            log_success "Build number incremented: $current_version ($new_build)"
        fi
        ;;
    patch|minor|major)
        current_version=$(get_current_version)
        current_build=$(get_current_build)
        new_version=$(bump_version "$COMMAND")
        new_build=$((current_build + 1))

        log_info "Bumping $COMMAND version..."
        log_info "  Version:    $current_version -> $new_version"
        log_info "  Build:      $current_build -> $new_build"

        set_version "$new_version"
        set_build_number "$new_build"

        if [ "$DRY_RUN" != true ]; then
            commit_changes "$new_version" "$new_build"
            log_success "Version bumped: $new_version ($new_build)"
        fi
        ;;
    set)
        if [ -z "$SET_VERSION" ]; then
            log_error "No version specified"
            echo "Usage: $0 set VERSION (e.g., set 2.0.0)"
            exit 1
        fi

        # Validate version format
        if ! [[ "$SET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            log_error "Invalid version format: $SET_VERSION"
            echo "Version must be in format: X.Y.Z (e.g., 2.0.0)"
            exit 1
        fi

        current_version=$(get_current_version)
        current_build=$(get_current_build)
        new_build=$((current_build + 1))

        log_info "Setting version..."
        log_info "  Version:    $current_version -> $SET_VERSION"
        log_info "  Build:      $current_build -> $new_build"

        set_version "$SET_VERSION"
        set_build_number "$new_build"

        if [ "$DRY_RUN" != true ]; then
            commit_changes "$SET_VERSION" "$new_build"
            log_success "Version set: $SET_VERSION ($new_build)"
        fi
        ;;
    "")
        show_usage
        exit 1
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac

exit 0
