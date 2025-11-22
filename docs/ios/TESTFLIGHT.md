# TestFlight Deployment Guide

This guide covers automated and manual deployment of the Cafe iOS app to TestFlight for beta testing.

## Quick Start

For one-click deployment:

```bash
# Deploy with build number increment (default)
./scripts/deploy-testflight.sh

# Deploy with patch version bump (1.0.0 -> 1.0.1)
./scripts/deploy-testflight.sh --bump-patch

# Preview what would happen without making changes
./scripts/deploy-testflight.sh --dry-run --verbose
```

## Prerequisites

### 1. Apple Developer Program

You need an active [Apple Developer Program](https://developer.apple.com/programs/) membership ($99/year).

### 2. App Store Connect Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** > **+** > **New App**
3. Fill in the app details:
   - Platform: iOS
   - Name: Cafe
   - Primary Language: English (US)
   - Bundle ID: `org.halext.Cafe`
   - SKU: `cafe-ios` (or any unique identifier)

### 3. Code Signing

The project uses **Automatic Signing**. Ensure:

1. Your Apple ID is added to Xcode (Preferences > Accounts)
2. Your Developer Team is selected in the project settings
3. Xcode can manage certificates and provisioning profiles

### 4. App Store Connect API (Recommended)

For fully automated uploads, configure the App Store Connect API:

1. Go to [App Store Connect > Users and Access > Integrations](https://appstoreconnect.apple.com/access/integrations)
2. Click **App Store Connect API** > **Generate API Key**
3. Select **Admin** or **App Manager** access
4. Download the `.p8` key file (you can only download it once)
5. Note the **Key ID** and **Issuer ID**

Store the key securely:

```bash
mkdir -p ~/.appstoreconnect
mv ~/Downloads/AuthKey_KEYID.p8 ~/.appstoreconnect/
chmod 600 ~/.appstoreconnect/AuthKey_*.p8
```

## Configuration

### Environment File Setup

Copy the example environment file and configure your credentials:

```bash
cp scripts/ios-testflight.env.example scripts/ios-testflight.env
```

Edit `scripts/ios-testflight.env`:

```bash
# App Store Connect API (recommended)
APP_STORE_CONNECT_KEY_ID="ABC123XYZ"
APP_STORE_CONNECT_ISSUER_ID="12345678-abcd-1234-efgh-123456789012"
APP_STORE_CONNECT_KEY_PATH="$HOME/.appstoreconnect/AuthKey_ABC123XYZ.p8"

# OR use Apple ID with app-specific password
APPLE_ID="your-apple-id@email.com"
APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

# Team ID (from Apple Developer Portal)
DEVELOPMENT_TEAM="TEAM123456"
```

**Important:** Never commit `ios-testflight.env` to version control. It should be in `.gitignore`.

## Deployment Scripts

### Main Deployment Script

The unified deployment script handles the entire pipeline:

```bash
./scripts/deploy-testflight.sh [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--bump-patch` | Bump patch version (1.0.0 -> 1.0.1) |
| `--bump-minor` | Bump minor version (1.0.0 -> 1.1.0) |
| `--bump-major` | Bump major version (1.0.0 -> 2.0.0) |
| `--bump-build` | Bump build number only (default) |
| `--skip-bump` | Do not increment version numbers |
| `--skip-clean` | Skip Xcode clean step |
| `--skip-upload` | Build and export only, no upload |
| `--dry-run` | Preview changes without executing |
| `--verbose` | Enable verbose output |

**Examples:**

```bash
# Standard deployment (increments build number)
./scripts/deploy-testflight.sh

# New feature release (minor version bump)
./scripts/deploy-testflight.sh --bump-minor

# Bug fix release (patch version bump)
./scripts/deploy-testflight.sh --bump-patch

# Build only, upload manually
./scripts/deploy-testflight.sh --skip-upload

# Debug a failed deployment
./scripts/deploy-testflight.sh --verbose
```

### Version Bump Utility

Manage app versions independently:

```bash
./scripts/ios-version-bump.sh [command] [options]
```

**Commands:**

| Command | Description |
|---------|-------------|
| `show` | Display current version info |
| `build` | Increment build number only |
| `patch` | Bump patch version (1.0.0 -> 1.0.1) |
| `minor` | Bump minor version (1.0.0 -> 1.1.0) |
| `major` | Bump major version (1.0.0 -> 2.0.0) |
| `set VERSION` | Set specific version (e.g., `set 2.0.0`) |

**Options:**

| Option | Description |
|--------|-------------|
| `--no-commit` | Skip git commit |
| `--dry-run` | Preview changes |

**Examples:**

```bash
# Show current version
./scripts/ios-version-bump.sh show

# Increment build number
./scripts/ios-version-bump.sh build

# Set specific version
./scripts/ios-version-bump.sh set 2.0.0

# Preview patch bump
./scripts/ios-version-bump.sh patch --dry-run
```

### Individual Scripts (Legacy)

These scripts in `ios/scripts/` can be used for manual steps:

| Script | Description |
|--------|-------------|
| `preflight-check.sh` | Validate project before archiving |
| `increment-build.sh` | Simple build number increment |
| `archive-for-testflight.sh` | Create Xcode archive |
| `upload-to-testflight.sh` | Export and upload to TestFlight |
| `xcode-deep-clean.sh` | Nuclear clean of all Xcode caches |
| `get-device-udid.sh` | Get connected device UDID |

## Deployment Pipeline

The deployment script executes these steps:

```
1. Pre-flight Checks
   - Xcode project exists
   - Xcode CLI tools installed
   - Code signing certificates available
   - App Store Connect credentials configured
   - Git working directory status

2. Version Management
   - Bump version/build number as specified
   - Update project.pbxproj

3. Clean Build
   - Remove previous build artifacts
   - Clean Xcode derived data

4. Archive
   - Build Release configuration
   - Create .xcarchive

5. Export
   - Generate ExportOptions.plist
   - Export for App Store distribution
   - Create .ipa file

6. Upload
   - Upload to App Store Connect
   - Use API key or app-specific password

7. Notifications (Optional)
   - Send Slack/Discord webhook
```

## Manual Upload Methods

If automated upload fails, you can upload manually:

### Method 1: Xcode Organizer

1. Open Xcode
2. **Window** > **Organizer**
3. Select the archive
4. Click **Distribute App**
5. Choose **TestFlight & App Store**
6. Follow the prompts

### Method 2: xcrun altool

```bash
# With Apple ID
xcrun altool --upload-app \
    -f ios/build/export/Cafe.ipa \
    -t ios \
    -u "your-apple-id@email.com" \
    -p "@keychain:AC_PASSWORD"

# With App Store Connect API
xcrun altool --upload-app \
    -f ios/build/export/Cafe.ipa \
    -t ios \
    --apiKey "KEY_ID" \
    --apiIssuer "ISSUER_ID"
```

### Method 3: Transporter App

1. Install [Transporter](https://apps.apple.com/app/transporter/id1450874784) from Mac App Store
2. Drag and drop `ios/build/export/Cafe.ipa`
3. Click **Deliver**

## Post-Upload Steps

After successful upload:

### 1. Wait for Processing

App Store Connect processes uploads, typically 10-30 minutes. You will receive an email when complete.

### 2. Add Build Information

In App Store Connect > TestFlight:

1. Select the new build
2. Add **What to Test** notes
3. Fill in **Test Information** if required

### 3. Add Testers

**Internal Testers** (up to 100, immediate access):
1. Go to **TestFlight** > **Internal Testing**
2. Add testers by Apple ID email
3. No review required

**External Testers** (up to 10,000, requires review):
1. Go to **TestFlight** > **External Testing**
2. Create a group and add testers
3. Submit for beta review (usually 24-48 hours)

### 4. Distribute

Testers receive an email invitation to install via the TestFlight app.

## Troubleshooting

### Archive Fails

**"No signing certificate found"**

1. Open Xcode > Preferences > Accounts
2. Select your team
3. Click **Manage Certificates**
4. Create new certificate if needed

**"Provisioning profile doesn't match"**

1. In Xcode, select the project
2. Go to **Signing & Capabilities**
3. Enable **Automatically manage signing**
4. Select your team

### Upload Fails

**"Authentication failed"**

1. Verify credentials in `ios-testflight.env`
2. For Apple ID: Generate new app-specific password
3. For API: Check key ID and issuer ID match

**"App already exists with this version"**

Each upload must have a unique build number:

```bash
./scripts/ios-version-bump.sh build
```

**"Invalid IPA"**

Run deep clean and rebuild:

```bash
cd ios
./scripts/xcode-deep-clean.sh
cd ..
./scripts/deploy-testflight.sh
```

### Build Processing Issues

**"Missing compliance information"**

In App Store Connect:
1. Select the build
2. Click **Manage** next to Export Compliance
3. Answer encryption questions (typically "No" for standard HTTPS)

**"Missing required icons"**

Ensure Assets.xcassets contains all required app icons:
- 1024x1024 for App Store
- All required iOS icon sizes

## CI/CD Integration

For GitHub Actions integration, see the example workflow:

```yaml
# .github/workflows/testflight.yml
name: Deploy to TestFlight

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install certificates
        env:
          P12_CERTIFICATE: ${{ secrets.P12_CERTIFICATE }}
          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
        run: |
          # Import certificate to keychain
          echo "$P12_CERTIFICATE" | base64 --decode > certificate.p12
          security create-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P "$P12_PASSWORD" -A
          security set-keychain-settings build.keychain
          security unlock-keychain -p "" build.keychain

      - name: Create API key file
        env:
          APP_STORE_CONNECT_KEY: ${{ secrets.APP_STORE_CONNECT_KEY }}
        run: |
          mkdir -p ~/.appstoreconnect
          echo "$APP_STORE_CONNECT_KEY" > ~/.appstoreconnect/AuthKey.p8

      - name: Deploy to TestFlight
        env:
          APP_STORE_CONNECT_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
          APP_STORE_CONNECT_KEY_PATH: ~/.appstoreconnect/AuthKey.p8
        run: ./scripts/deploy-testflight.sh --bump-build
```

## Version History

| Version | Build | Date | Notes |
|---------|-------|------|-------|
| 1.0.0 | 1 | - | Initial release |

Update this table after each TestFlight deployment.

## Related Documentation

- [iOS Deployment Overview](/docs/ios/DEPLOYMENT.md)
- [iOS Quick Start Guide](/docs/ios/QUICK_START.md)
- [API Compatibility](/docs/ios/API_COMPATIBILITY.md)
- [Scripts README](/scripts/README.md)

## Support

For deployment issues:
1. Run with `--verbose` flag for detailed output
2. Check Xcode > Report Navigator for build logs
3. Verify App Store Connect status at [developer.apple.com/system-status](https://developer.apple.com/system-status)
