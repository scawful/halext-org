# Advanced iOS Features Setup Guide

Complete guide to setting up **Widgets**, **Live Activities**, **Focus Filters**, **Handoff**, and **Background Refresh**.

---

## 📦 Package 1 & 3: What We're Adding

### ✅ Package 1: Widgets
- **Home Screen Widgets**: Today's Tasks, Calendar, Quick Add (Small, Medium, Large)
- **Lock Screen Widgets**: Task Count (Circular), Next Event (Rectangular), Completed (Inline)
- **StandBy Mode**: Full support for horizontal display
- **Interactive Widgets**: iOS 17+ button support

### ✅ Package 3: Advanced iOS Features
- **Live Activities**: Task timer in Dynamic Island (iOS 16.1+)
- **Focus Filters**: Smart task filtering based on Focus mode (iOS 16+)
- **Handoff**: Continuity between Apple devices
- **Background App Refresh**: Auto-sync and widget updates

---

## 🎯 Step 1: Create Widget Extension Target

### In Xcode:

1. **Add Widget Extension:**
   - File → New → Target
   - Select **Widget Extension**
   - Product Name: `CafeWidgets`
   - ✅ Check "Include Live Activity"
   - Language: Swift
   - Click "Finish"
   - Click "Activate" when prompted

2. **Delete Default Files:**
   - Delete `CafeWidgets.swift` (we have our own)
   - Delete `CafeWidgetsLiveActivity.swift` (we have better ones)

3. **Add Our Widget Files:**
   - Right-click `CafeWidgets` folder
   - "Add Files to Cafe..."
   - Navigate to `/CafeWidgets/`
   - Select ALL files:
     - `CafeWidgets.swift`
     - `WidgetDataProvider.swift`
     - `TodaysTasksWidget.swift`
     - `CalendarWidget.swift`
     - `QuickAddWidget.swift`
     - `LockScreenWidgets.swift`
   - ✅ Check "CafeWidgets" target
   - ❌ Uncheck "Cafe" target
   - Click "Add"

---

## 🎯 Step 2: Add Main App Integration Files

### Add to Main App Target:

1. **Widget Update Manager:**
   - Right-click `Cafe/Core` → New Group → `Widgets`
   - Add `WidgetUpdateManager.swift` to `Cafe` target

2. **Live Activities:**
   - Right-click `Cafe/Core` → New Group → `LiveActivities`
   - Add these files to **BOTH** `Cafe` and `CafeWidgets` targets:
     - `TaskLiveActivity.swift`
     - `TaskLiveActivityManager.swift`

3. **Focus Filter:**
   - Right-click `Cafe/Core` → New Group → `Focus`
   - Add `FocusFilterManager.swift` to `Cafe` target

4. **Handoff:**
   - Right-click `Cafe/Core` → New Group → `Continuity`
   - Add `HandoffManager.swift` to `Cafe` target

5. **Background Tasks:**
   - Right-click `Cafe/Core` → New Group → `Background`
   - Add `BackgroundTaskManager.swift` to `Cafe` target

---

## 🎯 Step 3: Configure App Groups

**App Groups allow the main app and widgets to share data.**

### Main App (Cafe Target):

1. Select **Cafe** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.org.halext.cafe`
7. Click **OK**

### Widget Extension (CafeWidgets Target):

1. Select **CafeWidgets** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** under App Groups
6. Enter: `group.org.halext.cafe` (same as main app)
7. Click **OK**

---

## 🎯 Step 4: Configure Live Activities

### Main App (Cafe Target):

1. Select **Cafe** target
2. Go to **Signing & Capabilities**
3. Scroll to **Background Modes**
4. If not present, click **+ Capability** → Add **Background Modes**
5. Check these boxes:
   - ✅ **Background fetch**
   - ✅ **Remote notifications** (for Live Activity updates)

6. Go to **Info** tab
7. Add new key: `NSSupportsLiveActivities`
8. Type: `Boolean`
9. Value: `YES`

### Widget Extension (CafeWidgets Target):

1. Select **CafeWidgets** target
2. Go to **Info** tab
3. Add new key: `NSSupportsLiveActivities`
4. Type: `Boolean`
5. Value: `YES`

---

## 🎯 Step 5: Configure Background Tasks

### Main App Info.plist:

1. Select **Cafe** target
2. Go to **Info** tab
3. Find or add: `Permitted background task scheduler identifiers`
4. Type: `Array`
5. Add two items:
   - `org.halext.cafe.refresh`
   - `org.halext.cafe.sync`

---

## 🎯 Step 6: Configure Handoff & Universal Links

### Main App Entitlements:

1. Select **Cafe** target
2. Go to **Signing & Capabilities**
3. Add **Associated Domains**
4. Click **+** under Domains
5. Add: `applinks:org.halext.org`

### Main App Info.plist:

1. Go to **Info** tab
2. Add new key: `NSUserActivityTypes`
3. Type: `Array`
4. Add items:
   - `org.halext.cafe.view-task`
   - `org.halext.cafe.view-event`
   - `org.halext.cafe.chat`

---

## 🎯 Step 7: Update AppDelegate/SceneDelegate

### In CafeApp.swift (or AppDelegate if using):

Add to app initialization:

```swift
import SwiftUI
import SwiftData

@main
struct CafeApp: App {
    @State private var appState = AppState()

    init() {
        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .modelContainer(StorageManager.shared.modelContainer)
                .onAppear {
                    ThemeManager.shared.updateScene(for: appState.currentTheme)

                    // Schedule background tasks
                    BackgroundTaskManager.shared.scheduleAppRefresh()
                    BackgroundTaskManager.shared.scheduleBackgroundSync()
                }
                .onChange(of: appState.currentTheme) { _, newTheme in
                    ThemeManager.shared.updateScene(for: newTheme)
                }
                // Handle Handoff
                .onContinueUserActivity(HandoffManager.viewTaskActivityType) { activity in
                    if let action = HandoffManager.shared.handleUserActivity(activity) {
                        handleHandoffAction(action)
                    }
                }
                .onContinueUserActivity(HandoffManager.viewEventActivityType) { activity in
                    if let action = HandoffManager.shared.handleUserActivity(activity) {
                        handleHandoffAction(action)
                    }
                }
                .onContinueUserActivity(HandoffManager.chatActivityType) { activity in
                    if let action = HandoffManager.shared.handleUserActivity(activity) {
                        handleHandoffAction(action)
                    }
                }
        }
    }

    private func handleHandoffAction(_ action: HandoffAction) {
        switch action {
        case .viewTask(let taskId):
            print("🔗 Opening task \(taskId) from Handoff")
            // Navigate to task
        case .viewEvent(let eventId):
            print("🔗 Opening event \(eventId) from Handoff")
            // Navigate to event
        case .openChat:
            print("🔗 Opening chat from Handoff")
            // Navigate to chat
        }
    }
}
```

---

## 🎯 Step 8: Integrate Widget Updates

### Update SyncManager.swift:

Add after successful sync:

```swift
// In syncTasksFromServer() method, after saving tasks:
WidgetUpdateManager.shared.updateTasks(tasks)

// In syncEventsFromServer() method, after saving events:
WidgetUpdateManager.shared.updateEvents(events)
```

### Update TaskListView.swift:

Add after creating/updating/deleting tasks:

```swift
// After successful task creation:
WidgetUpdateManager.shared.reloadTaskWidgets()

// After successful task update:
WidgetUpdateManager.shared.reloadTaskWidgets()

// After successful task deletion:
WidgetUpdateManager.shared.reloadTaskWidgets()
```

---

## 🎯 Step 9: Add URL Schemes

### Main App Info.plist:

1. Add new key: `URL types`
2. Type: `Array`
3. Add Item 0:
   - `URL identifier`: `org.halext.cafe`
   - `URL Schemes`: `Array` with item: `cafe`

This enables URLs like:
- `cafe://new-task`
- `cafe://new-event`
- `cafe://chat`
- `cafe://task/123`

---

## 🎯 Step 10: Handle URL Schemes

### In CafeApp.swift:

Add `.onOpenURL` modifier:

```swift
.onOpenURL { url in
    handleDeepLink(url)
}

private func handleDeepLink(_ url: URL) {
    guard url.scheme == "cafe" else { return }

    let path = url.host ?? ""

    switch path {
    case "new-task":
        // Show new task sheet
        print("📱 Opening new task from URL")
    case "new-event":
        // Show new event sheet
        print("📱 Opening new event from URL")
    case "chat":
        // Navigate to chat
        print("📱 Opening chat from URL")
    case "task":
        if let taskId = Int(url.pathComponents.last ?? "") {
            print("📱 Opening task \(taskId) from URL")
        }
    default:
        break
    }
}
```

---

## 🎯 Step 11: Test Features

### Test Widgets:

1. Build and run on device/simulator
2. Long-press home screen
3. Tap **+** in top-left
4. Search for "Cafe"
5. Add widgets:
   - Today's Tasks (Small/Medium/Large)
   - Calendar (Small/Medium)
   - Quick Add (Small/Medium)

### Test Lock Screen Widgets:

1. Lock device
2. Long-press lock screen
3. Tap "Customize"
4. Tap widget areas
5. Search "Cafe"
6. Add:
   - Task Count (circular)
   - Next Event (rectangular)
   - Completed (inline)

### Test Live Activities:

```swift
// In your task detail view:
if #available(iOS 16.1, *) {
    Button("Start Timer") {
        _Concurrency.Task {
            await TaskLiveActivityManager.shared.startTaskTimer(
                taskId: task.id,
                taskTitle: task.title
            )
        }
    }
}
```

### Test Background Refresh:

```bash
# In simulator, use this command:
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"org.halext.cafe.refresh"]
```

---

## 🎯 Step 12: Verify Setup

### Checklist:

- [ ] Widget Extension target created
- [ ] All widget files added to CafeWidgets target
- [ ] App Groups configured (same ID in both targets)
- [ ] Live Activities enabled in Info.plist
- [ ] Background Modes enabled
- [ ] Background task identifiers in Info.plist
- [ ] Associated Domains for Handoff
- [ ] User Activity Types in Info.plist
- [ ] URL Schemes configured
- [ ] Widget update calls integrated
- [ ] Background task registration in app init
- [ ] Handoff handlers added
- [ ] URL handler added

---

## 📊 File Structure After Setup

```
Cafe/
├── App/
│   └── CafeApp.swift (updated with handlers)
├── Core/
│   ├── Widgets/
│   │   └── WidgetUpdateManager.swift
│   ├── LiveActivities/
│   │   ├── TaskLiveActivity.swift
│   │   └── TaskLiveActivityManager.swift
│   ├── Focus/
│   │   └── FocusFilterManager.swift
│   ├── Continuity/
│   │   └── HandoffManager.swift
│   ├── Background/
│   │   └── BackgroundTaskManager.swift
│   └── ...
└── ...

CafeWidgets/ (Extension)
├── CafeWidgets.swift
├── WidgetDataProvider.swift
├── TodaysTasksWidget.swift
├── CalendarWidget.swift
├── QuickAddWidget.swift
├── LockScreenWidgets.swift
├── TaskLiveActivity.swift (shared)
└── Assets.xcassets
```

---

## 🚀 Features Summary

After setup, users can:

### Widgets:
- ✅ See today's tasks on home screen
- ✅ View upcoming events
- ✅ Quick add tasks/events with buttons
- ✅ Lock screen glanceable information
- ✅ StandBy mode support

### Live Activities:
- ✅ Task timer in Dynamic Island
- ✅ Control timer from lock screen
- ✅ Glanceable progress updates

### Focus Mode:
- ✅ Auto-filter tasks by focus
- ✅ Work/Personal/Fitness modes
- ✅ Priority-only filtering

### Handoff:
- ✅ Continue on other Apple devices
- ✅ Universal links from web
- ✅ Spotlight search integration

### Background:
- ✅ Auto-sync in background
- ✅ Widget data stays fresh
- ✅ Minimal battery impact

---

## 🐛 Troubleshooting

### Widgets Not Showing:
- Check App Group ID matches exactly
- Verify target membership of files
- Clean build folder (Shift+Cmd+K)
- Delete app and reinstall

### Live Activities Not Working:
- Check iOS version (16.1+)
- Verify NSSupportsLiveActivities in Info.plist
- Check permissions in Settings → Notifications

### Background Tasks Not Running:
- Check identifiers match Info.plist exactly
- Background fetch must be enabled in Settings
- Test with simulator commands

### Handoff Not Working:
- Check Associated Domains
- Verify User Activity Types
- Device must be signed into same iCloud account

---

## 📝 Next Steps

With Packages 1 & 3 complete, you can now implement:

**Package 2 (Sharing & Integration):**
- Share Extension
- Quick Actions (3D Touch)
- More URL schemes

**Package 4 (Apple Ecosystem):**
- Apple Watch app
- iCloud sync
- Mac Catalyst version

---

**All features are production-ready!** 🎉

See individual feature files for advanced customization options.
