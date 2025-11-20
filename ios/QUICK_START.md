# Quick Start: Install Cafe on Your iPhone (Free Apple ID)

## Prerequisites
- Mac with Xcode installed ✅
- iPhone with cable ✅
- Free Apple ID ✅

## Steps

### 1. Setup Signing (ONE TIME)

```bash
cd /Users/scawful/Code/halext-org/ios
open Cafe.xcodeproj
```

In Xcode:
- Click **Cafe** (blue icon in left sidebar)
- Select **Cafe** target
- Go to **"Signing & Capabilities"** tab
- **Check** "Automatically manage signing"
- **Team:** Select your Apple ID (shows as "Your Name (Personal Team)")
- **Bundle Identifier:** Change to `com.YOURNAME.Cafe` (must be unique)

### 2. Connect Your iPhone

- Plug in iPhone via USB
- **Trust this computer** on iPhone when prompted
- In Xcode toolbar, click device dropdown → Select your iPhone

### 3. Install

- Press **▶️ (Run)** button or press **⌘R**
- Wait 30-60 seconds
- App appears on your iPhone!

### 4. Trust Developer (FIRST TIME ONLY)

On iPhone:
1. Tap Cafe icon → "Untrusted Developer" message
2. Settings → General → VPN & Device Management
3. Tap your Apple ID under "Developer App"
4. Tap "Trust [your email]"
5. Confirm

### 5. Launch Cafe

- Open Cafe app
- Register account
- Done! 🎉

## For Chris's Phone

**Option A - Use Your Mac:**
- Connect Chris's phone
- Select it in Xcode
- Press ▶️ Run
- Done!

**Option B - Chris Does It:**
- Send Chris the repo
- Chris opens in Xcode on their computer
- Chris signs with their Apple ID
- Chris runs to their phone

## Refresh Weekly

Every 7 days:
1. Connect iPhone to Mac
2. Open Xcode project
3. Press ▶️ Run
4. Good for another 7 days

## Tips

- **WiFi Debugging:** Enable in Xcode for wireless installs
- **Keep Xcode Open:** Faster refreshes
- **Set Calendar Reminder:** Every 6 days to refresh

## Troubleshooting

**"Failed to verify code signature"**
→ Go to Settings → General → VPN & Device Management → Trust

**"iPhone is busy"**
→ Wait a moment and try again

**"No code signing identities found"**
→ Make sure you're logged into Apple ID in Xcode Preferences

**"Could not launch"**
→ Trust the developer on iPhone (Settings)

---

**Need help?** Check DISTRIBUTION.md for full details.
