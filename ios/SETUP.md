# Cafe iOS App - Developer Setup Guide

Quick start guide for developers working on the Cafe iOS app.

---

## 📋 Requirements

### Development Environment
- **Xcode**: 15.0 or later
- **macOS**: Ventura (13.0) or later
- **iOS Target**: 17.0+
- **Swift**: 5.9+

### Accounts
- Apple Developer account (for device testing and app-specific features)
- Access to backend API (development and production endpoints)

---

## 🚀 Quick Start

### 1. Clone and Open

```bash
cd /path/to/halext-org
open ios/Cafe.xcodeproj
```

### 2. Configure Signing

1. Select **Cafe** target
2. Go to **Signing & Capabilities**
3. Select your **Team**
4. Xcode will automatically manage provisioning

### 3. Update API Endpoints (if needed)

**File**: `Core/API/APIClient.swift`

```swift
enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "http://127.0.0.1:8000"  // Change if needed
        case .production:
            return "https://org.halext.org/api"  // Your production URL
        }
    }
}
```

### 4. Build and Run

```bash
# Select simulator or device
# Press Cmd+R or click ▶️ Play button
```

---

## 🏗️ Project Structure

```
ios/Cafe/
├── App/
│   ├── CafeApp.swift              # App entry point
│   ├── AppState.swift             # Global observable state
│   └── RootView.swift             # Root navigation + Settings
│
├── Core/
│   ├── API/
│   │   └── APIClient.swift        # Networking layer
│   ├── Auth/
│   │   ├── KeychainManager.swift  # Secure storage
│   │   └── BiometricAuthManager.swift
│   ├── Models/
│   │   ├── Models.swift           # Data models
│   │   └── AiChatMessage.swift
│   ├── Theme/
│   │   └── ThemeManager.swift
│   ├── Notifications/
│   │   └── NotificationManager.swift
│   ├── Intents/
│   │   └── AppIntents.swift       # Siri shortcuts
│   ├── Search/
│   │   └── SpotlightManager.swift
│   └── Utilities/
│       ├── HapticManager.swift
│       └── ColorExtensions.swift
│
├── Features/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   ├── RegisterView.swift
│   │   └── BiometricAuthView.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── DashboardViewModel.swift
│   ├── Tasks/
│   │   ├── TaskListView.swift
│   │   └── NewTaskView.swift
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   ├── CalendarViewModel.swift
│   │   └── NewEventView.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   └── ChatViewModel.swift
│   └── Settings/
│       └── ThemeSwitcherView.swift
│
├── Assets.xcassets
└── Cafe.entitlements
```

---

## 🔑 Configuration Files

### 1. Entitlements (`Cafe.entitlements`)

Current capabilities:
```xml
- Keychain Access Groups
```

To add (as needed):
```xml
- Push Notifications (aps-environment)
- App Groups (for widgets)
- Associated Domains (for universal links)
```

### 2. Info.plist Additions

**Required for Face ID** (add manually):
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely lock your app and protect your data</string>
```

---

## 🧪 Testing

### Simulator Testing

```bash
# Run specific simulator
xcrun simctl list devices

# Run on iPhone 15
xcodebuild -scheme Cafe \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

### Device Testing

1. Connect iPhone/iPad via USB
2. Select device in Xcode
3. Click Run (Cmd+R)
4. Trust developer certificate on device if prompted

### Features Requiring Real Device

- ✅ Face ID / Touch ID
- ✅ Push Notifications (with backend)
- ✅ Haptic Feedback
- ⚠️ Siri Shortcuts (works on simulator but better on device)

---

## 🐛 Debugging

### Common Issues

#### 1. **Build Fails: "Module not found"**
**Solution**: Clean build folder
```bash
# In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
# Or via CLI:
xcodebuild clean
```

#### 2. **Face ID Not Available**
**Cause**: Simulator doesn't have Face ID enrolled
**Solution**:
- Simulator: Features → Face ID → Enrolled
- Device: Settings → Face ID & Passcode

#### 3. **Network Requests Fail**
**Check**:
- Backend is running (for development)
- API endpoint is correct
- iPhone allows local network (Settings → Privacy)
- For localhost on device, use your Mac's IP address

#### 4. **"Task"/"Decoder" Conflicts**
**Solution**: Already fixed with `_Concurrency.Task` throughout codebase

### Debug Logging

Look for these emoji prefixes in console:
- 🔐 Authentication
- 📱 App State
- 🌍 Environment
- ✅ Success
- ❌ Error
- 📡 Network
- 🔒 Biometric
- 📲 Notifications
- 🗑️ Cleanup

---

## 🎨 Development Tips

### SwiftUI Previews

Most views have previews - use canvas (Cmd+Opt+Enter):

```swift
#Preview {
    DashboardView()
        .environment(AppState())
}
```

### State Management

All views use `@Observable` (iOS 17+):

```swift
@State private var viewModel = DashboardViewModel()
@Environment(AppState.self) var appState
```

### API Calls

All networking is async/await:

```swift
do {
    let tasks = try await APIClient.shared.getTasks()
    // Handle success
} catch {
    // Handle error
}
```

### Haptic Feedback

```swift
// On success
HapticManager.success()

// On delete
HapticManager.mediumImpact()

// Selection
HapticManager.selection()
```

---

## 📦 Dependencies

### No External Packages! 🎉

This project uses **zero external dependencies**:
- ✅ Pure SwiftUI
- ✅ Native URLSession
- ✅ Native Keychain
- ✅ Native Notifications
- ✅ Native Local Authentication

**Benefits:**
- Faster builds
- No dependency conflicts
- Smaller app size
- Better security
- Easier maintenance

---

## 🚢 Deployment

### TestFlight

1. Archive build (Product → Archive)
2. Upload to App Store Connect
3. Submit for TestFlight review
4. Invite internal/external testers

### App Store

1. Complete App Store Connect listing
2. Add screenshots (required sizes)
3. Submit for review
4. Wait for approval (typically 1-3 days)

### Required Assets

- [ ] App Icon (all sizes in Assets.xcassets)
- [ ] Screenshots (6.7", 6.5", 5.5" displays)
- [ ] Privacy policy URL
- [ ] App description
- [ ] Keywords
- [ ] Support URL

---

## 🔐 Security Checklist

- [x] API tokens stored in Keychain
- [x] HTTPS for all network requests
- [x] No hardcoded credentials
- [x] Biometric authentication option
- [x] Session management with auto-logout
- [x] Secure input sanitization (pending)
- [ ] Certificate pinning (optional)
- [ ] Jailbreak detection (optional)

---

## 🎯 Performance Optimization

### Current Optimizations

- ✅ Lazy loading in lists
- ✅ Image caching (system default)
- ✅ Async/await for smooth UI
- ✅ Efficient state updates
- ✅ Pull-to-refresh instead of auto-refresh

### Monitoring

Use Xcode Instruments:
```bash
# Profile with Instruments
# Product → Profile (Cmd+I)

# Check:
- Time Profiler (CPU usage)
- Allocations (Memory usage)
- Leaks (Memory leaks)
- Network (API calls)
```

---

## 📝 Code Style

### SwiftUI Best Practices

```swift
// ✅ Good
struct MyView: View {
    @State private var isLoading = false

    var body: some View {
        // ...
    }

    private func loadData() async {
        // ...
    }
}

// ❌ Avoid
struct MyView: View {
    @State var isLoading: Bool = false  // Use private, type inference

    var body: some View {
        // Complex logic here - extract to computed properties/functions
    }
}
```

### Naming Conventions

- **Views**: `SomeView`
- **ViewModels**: `SomeViewModel`
- **Managers**: `SomeManager`
- **Extensions**: `TypeName+Extension`

### File Organization

- Group by feature, not type
- One view per file
- Keep files under 300 lines
- Extract reusable components

---

## 🧩 Adding New Features

### 1. Create View

```swift
// Features/NewFeature/NewFeatureView.swift
struct NewFeatureView: View {
    @State private var viewModel = NewFeatureViewModel()

    var body: some View {
        // UI
    }
}
```

### 2. Create ViewModel (if needed)

```swift
@Observable
class NewFeatureViewModel {
    var items: [Item] = []
    var isLoading = false

    @MainActor
    func loadItems() async {
        // Load data
    }
}
```

### 3. Add to Navigation

Update `RootView.swift` if adding new tab:

```swift
.tabItem {
    Label("New Feature", systemImage: "icon.name")
}
```

### 4. Add Tests (future)

```swift
@testable import Cafe
import XCTest

final class NewFeatureTests: XCTestCase {
    func testLoadItems() async {
        // Test logic
    }
}
```

---

## 📚 Resources

### Apple Documentation
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [Async/Await](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [App Intents](https://developer.apple.com/documentation/appintents)
- [WidgetKit](https://developer.apple.com/documentation/widgetkit)

### Project Docs
- `FEATURES.md` - Complete feature list
- `WIDGET_GUIDE.md` - Widget implementation
- `README.md` - Project overview (if exists)

---

## 💬 Getting Help

### Issues?

1. Check console for error logs
2. Clean build folder
3. Restart Xcode
4. Check GitHub issues
5. Ask in team chat

### Contributing

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit PR with description
5. Wait for review

---

## ✅ Pre-commit Checklist

- [ ] Code builds without errors
- [ ] No SwiftLint warnings (if added)
- [ ] Tested on simulator
- [ ] Tested on device (for device-specific features)
- [ ] No console errors/warnings
- [ ] Code formatted consistently
- [ ] Updated documentation if needed

---

**Happy Coding! 🚀**

Last Updated: November 2025
