# Quick Setup - Add Offline Support Files

## ⚡ 5-Minute Setup

### Step 1: Open Xcode Project
```bash
cd /Users/scawful/Code/halext-org/ios
open Cafe.xcodeproj
```

### Step 2: Add Files (Do This Once)

**In Xcode Project Navigator (left sidebar):**

1. **Create "Storage" group:**
   - Right-click `Cafe/Core` folder
   - New Group → name: `Storage`
   - Right-click `Storage` → "Add Files to Cafe..."
   - Navigate to: `Cafe/Core/Storage/`
   - Select BOTH files:
     - ☑️ `SwiftDataModels.swift`
     - ☑️ `StorageManager.swift`
   - ⚠️ **UNCHECK** "Copy items if needed"
   - ✅ **CHECK** "Add to targets: Cafe"
   - Click "Add"

2. **Create "Network" group:**
   - Right-click `Cafe/Core`
   - New Group → name: `Network`
   - Right-click `Network` → "Add Files to Cafe..."
   - Navigate to: `Cafe/Core/Network/`
   - Select: `NetworkMonitor.swift`
   - Add to Cafe target
   - Click "Add"

3. **Create "Sync" group:**
   - Right-click `Cafe/Core`
   - New Group → name: `Sync`
   - Right-click `Sync` → "Add Files to Cafe..."
   - Navigate to: `Cafe/Core/Sync/`
   - Select: `SyncManager.swift`
   - Add to Cafe target
   - Click "Add"

### Step 3: Build & Run
```
Press Cmd+B to build
Press Cmd+R to run
```

### Step 4: Test Offline Mode
```
1. Run app on simulator
2. Open Settings app on simulator
3. Enable Airplane Mode
4. Switch back to Cafe app
5. See "Offline" indicator
6. Create a task → works!
7. Disable Airplane Mode
8. Watch automatic sync
```

---

## 🎯 Visual Reference

**Your Project Navigator should look like this:**

```
Cafe/
├── App/
├── Core/
│   ├── API/
│   ├── Auth/
│   ├── Models/
│   ├── Theme/
│   ├── Notifications/
│   ├── Intents/
│   ├── Search/
│   ├── Utilities/
│   ├── Storage/           ← NEW
│   │   ├── SwiftDataModels.swift
│   │   └── StorageManager.swift
│   ├── Network/           ← NEW
│   │   └── NetworkMonitor.swift
│   └── Sync/              ← NEW
│       └── SyncManager.swift
├── Features/
└── Assets.xcassets
```

---

## ✅ Verification

After adding files, you should see:

- [x] 4 new files in Project Navigator
- [x] Files have blue icon (in target)
- [x] Build succeeds (Cmd+B)
- [x] No "Cannot find type" errors

---

## 🆘 Common Issues

**"Cannot find type 'StorageManager'"**
- Files not added to target
- Solution: Select file → File Inspector → check "Cafe" target

**"Missing files in navigator"**
- Need to add them manually
- Use "Add Files to Cafe..." option

**"Build failed after adding"**
- Make sure all 4 files added
- Clean build folder: Product → Clean Build Folder
- Rebuild: Cmd+B

---

## 📚 More Info

See `OFFLINE_MODE_GUIDE.md` for:
- Complete testing guide
- How offline mode works
- Troubleshooting tips
- Architecture details
