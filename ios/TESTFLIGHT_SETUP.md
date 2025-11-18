# TestFlight Setup - Step by Step

Let's get your app on TestFlight! Follow these steps in order.

## Step 1: Add Files to Xcode Project (5 minutes)

The Swift files I created are on your filesystem but not yet in the Xcode project. Let's add them:

### Option A: Drag and Drop (Recommended)

1. **Open Xcode project**:
   ```bash
   open ios/Cafe/Cafe.xcodeproj
   ```

2. **In Finder**, open a new window and navigate to:
   ```
   /Users/scawful/Code/halext-org/ios/Cafe/Cafe/
   ```

3. **Arrange windows** so you can see both Xcode and Finder

4. **Drag these folders** from Finder into Xcode's Project Navigator (left sidebar), into the "Cafe" group:
   - **Core/** folder (contains API, Auth, Models)
   - **Features/** folder (contains Auth and Tasks views)
   - **App/AppState.swift** (into existing App folder)
   - **App/RootView.swift** (into existing App folder)

5. **When the dialog appears**, make sure:
   - ✅ "Copy items if needed" is UNCHECKED (files are already in place)
   - ✅ "Create groups" is selected
   - ✅ "Add to targets: Cafe" is CHECKED
   - Click **Finish**

### Option B: Command Line (Alternative)

I can try to add them programmatically, but drag-and-drop is more reliable.

### Verify Files Were Added

In Xcode Project Navigator, you should see:
```
Cafe
├── App
│   ├── CafeApp.swift
│   ├── AppState.swift ← new
│   └── RootView.swift ← new
├── Core ← new
│   ├── API
│   ├── Auth
│   └── Models
├── Features ← new
│   ├── Auth
│   └── Tasks
├── ContentView.swift
└── Assets.xcassets
```

**When done, type "done" and I'll help with the next step!**

---

## Step 2: Build and Test (Next)

Once files are added, we'll:
1. Build the project (Cmd+B)
2. Fix any errors
3. Test on simulator
4. Prepare for archive

---

## Step 3: App Store Connect Setup (Next)

Create your app in App Store Connect for TestFlight distribution.

---

## Step 4: Archive and Upload (Next)

Archive the app and upload to TestFlight.

---

## Step 5: Add Testers (Final)

Add your partner as a beta tester.

---

**Ready? Start with Step 1 above, then let me know when you're done!**
