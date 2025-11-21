# Quick TestFlight Upload

## Prerequisites Checklist

Before archiving:

- [ ] **Xcode project builds successfully** (Cmd+B in Xcode)
- [ ] **All Swift files added to project** (check Project Navigator)
- [ ] **Apple ID added to Xcode** (Xcode > Settings > Accounts)
- [ ] **Signing configured** (Project > Signing & Capabilities > Auto-manage)
- [ ] **App created in App Store Connect** (appstoreconnect.apple.com)

## Method 1: Xcode GUI (Easiest)

### 1. Prepare for Archive

In Xcode:
1. Select destination: **Any iOS Device (arm64)** (NOT a simulator!)
2. Verify bundle ID: `org.halext.Cafe`
3. Check version and build number in project settings

### 2. Archive

1. **Product** > **Archive**
2. Wait 2-5 minutes for build
3. Organizer window opens automatically

### 3. Upload to TestFlight

1. Select your archive in Organizer
2. Click **Distribute App**
3. Select **TestFlight & App Store**
4. Click **Next**
5. Select **Upload**
6. **Next** through options (defaults are fine)
7. Click **Upload**
8. Wait 5-10 minutes for upload

### 4. Wait for Processing

1. Go to https://appstoreconnect.apple.com
2. **My Apps** > **Cafe** > **TestFlight** tab
3. Build shows "Processing" (10-30 minutes)
4. You'll get email when ready

### 5. Add Tester

When processing complete:
1. TestFlight tab > **Internal Testing**
2. Click **+** to add tester
3. Enter partner's email
4. Click **Add**
5. Partner receives invitation email

## Method 2: Command Line (Advanced)

### Archive
```bash
cd /Users/scawful/Code/halext-org/ios
./scripts/archive-for-testflight.sh
```

### Upload via Xcode Organizer
After archiving, open Xcode Organizer and follow Method 1 steps.

## Method 3: Fully Automated (Coming Soon)

Will require App Store Connect API key setup.

## Troubleshooting

### "No accounts with App Store Connect access"
- Add Apple ID in Xcode > Settings > Accounts
- Or join Apple Developer Program ($99/year)

### "Failed to create provisioning profile"
- Make sure signing is set to Automatic
- Check bundle identifier is unique
- Try signing out/in of Apple ID in Xcode

### "Cannot archive - selected simulator"
- Change destination to **Any iOS Device (arm64)**
- Cannot archive for simulator

### Archive succeeds but upload fails
- Check internet connection
- Verify Apple ID credentials
- Try Xcode > Preferences > Accounts > Download Manual Profiles

## After First Upload

### Update the App Later

1. Make code changes
2. Increment build number:
   ```bash
   ./scripts/increment-build.sh
   ```
3. Archive again (Method 1, step 2-3)
4. Testers auto-notified of update

### Check Upload Status

App Store Connect > Cafe > Activity tab
- Shows all uploads and their status
- Processing times vary (10min - 2hrs)

## What Partner Sees

1. **Email invitation** from TestFlight
2. **Installs TestFlight** from App Store
3. **Opens invitation**, taps "Accept"
4. **Taps "Install"** in TestFlight app
5. **Launches Cafe** from home screen
6. **Creates account** and starts using!

## Quick Commands Reference

```bash
# Archive for TestFlight
./scripts/archive-for-testflight.sh

# Increment build number
./scripts/increment-build.sh

# Check project info
cd Cafe && xcodebuild -list

# Check bundle ID
grep PRODUCT_BUNDLE_IDENTIFIER Cafe.xcodeproj/project.pbxproj
```

## Next: App Store Connect Setup

If you haven't created the app yet:

1. Go to https://appstoreconnect.apple.com
2. Click **My Apps** > **+** > **New App**
3. Fill in:
   - Platform: iOS
   - Name: Cafe
   - Language: English
   - Bundle ID: org.halext.Cafe
   - SKU: cafe-app
4. Click **Create**

Now you're ready to upload!
