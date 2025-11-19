# Package 2: Sharing & Integration Setup Guide

Complete setup guide for implementing sharing and integration features in the Cafe iOS app.

## Table of Contents
1. [Share Extension Setup](#share-extension-setup)
2. [Quick Actions Configuration](#quick-actions-configuration)
3. [URL Schemes & Deep Linking](#url-schemes--deep-linking)
4. [Advanced Shortcuts Integration](#advanced-shortcuts-integration)
5. [Clipboard Monitoring Setup](#clipboard-monitoring-setup)
6. [Testing Guide](#testing-guide)
7. [Troubleshooting](#troubleshooting)

---

## 1. Share Extension Setup

### Step 1.1: Create Share Extension Target

1. Open Xcode and select your project
2. Click **File → New → Target**
3. Choose **iOS → Share Extension**
4. Name it: `CafeShareExtension`
5. Click **Finish**

### Step 1.2: Configure Extension Info.plist

Edit `CafeShareExtension/Info.plist`:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsText</key>
            <true/>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>1</integer>
        </dict>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

### Step 1.3: Configure App Groups

Both **main app** and **share extension** need the same App Group:

1. Select **Cafe** target → **Signing & Capabilities**
2. Click **+ Capability** → **App Groups**
3. Add: `group.org.halext.cafe`
4. Repeat for **CafeShareExtension** target

### Step 1.4: Remove Default Storyboard

The extension uses a custom UIViewController, no storyboard needed:

1. Delete `MainInterface.storyboard` from CafeShareExtension folder
2. Edit `Info.plist` and remove the `NSExtensionMainStoryboard` key
3. Add instead:
```xml
<key>NSExtensionPrincipalClass</key>
<string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
```

### Step 1.5: Replace ShareViewController

Replace the default `ShareViewController.swift` with the provided implementation that includes:
- Custom UI for task creation
- URL/text/image extraction
- App Group data sharing
- URL scheme communication with main app

**File:** `CafeShareExtension/ShareViewController.swift` (already created)

---

## 2. Quick Actions Configuration

### Step 2.1: Add Quick Actions Manager

The Quick Actions manager is already created at:
`Cafe/Core/QuickActions/QuickActionsManager.swift`

### Step 2.2: Initialize in App Delegate

Add to `CafeApp.swift` or your app's initialization:

```swift
import UIKit

@main
struct CafeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Setup Quick Actions
        QuickActionsManager.shared.setupQuickActions()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        handleQuickAction(shortcutItem)
        completionHandler(true)
    }

    @MainActor
    private func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
        guard let result = QuickActionsManager.shared.handleQuickAction(shortcutItem) else {
            return
        }

        // Handle the result in your app state
        switch result {
        case .newTask:
            // Navigate to new task screen
            NotificationCenter.default.post(name: NSNotification.Name("ShowNewTask"), object: nil)
        case .newEvent:
            // Navigate to new event screen
            NotificationCenter.default.post(name: NSNotification.Name("ShowNewEvent"), object: nil)
        case .todaysTasks:
            // Navigate to today's tasks
            NotificationCenter.default.post(name: NSNotification.Name("ShowTodaysTasks"), object: nil)
        case .chat:
            // Navigate to chat
            NotificationCenter.default.post(name: NSNotification.Name("ShowChat"), object: nil)
        }
    }
}
```

### Step 2.3: Dynamic Quick Actions (Optional)

Update quick actions based on app state:

```swift
// In your task list view or app state
QuickActionsManager.shared.updateDynamicQuickActions(taskCount: tasks.count)
```

---

## 3. URL Schemes & Deep Linking

### Step 3.1: Register URL Scheme

Edit **Cafe** target `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>org.halext.cafe</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>cafe</string>
        </array>
    </dict>
</array>
```

### Step 3.2: Handle URLs in App

Update `CafeApp.swift`:

```swift
@main
struct CafeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    @MainActor
    private func handleDeepLink(_ url: URL) {
        if let action = DeepLinkManager.shared.handleDeepLink(url) {
            // Handle the deep link action
            switch action {
            case .newTask(let prefill):
                // Navigate to new task with prefill data
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkNewTask"),
                    object: prefill
                )

            case .viewTask(let id):
                // Navigate to task detail
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkViewTask"),
                    object: id
                )

            case .openChat(let prompt):
                // Open chat with optional prompt
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkChat"),
                    object: prompt
                )

            // ... handle other actions
            default:
                break
            }
        }
    }
}
```

### Step 3.3: Universal Links (Optional)

For production apps, configure Universal Links:

1. Add **Associated Domains** capability
2. Add domain: `applinks:org.halext.org`
3. Host `apple-app-site-association` file on your server
4. Deep link handler works the same way

---

## 4. Advanced Shortcuts Integration

### Step 4.1: Import AppIntents Framework

Already done in `AdvancedShortcuts.swift`

### Step 4.2: Register Shortcuts Provider

Update `CafeApp.swift`:

```swift
import AppIntents

@main
struct CafeApp: App {
    init() {
        // Register shortcuts
        CafeAdvancedShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

### Step 4.3: Test Shortcuts

1. Build and run the app on a real device (Shortcuts don't work in Simulator)
2. Open **Shortcuts** app
3. Create new shortcut
4. Search for "Cafe" - you should see:
   - Search Tasks
   - Complete Task by Name
   - Get Tasks Count
   - Get Next Event
   - Create Multiple Tasks

### Step 4.4: Siri Integration

Users can create Siri voice commands for these shortcuts:
1. Open Shortcuts app
2. Create shortcut using Cafe actions
3. Tap (•••) → Add to Siri
4. Record phrase like "What's next in Cafe"

---

## 5. Clipboard Monitoring Setup

### Step 5.1: Start Monitoring

The clipboard monitor starts automatically if enabled. To control it:

```swift
// In your app initialization or settings
ClipboardMonitor.shared.isMonitoringEnabled = true
```

### Step 5.2: Add Suggestion Banner to UI

Update your main view to show clipboard suggestions:

```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        ZStack {
            // Your main content
            TabView {
                // ... tabs
            }

            // Clipboard suggestion overlay
            VStack {
                ClipboardSuggestionBanner()
                Spacer()
            }
            .allowsHitTesting(true)
        }
    }
}
```

### Step 5.3: Add Settings UI

Add clipboard settings to your Settings view:

```swift
struct SettingsView: View {
    var body: some View {
        List {
            NavigationLink(destination: ClipboardSettingsView()) {
                Label("Clipboard Monitoring", systemImage: "clipboard")
            }
        }
    }
}
```

### Step 5.4: Privacy Considerations

Add to `Info.plist` (for App Store review):

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>org.halext.cafe.clipboard-monitoring</string>
</array>
```

Add privacy explanation in App Store description:
> "Clipboard monitoring is optional and checks your clipboard every 2 seconds to suggest creating tasks. Your clipboard data never leaves your device and is processed locally."

---

## 6. Testing Guide

### Test Share Extension

1. Open Safari and navigate to any website
2. Tap Share button
3. Scroll to find "Cafe" (may need to tap "More" first)
4. Select Cafe
5. Verify the URL is populated
6. Enter task title and tap "Create Task"
7. Open Cafe app - task should appear

### Test Quick Actions

1. Long-press Cafe app icon on home screen
2. Verify you see 4 quick actions:
   - New Task
   - New Event
   - Today's Tasks
   - AI Assistant
3. Tap each to verify navigation

### Test Deep Links

Test in Safari (URL bar) or Notes app:

```
cafe://new-task?title=Test%20Task&description=Test%20description
cafe://task/1
cafe://chat?prompt=Hello
cafe://search?q=meeting
cafe://dashboard
```

### Test Advanced Shortcuts

1. Open Shortcuts app
2. Create shortcut with "Get Tasks Count" action
3. Select status: "Incomplete"
4. Run shortcut
5. Verify you get spoken response with count

### Test Clipboard Monitoring

1. Enable clipboard monitoring in Settings
2. Copy a URL (e.g., from Safari)
3. Return to Cafe app
4. Within 2 seconds, you should see suggestion banner
5. Tap "Create Task" to accept or "Dismiss" to ignore

---

## 7. Troubleshooting

### Share Extension Not Appearing

**Problem:** Cafe doesn't show up in Share menu

**Solutions:**
- Verify Info.plist has correct NSExtensionActivationRule
- Check App Groups are configured for both targets
- Rebuild app (Clean Build Folder: Cmd+Shift+K)
- Reinstall app on device
- Check extension is enabled: Settings → Cafe → More → enable extension

### Quick Actions Not Working

**Problem:** Long-press shows no actions

**Solutions:**
- Verify QuickActionsManager.shared.setupQuickActions() is called in didFinishLaunching
- Check you're testing on a real device (not all features work in Simulator)
- Reinstall app
- Maximum 4 quick actions - verify you haven't exceeded

### Deep Links Not Opening App

**Problem:** cafe:// URLs don't open app

**Solutions:**
- Verify CFBundleURLSchemes in Info.plist
- Check .onOpenURL handler is registered
- Test with URL that definitely exists: `cafe://dashboard`
- For Universal Links, verify apple-app-site-association is valid

### Shortcuts Not Appearing

**Problem:** Can't find Cafe actions in Shortcuts app

**Solutions:**
- Shortcuts only work on real devices (not Simulator)
- Build and run app at least once
- Force-quit Shortcuts app and reopen
- Check AppIntents are properly exported with `static var title`

### Clipboard Monitoring Not Working

**Problem:** No suggestions appear when copying

**Solutions:**
- Verify monitoring is enabled: ClipboardMonitor.shared.isMonitoringEnabled
- Check ClipboardSuggestionBanner is added to view hierarchy
- Test with obvious content (copy a URL)
- Check console for "📋 Detected..." logs
- Verify app is in foreground (monitoring pauses in background)

### Shared Tasks Not Syncing

**Problem:** Tasks created in Share Extension don't appear in main app

**Solutions:**
- Verify both targets use same App Group: `group.org.halext.cafe`
- Check App Group is created in Apple Developer portal
- Call SharedTaskManager.shared.processPendingSharedTasks() when app launches
- Check UserDefaults(suiteName:) is working
- Review console for error messages

---

## Integration Checklist

Use this checklist to ensure all Package 2 features are properly integrated:

### Share Extension
- [ ] Extension target created
- [ ] App Groups configured for both targets
- [ ] Info.plist configured with activation rules
- [ ] ShareViewController.swift added
- [ ] Tested sharing from Safari, Notes, Photos

### Quick Actions
- [ ] QuickActionsManager.swift integrated
- [ ] setupQuickActions() called in app launch
- [ ] SceneDelegate handles quick action taps
- [ ] Tested all 4 quick actions on device

### Deep Linking
- [ ] URL scheme registered in Info.plist
- [ ] DeepLinkManager.swift integrated
- [ ] .onOpenURL handler added to app
- [ ] Tested multiple deep link formats
- [ ] Navigation logic implemented for all actions

### Advanced Shortcuts
- [ ] AdvancedShortcuts.swift integrated
- [ ] AppShortcutsProvider registered
- [ ] Tested on real device in Shortcuts app
- [ ] Siri integration tested (optional)

### Clipboard Monitoring
- [ ] ClipboardMonitor.swift integrated
- [ ] ClipboardSuggestionBanner added to UI
- [ ] Settings UI added (ClipboardSettingsView)
- [ ] Tested with URLs, text, and images
- [ ] Privacy documentation added

### Shared Task Manager
- [ ] SharedTaskManager.swift integrated
- [ ] processPendingSharedTasks() called on app launch
- [ ] Handles both online and offline creation
- [ ] Widget updates triggered after task creation
- [ ] Notifications shown for created tasks

---

## Example Use Cases

### 1. Share from Safari
User is reading an article and wants to remember it:
1. Tap Share → Cafe
2. Cafe suggests article title
3. User adds notes in description
4. Tap "Create Task"
5. Task appears in Cafe with URL in description

### 2. Quick Action from Home Screen
User needs to quickly add a task:
1. Long-press Cafe icon
2. Tap "New Task"
3. App opens directly to new task form
4. Add task details and save

### 3. Siri Shortcut
User wants to know task count:
1. "Hey Siri, how many tasks in Cafe?"
2. Siri responds: "You have 12 incomplete tasks"

### 4. Clipboard Smart Suggestion
User copies meeting notes:
1. Copy text: "Team meeting Friday 2pm - discuss Q4 goals"
2. Open Cafe app
3. Banner appears: "Create task from clipboard?"
4. Tap "Create Task"
5. Task created with meeting details

### 5. Deep Link from Another App
Task management tool wants to integrate with Cafe:
1. User taps "Add to Cafe" in other app
2. Opens: `cafe://new-task?title=Follow%20up&due=2024-01-15T14:00:00Z`
3. Cafe opens with pre-filled task form
4. User saves task

---

## Performance Considerations

### Battery Impact
- Clipboard monitoring: **Low** (checks every 2 seconds when enabled)
- Share extension: **None** (only active when sharing)
- Quick actions: **None** (static definitions)
- Deep linking: **None** (event-driven)
- Shortcuts: **Low** (only when user invokes)

### Storage Impact
- Share extension: **<1 MB**
- Shared data (App Groups): **~10 KB per task**
- Quick actions: **None** (no persistent storage)

### Network Impact
- All features work offline with local storage
- Online: Tasks sync when network available
- No background network activity

---

## Next Steps

After completing Package 2, proceed to **Package 4: Apple Ecosystem**:
- Apple Watch companion app
- iCloud CloudKit sync
- Mac Catalyst version
- Continuity Camera integration

See `APPLE_ECOSYSTEM_SETUP.md` for details (coming soon).
