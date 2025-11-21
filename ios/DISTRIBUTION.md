# Cafe iOS App - Distribution Guide

## SideStore Distribution

### Prerequisites
1. **macOS with Xcode** (version 15.0 or later)
2. **SideStore** installed on iPhone and its anisette/VPN profile configured (per SideStore setup guide)
3. **Apple ID** (free or paid works; SideStore handles renewals without AltServer once configured)

### Building for Distribution

#### 1. Configure Signing
```bash
# Open project in Xcode
open ios/Cafe.xcodeproj

# In Xcode:
# 1. Select Cafe target
# 2. Go to "Signing & Capabilities"
# 3. Select your Team (Personal Team works)
# 4. Bundle ID: org.halext.Cafe (or change to your own)
```

#### 2. Add Privacy Descriptions
The app needs these privacy permissions. Add to `Info.plist` or target settings:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Cafe needs access to your photos to attach images to tasks and messages</string>

<key>NSCameraUsageDescription</key>
<string>Cafe needs camera access to capture images and scan documents</string>

<key>NSMicrophoneUsageDescription</key>
<string>Cafe needs microphone access for voice input and speech recognition</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Cafe uses speech recognition to convert your voice to text</string>

<key>NSFaceIDUsageDescription</key>
<string>Cafe uses Face ID to securely lock and unlock the app</string>
```

#### 3. Build IPA

**Option A: Xcode Archive (Recommended)**
```bash
# 1. In Xcode menu: Product → Archive
# 2. Wait for archive to complete
# 3. Window → Organizer opens automatically
# 4. Select your archive
# 5. Click "Distribute App"
# 6. Select "Custom"
# 7. Select "Development" or "Ad Hoc"
# 8. Select "App Thinning: None"
# 9. Select "Rebuild from Bitcode: No"
# 10. Click "Export"
# 11. Choose save location
```

**Option A: Command Line Build**
```bash
cd ios

# Clean build folder
xcodebuild clean -scheme Cafe

# Archive the app
xcodebuild archive \
  -scheme Cafe \
  -archivePath ./build/Cafe.xcarchive \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO

# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/Cafe.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

#### 4. Install via SideStore

**On your iPhone:**
1. Open **SideStore** (enable its VPN/anisette toggle if prompted)
2. Tap **My Apps**
3. Tap **+** button
4. Select the `Cafe.ipa` file (from AirDrop/Files)
5. Sign with your Apple ID when prompted; SideStore signs on-device
6. App appears on home screen—no AltServer/tether required!

### Sharing with Others

#### Method 1: Direct IPA Share
1. Build the IPA (steps above)
2. Upload `Cafe.ipa` to cloud storage (Dropbox, Google Drive, etc.)
3. Share link with others
4. They install via SideStore

#### Method 2: SideStore Source (Advanced)
1. Host the IPA on a web server
2. Create `apps.json` manifest:

```json
{
  "name": "Halext Apps",
  "identifier": "org.halext.sidestore",
  "sourceURL": "https://your-domain.com/apps.json",
  "apps": [
    {
      "name": "Cafe",
      "bundleIdentifier": "org.halext.Cafe",
      "developerName": "Halext Org",
      "version": "1.0.0",
      "versionDate": "2025-01-19",
      "downloadURL": "https://your-domain.com/Cafe.ipa",
      "localizedDescription": "Your productivity companion",
      "iconURL": "https://your-domain.com/icon.png",
      "size": 25000000,
      "screenshotURLs": [
        "https://your-domain.com/screenshot1.png"
      ]
    }
  ]
}
```

3. Add source to SideStore (uses the same JSON format):
   - Open SideStore
   - Tap **Sources** tab
   - Tap **+** button
   - Enter: `https://your-domain.com/apps.json`

### For Your Girlfriend

**Quick Setup:**
1. Build IPA on your Mac
2. AirDrop the `.ipa` file to her iPhone
3. She opens SideStore
4. Taps **+** to install
5. Logs in with her Apple ID (SideStore signs on-device)

**Note:** SideStore apps still follow Apple’s 7-day free-profile window but SideStore will auto-refresh as long as its anisette/VPN session is available (paid developer IDs last 365 days).

---

## TestFlight Distribution (Alternative)

If you have a paid Apple Developer account ($99/year):

### 1. App Store Connect Setup
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Create new app
3. Fill in app information
4. Enable TestFlight

### 2. Upload Build
```bash
# In Xcode:
# Product → Archive
# Upload to App Store Connect
```

### 3. Add Testers
1. Go to TestFlight tab
2. Add internal or external testers
3. Send email invites
4. Testers install via TestFlight app

### Benefits
- No 7-day refresh requirement
- Easier for non-technical users
- Official Apple distribution
- Up to 10,000 testers

---

## Backend Configuration

### Production API
The app is currently configured to use:
- **Production:** `https://org.halext.org/api`
- **Development:** `http://127.0.0.1:8000` (DEBUG only)

### Creating User Accounts

**Option 1: Via App**
- Tap "Don't have an account? Register"
- Enter username, email, password
- Account created!

**Option 2: Via Backend Script**
```bash
cd backend
python create_dev_user.py --username girlfriend --email gf@example.com
```

---

## Troubleshooting

### "Untrusted Developer"
1. Settings → General → VPN & Device Management
2. Trust the developer profile
3. Return to app and launch

### "Unable to Verify App"
- Make sure you're connected to internet
- SideStore needs to verify signature with Apple; ensure its VPN/anisette toggle is on

### App Crashes on Launch
- Check Xcode console for errors
- Ensure all permissions are granted
- Try reinstalling

### Sync Not Working
- Check internet connection
- Verify backend is running
- Check login credentials
- Look at app logs in Settings

---

## App Features

✅ **Fully Implemented**
- Task Management (create, edit, complete, delete)
- Calendar Events
- AI Chat Assistant
- User-to-user Messaging
- 15 Theme Options (light/dark)
- Customizable Navigation
- Offline Sync
- Biometric App Lock
- Notifications
- Widgets & Live Activities
- Document Scanning (OCR)
- Speech Recognition
- File Attachments

⏳ **Backend Integration Needed**
- Online/Offline Status (presence system ready on iOS)
- Financial Management (UI ready, API needed)
- Pages with Layouts (UI ready, API partially done)

---

## Support

For issues or questions:
- Check app logs in Settings
- Review backend logs: `tail -f backend/app.log`
- GitHub Issues: [halext-org/issues](https://github.com/halext-org/halext-org/issues)

---

**Version:** 1.0.0
**Last Updated:** January 19, 2025
**Minimum iOS:** 17.0
**Bundle ID:** org.halext.Cafe
