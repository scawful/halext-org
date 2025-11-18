# Getting Cafe on Your iPhones

Complete guide for installing the Cafe app on your and your partner's iPhones.

## Quick Overview

**For Your iPhone**: Direct development installation (free, 7-day expiry)
**For Partner's iPhone**: TestFlight (free, 90-day expiry, professional)

---

## Part 1: Installing on YOUR iPhone (Development Build)

### Prerequisites
- USB-C cable to connect iPhone to Mac
- Your iPhone running iOS 17+
- Xcode installed on your Mac

### Step 1: Connect Your iPhone

1. Connect iPhone to Mac via USB-C cable
2. Unlock your iPhone
3. If prompted "Trust This Computer?", tap **Trust**
4. Enter your iPhone passcode

### Step 2: Add Your Apple ID to Xcode

1. Open Xcode
2. Go to **Xcode** > **Settings** (or Preferences)
3. Click **Accounts** tab
4. Click **+** button in bottom left
5. Select **Apple ID**
6. Sign in with your Apple ID (the one used on your iPhone)
7. Close Settings

### Step 3: Configure Signing

1. Open `Cafe.xcodeproj` in Xcode
2. Select **Cafe** project in Project Navigator (top of sidebar)
3. Select **Cafe** target
4. Go to **Signing & Capabilities** tab
5. Check **Automatically manage signing**
6. Select your **Team** (your Apple ID name)
7. Xcode will automatically create a provisioning profile

**If you see "Failed to create provisioning profile"**:
- Change the **Bundle Identifier** to something unique
- Example: `org.halext.Cafe` → `org.halext.Cafe.yourname`
- Try again

### Step 4: Select Your Device

1. At the top of Xcode, click the device selector (next to the Run button)
2. Look for your iPhone name under **iOS Device**
3. Select your iPhone

### Step 5: Run the App

1. Press **Cmd+R** or click the ▶️ Play button
2. Xcode will:
   - Build the app (~1-2 minutes first time)
   - Install it on your iPhone
   - Launch it automatically

### Step 6: Trust Developer Certificate (First Time Only)

If the app doesn't launch and shows "Untrusted Developer":

1. On your iPhone: **Settings** > **General** > **VPN & Device Management**
2. Under **Developer App**, tap your Apple ID
3. Tap **Trust "[Your Apple ID]"**
4. Tap **Trust** in the dialog
5. Go back to Home Screen and launch Cafe

### Step 7: Connect to Backend

Since your iPhone can't access `localhost`, you need to use your Mac's IP address:

#### Find Your Mac's IP Address
```bash
# Run this in Terminal
ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1
```

You'll see something like: `inet 192.168.1.XXX`

#### Update APIClient (Temporary for Testing)

Open `ios/Cafe/Cafe/Core/API/APIClient.swift` and modify:

```swift
enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            // Change this to your Mac's IP:
            return "http://192.168.1.XXX:8000"  // ← Use your actual IP
        case .production:
            return "https://org.halext.org/api"
        }
    }
}
```

**Important**: Both your iPhone and Mac must be on the same WiFi network!

#### Rebuild and Test
1. Press Cmd+R to rebuild
2. Login with dev/dev123
3. You should see your tasks!

### Limitations of Development Builds

- **Expires after 7 days** - You'll need to rebuild weekly
- **Only works with your Apple ID** - Can't share this way
- **Must be connected to Mac** to reinstall

For your partner, we'll use TestFlight instead!

---

## Part 2: Installing on PARTNER's iPhone (TestFlight)

TestFlight is Apple's official beta testing platform. Much better for sharing!

### Prerequisites
- Apple Developer Account ($99/year) - **OR** use free account with limitations
- Partner's Apple ID email address

### Option A: Free Apple Developer Account (Limitations)

With a free account:
- ✅ TestFlight works
- ❌ Limited to 100 testers
- ❌ Builds expire after 90 days
- ❌ Cannot publish to App Store
- ✅ Perfect for 2 people!

### Option B: Paid Apple Developer Program ($99/year)

Benefits:
- ✅ Unlimited internal testers (up to 10,000 external)
- ✅ App Store publishing
- ✅ Advanced capabilities
- ✅ Professional support

**Recommendation**: Start with free for testing, upgrade later if needed.

### Step 1: Enroll in Apple Developer Program

#### For Free Account (Already Done!)
You're already enrolled when you added your Apple ID to Xcode. Skip to Step 2.

#### For Paid Account
1. Go to https://developer.apple.com/programs/enroll/
2. Sign in with your Apple ID
3. Complete enrollment and payment
4. Wait for approval (1-2 days)

### Step 2: Register Your App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Sign in with your Apple ID
3. Click **My Apps**
4. Click **+** button, select **New App**

Fill in:
- **Platforms**: iOS
- **Name**: Cafe
- **Primary Language**: English
- **Bundle ID**: Select the one from Xcode (org.halext.Cafe or your custom one)
- **SKU**: cafe-app (can be anything unique)
- **User Access**: Full Access

Click **Create**

### Step 3: Prepare App for Archive

1. Open `Cafe.xcodeproj` in Xcode
2. Select **Any iOS Device (arm64)** as the destination (not a simulator!)
3. Make sure backend URL is set correctly (use production URL or your Mac's IP)

### Step 4: Archive the App

1. Go to **Product** > **Archive**
2. Wait for the archive to complete (2-5 minutes)
3. The **Organizer** window will open automatically

If archive fails:
- Make sure you selected **Any iOS Device**, not a simulator
- Check that Signing & Capabilities is configured correctly
- Clean build folder: **Product** > **Clean Build Folder**

### Step 5: Upload to App Store Connect

1. In the Organizer, select your archive
2. Click **Distribute App**
3. Select **TestFlight & App Store**
4. Click **Next**
5. Select **Upload**
6. Click **Next** through the options:
   - **Automatically manage signing** ✅
   - **Upload** (default options are fine)
7. Click **Upload**
8. Wait for upload to complete (5-10 minutes)

### Step 6: Wait for Processing

1. Go to https://appstoreconnect.apple.com
2. Click **My Apps** > **Cafe**
3. Go to **TestFlight** tab
4. You'll see your build under **iOS Builds**
5. Status will show "Processing" - this takes 10-30 minutes
6. You'll get an email when it's ready

### Step 7: Add Your Partner as a Tester

Once processing is complete:

1. In TestFlight tab, click **Internal Testing** (left sidebar)
2. Click **+** next to "Internal Group"
3. Or click the default group "App Store Connect Users"
4. Click **Testers** > **+**
5. Enter your partner's email address
6. Click **Add**

**Internal vs External Testing**:
- **Internal**: Up to 100 users, no review needed, instant access
- **External**: More testers, requires Apple review (1-2 days)

For 2 people, use Internal Testing.

### Step 8: Partner Installation

Your partner will:

1. **Receive invitation email** from App Store Connect
2. **Install TestFlight** app from App Store (if not already installed)
3. **Open the invitation email** on their iPhone
4. **Tap "View in TestFlight"** - opens TestFlight app
5. **Tap "Accept"** to accept the invitation
6. **Tap "Install"** to download Cafe
7. **Launch Cafe** from Home Screen

### Step 9: Partner Setup

Your partner needs to:

1. Make sure their iPhone is on the **same WiFi as your Mac** (for development testing)
   - Or wait until you deploy to production server at org.halext.org

2. Open Cafe and register a new account
   - Or use the access code if required

3. Start using the app!

### Updating the App via TestFlight

When you make changes:

1. Increment the build number:
   - In Xcode: Select project > Build Settings > Search "build"
   - Increment "CURRENT_PROJECT_VERSION" (e.g., 1 → 2)

2. Archive again (Product > Archive)
3. Upload to TestFlight
4. Partner will get a notification to update
5. They open TestFlight and tap "Update"

---

## Part 3: Production Deployment (Future)

When your backend is live at `org.halext.org`:

### Backend is Ready When:
1. ✅ Deployed to Ubuntu server at org.halext.org
2. ✅ HTTPS is configured with SSL certificate
3. ✅ API is accessible at `https://org.halext.org/api`
4. ✅ Access codes are configured

### Update iOS App:
1. In `APIClient.swift`, verify production URL:
   ```swift
   case .production:
       return "https://org.halext.org/api"
   ```

2. Build in **Release** mode (not Debug):
   - Product > Scheme > Edit Scheme
   - Select "Run" on left
   - Change "Build Configuration" to **Release**

3. Archive and upload to TestFlight

4. Now the app will use production server automatically!

5. Partner can use from anywhere (not just same WiFi)

---

## Quick Reference

### Installing on YOUR phone:
```
1. Connect iPhone via USB-C
2. Trust computer
3. Open Xcode project
4. Select your iPhone as destination
5. Cmd+R to run
6. Trust developer in Settings if needed
7. Update API URL to Mac's IP
```

### Installing on PARTNER's phone:
```
1. Archive app in Xcode (Product > Archive)
2. Upload to TestFlight
3. Add partner as tester in App Store Connect
4. Partner installs TestFlight from App Store
5. Partner opens invitation email
6. Partner installs Cafe via TestFlight
```

### Troubleshooting

**"Failed to create provisioning profile"**
- Change Bundle Identifier to something unique
- Make sure you're signed in with Apple ID in Xcode

**"The operation couldn't be completed"**
- Clean build folder (Cmd+Shift+K)
- Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/`
- Restart Xcode

**"Unable to install"**
- Check that iPhone iOS version is compatible
- Make sure you trusted your developer certificate
- Try deleting the app and reinstalling

**App can't reach backend**
- Both devices must be on same WiFi (for development)
- Check firewall isn't blocking port 8000
- Verify backend is running: `./dev-reload.sh`
- Test from iPhone browser: `http://YOUR_MAC_IP:8000/docs`

**TestFlight upload stuck**
- Make sure you selected "Any iOS Device", not a simulator
- Check internet connection
- Try uploading from Xcode > Window > Organizer

**Partner can't see TestFlight invitation**
- Check spam folder
- Resend invitation from App Store Connect
- Make sure they're using the email associated with their Apple ID

---

## Network Setup for Development

### Option 1: Same WiFi (Easiest for Testing)

Both iPhone and Mac on same WiFi:
- Mac runs backend on `192.168.1.XXX:8000`
- iPhone connects to that IP
- Works great for testing

### Option 2: USB Tethering (If WiFi Issues)

You can use iPhone's network:
1. iPhone Settings > Personal Hotspot > Turn on
2. Connect Mac to iPhone hotspot
3. Find new IP address
4. Update APIClient with new IP

### Option 3: Production Server (Best Long-term)

Deploy backend to org.halext.org:
- iPhone accesses `https://org.halext.org/api`
- Works from anywhere
- No IP address changes needed
- Most reliable for both users

---

## Cost Summary

**Free Option**:
- ✅ Development builds on your iPhone: **FREE**
- ✅ TestFlight for partner: **FREE**
- ❌ Limited to 90-day builds
- ❌ Cannot publish to App Store

**Paid Option** ($99/year):
- ✅ Everything above
- ✅ App Store publishing
- ✅ Extended capabilities
- ✅ Better for long-term

**Recommendation**: Start free, upgrade if you want to publish to App Store.

---

Ready to get started? Open Xcode and connect your iPhone!
