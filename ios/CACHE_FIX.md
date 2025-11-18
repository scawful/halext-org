# Fix: Xcode Showing Stale Errors

## The Problem

You're seeing this error:
```
/Users/scawful/Code/halext-org/ios/Cafe/Features/Auth/LoginView.swift:63:30
Trailing closure passed to parameter of type 'any Decoder' that does not accept a closure
```

But the code at line 63 is actually correct:
```swift
Button(action: {  // ← This is the RIGHT syntax
    Task {
        await appState.login(username: username, password: password)
    }
}) {
    // Button content
}
```

**This is an Xcode caching issue.** Xcode is showing you errors from old code that's been fixed.

## The Solution

### Step 1: Quit Xcode Completely

**Cmd+Q** to quit (don't just close the window!)

Or from terminal:
```bash
killall Xcode
```

### Step 2: Deep Clean

```bash
cd /Users/scawful/Code/halext-org/ios
./scripts/xcode-deep-clean.sh
```

This removes:
- DerivedData (build artifacts)
- Xcode caches
- Module cache
- Project build folder

### Step 3: Reopen and Rebuild

```bash
open Cafe.xcodeproj
```

In Xcode:
1. **Shift+Cmd+K** - Clean build folder
2. **Cmd+B** - Build

The errors should be gone!

## Why This Happens

Xcode caches compiled Swift modules and intermediate build products. When you:
1. Make changes to Swift files
2. Git pull/merge changes
3. Restructure the project

Xcode sometimes keeps using old cached versions instead of recompiling with the new code.

## Alternative: Manual Clean

If the script doesn't work, do it manually:

```bash
# Quit Xcode first!

# Remove DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Remove caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode/

# Remove module cache
rm -rf ~/Library/Developer/Xcode/UserData/ModuleCache/

# Reopen
open Cafe.xcodeproj
```

## Still Not Working?

If you still see the error after deep clean:

1. **Verify the file content**:
   ```bash
   sed -n '62,66p' Cafe/Features/Auth/LoginView.swift
   ```

   Should show:
   ```swift
   Button(action: {
       Task {
           await appState.login(username: username, password: password)
       }
   }) {
   ```

2. **Check you have latest code**:
   ```bash
   git pull
   git status
   ```

3. **Restart your Mac** (sometimes Xcode daemons get stuck)

4. **Update Xcode** (if you're on an old version)

## Proof the Code is Correct

Check yourself:
```bash
cat Cafe/Features/Auth/LoginView.swift | grep -A 5 "Button(action:"
```

Both Button instances use `Button(action: { ... }) { ... }` syntax, which is correct!

---

**TL;DR**: Quit Xcode, run `./scripts/xcode-deep-clean.sh`, reopen, rebuild.
