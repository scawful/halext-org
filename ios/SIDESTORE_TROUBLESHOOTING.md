# SideStore Installation Troubleshooting

## Certificate Revocation Error

### The Problem
When installing via SideStore, you see:
- "Do you want to revoke certificate X?" (e.g., "justins iphone")
- After clicking "Revoke" or "Yes", you get a **UDID error** and installation fails

### Why This Happens
SideStore detects old or conflicting certificates/provisioning profiles that contain UDID references. When it tries to revoke these certificates, it encounters UDID validation errors. This can happen if:
- The IPA contains embedded UDID references in Info.plist or provisioning profiles
- SideStore has cached certificates with UDID information
- Previous installations left certificate artifacts

## Solutions

### Solution 1: Rebuild with Clean IPA (Recommended)
The build script now removes ALL signing artifacts. Rebuild your IPA:

```bash
cd ios
./build-for-sidestore.sh
```

This creates a completely unsigned IPA that SideStore can sign fresh.

### Solution 2: Clear SideStore Certificate Cache (For UDID Errors)
If you get a UDID error when revoking certificates:

1. **Open SideStore** on your iPhone
2. Go to **Settings**
3. Look for **"Clear Certificate Cache"** or **"Reset Certificates"**
4. Clear the cache
5. Try installing the IPA again

**Alternative:** Sign out and back into SideStore:
1. SideStore → Settings → Account
2. Sign out
3. Sign back in with your Apple ID
4. Try installing again

### Solution 3: When SideStore Asks About Revoking
**It's safe to revoke!** SideStore needs to revoke old certificates to sign with your Apple ID.

1. Click **"Revoke"** or **"Yes"** when prompted
2. Wait for SideStore to complete the revocation
3. If you get a UDID error, try Solution 2 or Solution 1

### Solution 4: Delete Existing App First
Sometimes a previous installation leaves artifacts:

1. **Delete the Cafe app** from your iPhone (if it exists)
2. Go to Settings → General → VPN & Device Management
3. Remove any old developer certificates for Cafe
4. Rebuild and reinstall

### Solution 5: Check SideStore Setup
Make sure SideStore is properly configured:

1. **Anisette/VPN Setup:**
   - Open SideStore
   - Go to Settings
   - Ensure "Anisette" or "VPN" toggle is ON
   - This is required for SideStore to sign apps

2. **Apple ID Session:**
   - Make sure you're logged into SideStore with your Apple ID
   - Go to SideStore → Settings → Account
   - Sign in if needed

### Solution 6: Clear SideStore Cache
If issues persist:

1. Open SideStore
2. Go to Settings
3. Clear cache or restart SideStore
4. Try installing again

### Solution 7: Delete and Reinstall
1. Delete the failed IPA from your device
2. Rebuild the IPA on your Mac: `./build-for-sidestore.sh`
3. Transfer the NEW IPA to your device
4. Try installing again

## What the Build Script Does

The updated `build-for-sidestore.sh` script now:

✅ Removes ALL provisioning profiles (`embedded.mobileprovision`)  
✅ Removes ALL code signatures (`_CodeSignature` directories)  
✅ Removes signing-related Info.plist keys (including `ProvisionedDevices` with UDIDs)  
✅ Removes UDID patterns from all plist files  
✅ Removes Safari extension signing artifacts  
✅ Cleans extension Info.plist files  
✅ Verifies the app is completely unsigned and UDID-free  

This ensures SideStore can sign the app cleanly without conflicts.

## Still Having Issues?

### Check the IPA
You can verify the IPA is unsigned:

```bash
# On Mac, unzip and check
cd ios/build
unzip -q Cafe.ipa
find Payload -name "embedded.mobileprovision"
find Payload -name "_CodeSignature"
# Should return nothing if properly unsigned
```

### Common Issues

**"Failed to verify code signature"**
- The IPA might still have signing artifacts
- Rebuild with the updated script

**"App installation failed"**
- Check SideStore's anisette/VPN is enabled
- Make sure you're logged into SideStore with Apple ID
- Try deleting the app and reinstalling

**"Certificate error"**
- This is normal - SideStore needs to revoke old certs
- Click "Revoke" and let it complete
- If it fails, rebuild the IPA

## Prevention

To avoid certificate issues:

1. **Always use the build script:**
   ```bash
   ./build-for-sidestore.sh
   ```
   Don't use Xcode's Archive → Export for SideStore (it includes signing artifacts)

2. **Don't manually sign the IPA:**
   - SideStore will sign it on-device
   - Any pre-signing can cause conflicts

3. **Keep SideStore updated:**
   - Update SideStore regularly
   - Newer versions handle signing better

## Need More Help?

- Check SideStore documentation: https://sidestore.io
- SideStore Discord: https://discord.gg/sidestore
- Make sure your iOS version is compatible with SideStore

