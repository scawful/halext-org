#!/bin/bash
# ==============================================================================
# TestFlight Deployment Script
# ==============================================================================
# One-click deployment of the Cafe iOS app to TestFlight.
#
# This script orchestrates the entire deployment pipeline:
#   1. Pre-flight checks (project validation, signing, dependencies)
#   2. Version/build number management
#   3. Clean build and archive
#   4. Export for App Store distribution
#   5. Upload to App Store Connect / TestFlight
#   6. Optional: Send notification webhooks
#
# Usage:
#   ./scripts/deploy-testflight.sh [options]
#
# Options:
#   --bump-patch     Bump patch version before deploying
#   --bump-minor     Bump minor version before deploying
#   --bump-major     Bump major version before deploying
#   --bump-build     Bump build number only (default if no bump specified)
#   --skip-bump      Do not increment any version numbers
#   --skip-clean     Skip Xcode clean step
#   --skip-upload    Build and export but do not upload
#   --dry-run        Show what would happen without executing
#   --verbose        Enable verbose output
#   --help           Show this help message
#
# Environment:
#   Copy scripts/ios-testflight.env.example to scripts/ios-testflight.env
#   and configure your App Store Connect API credentials.
#
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_DIR="$PROJECT_ROOT/ios"
BUILD_DIR="$IOS_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/Cafe.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
EXPORT_OPTIONS_PATH="$BUILD_DIR/ExportOptions.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default options
BUMP_TYPE="build"
SKIP_BUMP=false
SKIP_CLEAN=false
SKIP_UPLOAD=false
DRY_RUN=false
VERBOSE=false

# Configuration defaults (can be overridden by env file)
XCODE_PROJECT="Cafe.xcodeproj"
XCODE_SCHEME="Cafe"
BUNDLE_IDENTIFIER="org.halext.Cafe"
EXPORT_METHOD="app-store"
UPLOAD_SYMBOLS="true"
INCLUDE_BITCODE="false"
COMPILE_BITCODE="false"
STRIP_SWIFT_SYMBOLS="true"
UPLOAD_TIMEOUT=3600

# ==============================================================================
# Helper Functions
# ==============================================================================

log_header() {
    echo ""
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo ""
}

log_step() {
    echo -e "${BLUE}>>> ${BOLD}$1${NC}"
}

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

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

show_usage() {
    echo "TestFlight Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --bump-patch     Bump patch version before deploying (1.0.0 -> 1.0.1)"
    echo "  --bump-minor     Bump minor version before deploying (1.0.0 -> 1.1.0)"
    echo "  --bump-major     Bump major version before deploying (1.0.0 -> 2.0.0)"
    echo "  --bump-build     Bump build number only (default)"
    echo "  --skip-bump      Do not increment any version numbers"
    echo "  --skip-clean     Skip Xcode clean step"
    echo "  --skip-upload    Build and export but do not upload to TestFlight"
    echo "  --dry-run        Show what would happen without executing"
    echo "  --verbose        Enable verbose output"
    echo "  --help           Show this help message"
    echo ""
    echo "Environment:"
    echo "  Configure scripts/ios-testflight.env with your App Store Connect credentials"
    echo ""
    echo "Examples:"
    echo "  $0                          # Deploy with build number increment"
    echo "  $0 --bump-patch             # Deploy with patch version bump"
    echo "  $0 --skip-upload            # Build and export only, no upload"
    echo "  $0 --dry-run --verbose      # Preview deployment steps"
    echo ""
}

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Deployment failed with exit code $exit_code"
        send_notification "failure"
    fi
}

trap cleanup EXIT

# ==============================================================================
# Load Environment
# ==============================================================================

load_env() {
    local env_file="$SCRIPT_DIR/ios-testflight.env"

    if [ -f "$env_file" ]; then
        log_verbose "Loading environment from $env_file"
        # shellcheck source=/dev/null
        source "$env_file"
    else
        log_warning "Environment file not found: $env_file"
        log_info "Using default configuration. Copy ios-testflight.env.example to configure."
    fi
}

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

preflight_checks() {
    log_header "Pre-flight Checks"
    local errors=0

    # Check Xcode project exists
    log_step "Checking Xcode project..."
    if [ ! -d "$IOS_DIR/$XCODE_PROJECT" ]; then
        log_error "Xcode project not found: $IOS_DIR/$XCODE_PROJECT"
        errors=$((errors + 1))
    else
        log_success "Xcode project found"
    fi

    # Check xcodebuild is available
    log_step "Checking Xcode CLI tools..."
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Install Xcode Command Line Tools."
        errors=$((errors + 1))
    else
        local xcode_version
        xcode_version=$(xcodebuild -version | head -1)
        log_success "$xcode_version installed"
    fi

    # Check code signing
    log_step "Checking code signing..."
    if ! security find-identity -v -p codesigning | grep -q "Apple Distribution\|Apple Development"; then
        log_warning "No distribution certificate found in keychain"
        log_info "Automatic signing may handle this, but verify in Xcode"
    else
        log_success "Code signing certificate found"
    fi

    # Check App Store Connect credentials for upload
    if [ "$SKIP_UPLOAD" != true ]; then
        log_step "Checking App Store Connect credentials..."

        if [ -n "$APP_STORE_CONNECT_KEY_ID" ] && [ -n "$APP_STORE_CONNECT_ISSUER_ID" ] && [ -f "$APP_STORE_CONNECT_KEY_PATH" ]; then
            log_success "App Store Connect API credentials configured"
        elif [ -n "$APPLE_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
            log_success "Apple ID with app-specific password configured"
        else
            log_warning "No App Store Connect credentials found"
            log_info "Upload will require manual authentication"
        fi
    fi

    # Check git status
    log_step "Checking git status..."
    if git -C "$PROJECT_ROOT" status --porcelain | grep -q .; then
        log_warning "Uncommitted changes detected"
        log_info "Consider committing changes before deployment"
    else
        log_success "Working directory clean"
    fi

    if [ $errors -gt 0 ]; then
        log_error "Pre-flight checks failed with $errors error(s)"
        exit 1
    fi

    log_success "All pre-flight checks passed"
}

# ==============================================================================
# Version Management
# ==============================================================================

bump_version() {
    log_header "Version Management"

    if [ "$SKIP_BUMP" = true ]; then
        log_info "Skipping version bump (--skip-bump flag)"
        return
    fi

    local version_script="$SCRIPT_DIR/ios-version-bump.sh"

    if [ ! -f "$version_script" ]; then
        log_error "Version bump script not found: $version_script"
        exit 1
    fi

    local bump_args="$BUMP_TYPE"

    if [ "$DRY_RUN" = true ]; then
        bump_args="$bump_args --dry-run"
    fi

    bump_args="$bump_args --no-commit"

    log_step "Bumping $BUMP_TYPE version..."
    bash "$version_script" $bump_args
}

# ==============================================================================
# Build and Archive
# ==============================================================================

clean_build() {
    log_header "Clean Build"

    if [ "$SKIP_CLEAN" = true ]; then
        log_info "Skipping clean (--skip-clean flag)"
        return
    fi

    log_step "Removing previous build artifacts..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would remove: $BUILD_DIR"
        return
    fi

    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    log_step "Cleaning Xcode derived data for project..."
    cd "$IOS_DIR"

    xcodebuild clean \
        -project "$XCODE_PROJECT" \
        -scheme "$XCODE_SCHEME" \
        -configuration Release \
        ${VERBOSE:+-verbose} 2>&1 | while read -r line; do
            if [ "$VERBOSE" = true ]; then
                echo "$line"
            elif [[ "$line" == *"error:"* ]] || [[ "$line" == *"warning:"* ]]; then
                echo "$line"
            fi
        done

    log_success "Clean completed"
}

build_archive() {
    log_header "Build Archive"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would archive to: $ARCHIVE_PATH"
        return
    fi

    mkdir -p "$BUILD_DIR"

    log_step "Archiving $XCODE_SCHEME..."
    cd "$IOS_DIR"

    local archive_cmd="xcodebuild archive \
        -project \"$XCODE_PROJECT\" \
        -scheme \"$XCODE_SCHEME\" \
        -archivePath \"$ARCHIVE_PATH\" \
        -configuration Release \
        CODE_SIGN_STYLE=Automatic \
        -allowProvisioningUpdates"

    log_verbose "Running: $archive_cmd"

    # Run archive with progress indicator
    local start_time
    start_time=$(date +%s)

    xcodebuild archive \
        -project "$XCODE_PROJECT" \
        -scheme "$XCODE_SCHEME" \
        -archivePath "$ARCHIVE_PATH" \
        -configuration Release \
        CODE_SIGN_STYLE=Automatic \
        -allowProvisioningUpdates 2>&1 | while read -r line; do
            if [ "$VERBOSE" = true ]; then
                echo "$line"
            elif [[ "$line" == *"error:"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ "$line" == *"warning:"* ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ "$line" == *"BUILD SUCCEEDED"* ]] || [[ "$line" == *"ARCHIVE SUCCEEDED"* ]]; then
                echo -e "${GREEN}$line${NC}"
            elif [[ "$line" == *"Compiling"* ]] || [[ "$line" == *"Linking"* ]]; then
                # Show progress dots for compile/link steps
                echo -n "."
            fi
        done

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    log_success "Archive completed in ${duration}s"
    log_info "Archive location: $ARCHIVE_PATH"
}

# ==============================================================================
# Export for App Store
# ==============================================================================

create_export_options() {
    log_step "Creating export options plist..."

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create: $EXPORT_OPTIONS_PATH"
        return
    fi

    cat > "$EXPORT_OPTIONS_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>uploadSymbols</key>
    <${UPLOAD_SYMBOLS}/>
    <key>uploadBitcode</key>
    <${INCLUDE_BITCODE}/>
    <key>compileBitcode</key>
    <${COMPILE_BITCODE}/>
    <key>stripSwiftSymbols</key>
    <${STRIP_SWIFT_SYMBOLS}/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

    log_verbose "Export options created at $EXPORT_OPTIONS_PATH"
}

export_archive() {
    log_header "Export Archive"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would export to: $EXPORT_PATH"
        return
    fi

    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_error "Archive not found: $ARCHIVE_PATH"
        log_info "Run the archive step first"
        exit 1
    fi

    create_export_options

    log_step "Exporting for $EXPORT_METHOD distribution..."
    cd "$IOS_DIR"

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
        -allowProvisioningUpdates 2>&1 | while read -r line; do
            if [ "$VERBOSE" = true ]; then
                echo "$line"
            elif [[ "$line" == *"error:"* ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ "$line" == *"EXPORT SUCCEEDED"* ]]; then
                echo -e "${GREEN}$line${NC}"
            fi
        done

    local ipa_file="$EXPORT_PATH/Cafe.ipa"
    if [ -f "$ipa_file" ]; then
        local ipa_size
        ipa_size=$(du -h "$ipa_file" | cut -f1)
        log_success "Export completed"
        log_info "IPA file: $ipa_file ($ipa_size)"
    else
        log_error "IPA file not found after export"
        exit 1
    fi
}

# ==============================================================================
# Upload to TestFlight
# ==============================================================================

upload_to_testflight() {
    log_header "Upload to TestFlight"

    if [ "$SKIP_UPLOAD" = true ]; then
        log_info "Skipping upload (--skip-upload flag)"
        if [ "$DRY_RUN" != true ]; then
            log_info "IPA file ready for manual upload: $EXPORT_PATH/Cafe.ipa"
        fi
        return
    fi

    local ipa_file="$EXPORT_PATH/Cafe.ipa"

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would upload: $ipa_file"
        return
    fi

    if [ ! -f "$ipa_file" ]; then
        log_error "IPA file not found: $ipa_file"
        exit 1
    fi

    # Determine upload method
    if [ -n "$APP_STORE_CONNECT_KEY_ID" ] && [ -n "$APP_STORE_CONNECT_ISSUER_ID" ] && [ -f "$APP_STORE_CONNECT_KEY_PATH" ]; then
        upload_via_api "$ipa_file"
    elif [ -n "$APPLE_ID" ] && [ -n "$APPLE_APP_SPECIFIC_PASSWORD" ]; then
        upload_via_altool "$ipa_file"
    else
        upload_interactive "$ipa_file"
    fi
}

upload_via_api() {
    local ipa_file="$1"

    log_step "Uploading via App Store Connect API..."

    xcrun notarytool submit "$ipa_file" \
        --key "$APP_STORE_CONNECT_KEY_PATH" \
        --key-id "$APP_STORE_CONNECT_KEY_ID" \
        --issuer "$APP_STORE_CONNECT_ISSUER_ID" \
        --wait \
        --timeout "$UPLOAD_TIMEOUT" 2>&1 || {

        # notarytool is for macOS, use altool for iOS
        log_info "Using xcrun altool for iOS upload..."

        xcrun altool --upload-app \
            -f "$ipa_file" \
            -t ios \
            --apiKey "$APP_STORE_CONNECT_KEY_ID" \
            --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" 2>&1
    }

    log_success "Upload completed"
}

upload_via_altool() {
    local ipa_file="$1"

    log_step "Uploading via altool with app-specific password..."

    xcrun altool --upload-app \
        -f "$ipa_file" \
        -t ios \
        -u "$APPLE_ID" \
        -p "$APPLE_APP_SPECIFIC_PASSWORD" 2>&1

    log_success "Upload completed"
}

upload_interactive() {
    local ipa_file="$1"

    log_warning "No credentials configured for automated upload"
    echo ""
    echo "To upload manually, use one of these methods:"
    echo ""
    echo "Option 1: xcrun altool (requires Apple ID)"
    echo "  xcrun altool --upload-app -f '$ipa_file' -t ios -u YOUR_APPLE_ID"
    echo ""
    echo "Option 2: Xcode Organizer"
    echo "  1. Open Xcode"
    echo "  2. Window > Organizer"
    echo "  3. Select the archive"
    echo "  4. Click 'Distribute App'"
    echo "  5. Choose 'TestFlight & App Store'"
    echo ""
    echo "Option 3: Transporter App"
    echo "  1. Open Transporter from Mac App Store"
    echo "  2. Drag and drop the IPA file"
    echo "  3. Click Deliver"
    echo ""

    read -rp "Would you like to open the archive in Xcode Organizer? (y/n) " response
    if [ "$response" = "y" ]; then
        open "$ARCHIVE_PATH"
    fi
}

# ==============================================================================
# Notifications
# ==============================================================================

send_notification() {
    local status="$1"

    local version build
    version=$("$SCRIPT_DIR/ios-version-bump.sh" show 2>/dev/null | grep "Marketing Version" | awk '{print $3}' || echo "unknown")
    build=$("$SCRIPT_DIR/ios-version-bump.sh" show 2>/dev/null | grep "Build Number" | awk '{print $3}' || echo "unknown")

    local message
    if [ "$status" = "success" ]; then
        message="Cafe iOS v$version ($build) deployed to TestFlight successfully"
    else
        message="Cafe iOS deployment failed"
    fi

    # Slack notification
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        log_verbose "Sending Slack notification..."
        curl -s -X POST "$SLACK_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\": \"$message\"}" > /dev/null 2>&1 || true
    fi

    # Discord notification
    if [ -n "$DISCORD_WEBHOOK_URL" ]; then
        log_verbose "Sending Discord notification..."
        curl -s -X POST "$DISCORD_WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" > /dev/null 2>&1 || true
    fi
}

# ==============================================================================
# Summary
# ==============================================================================

show_summary() {
    log_header "Deployment Summary"

    local version build
    version=$("$SCRIPT_DIR/ios-version-bump.sh" show 2>/dev/null | grep "Marketing Version" | awk '{print $3}' || echo "unknown")
    build=$("$SCRIPT_DIR/ios-version-bump.sh" show 2>/dev/null | grep "Build Number" | awk '{print $3}' || echo "unknown")

    echo "  App:            Cafe"
    echo "  Version:        $version ($build)"
    echo "  Archive:        $ARCHIVE_PATH"
    echo "  IPA:            $EXPORT_PATH/Cafe.ipa"
    echo ""

    if [ "$SKIP_UPLOAD" = true ]; then
        echo "  Status:         Built (upload skipped)"
    else
        echo "  Status:         Uploaded to TestFlight"
    fi

    echo ""
    log_success "Deployment completed successfully"

    if [ "$SKIP_UPLOAD" != true ]; then
        echo ""
        echo "Next steps:"
        echo "  1. Go to App Store Connect > TestFlight"
        echo "  2. Wait for build processing (usually 10-30 minutes)"
        echo "  3. Add internal/external testers"
        echo "  4. Submit for review (external testers only)"
        echo ""
    fi
}

# ==============================================================================
# Parse Arguments
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --bump-patch)
            BUMP_TYPE="patch"
            shift
            ;;
        --bump-minor)
            BUMP_TYPE="minor"
            shift
            ;;
        --bump-major)
            BUMP_TYPE="major"
            shift
            ;;
        --bump-build)
            BUMP_TYPE="build"
            shift
            ;;
        --skip-bump)
            SKIP_BUMP=true
            shift
            ;;
        --skip-clean)
            SKIP_CLEAN=true
            shift
            ;;
        --skip-upload)
            SKIP_UPLOAD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
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

main() {
    log_header "Cafe iOS TestFlight Deployment"

    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    load_env
    preflight_checks
    bump_version
    clean_build
    build_archive
    export_archive
    upload_to_testflight
    send_notification "success"
    show_summary
}

main
