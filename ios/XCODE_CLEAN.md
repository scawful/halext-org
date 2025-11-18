# Xcode Build Issues - Quick Fixes

If you're seeing compilation errors that don't make sense or persist after fixing:

## 1. Clean Build Folder (First Try)

In Xcode:
```
Shift + Cmd + K
```

Or menu: **Product** > **Clean Build Folder**

Then rebuild: **Cmd + B**

## 2. Delete Derived Data (If Clean Doesn't Work)

Close Xcode first, then:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/
```

Reopen Xcode and build.

## 3. Reset Package Caches (If Using SPM)

In Xcode:
```
File > Packages > Reset Package Caches
```

## 4. Restart Xcode

Sometimes Xcode just needs a restart:
1. Quit Xcode (Cmd+Q)
2. Reopen: `open Cafe.xcodeproj`
3. Build (Cmd+B)

## 5. Nuclear Option (If All Else Fails)

```bash
# Close Xcode first!
rm -rf ~/Library/Developer/Xcode/DerivedData/
rm -rf ~/Library/Caches/com.apple.dt.Xcode/

# Then reopen and rebuild
open Cafe.xcodeproj
```

## Common Issues

### "Trailing closure passed to parameter of type 'any Decoder'"

This usually means Xcode is confused about closure syntax. After you've updated the code:
1. Clean build folder (Shift+Cmd+K)
2. Rebuild (Cmd+B)

### Files Not Found

Make sure all files are added to the Cafe target:
1. Select file in Project Navigator
2. Right panel > Target Membership
3. Check "Cafe" is enabled

### Swift Version Mismatch

Check your Swift version matches:
- Xcode > Settings > Locations > Command Line Tools (should be latest)
- Project > Build Settings > Swift Language Version (should be Swift 6 or Swift 5)

## Your Current Issue

For the LoginView.swift error, try this sequence:

1. **Close Xcode**
2. **Clean derived data**:
   ```bash
   cd /Users/scawful/Code/halext-org/ios
   rm -rf ~/Library/Developer/Xcode/DerivedData/
   ```
3. **Reopen**:
   ```bash
   open Cafe.xcodeproj
   ```
4. **Clean and rebuild**:
   - Shift+Cmd+K (clean)
   - Cmd+B (build)

If that doesn't work, the file might not have saved properly. Pull latest from git:

```bash
git status  # Check for local changes
git pull    # Get latest
```

Then reopen Xcode and build.
