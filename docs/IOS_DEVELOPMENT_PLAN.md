# Halext Org iOS App - Development Plan

## Overview

This document outlines the complete plan for developing the Halext Org iOS application, including architecture, development workflow, deployment strategy, and timeline.

## 1. iOS App Architecture

### Tech Stack

**Core Framework**: SwiftUI + Swift 6
- Modern, declarative UI framework
- Native performance
- Excellent integration with iOS features
- Type-safe and compile-time checked

**Data Layer**:
- **SwiftData** (iOS 17+): Local persistence with CloudKit sync
- **URLSession**: API communication with backend
- **Combine**: Reactive data flow
- **AsyncAwait**: Modern concurrency

**Authentication**:
- **Keychain**: Secure token storage
- **OAuth2**: JWT token-based auth matching backend

**Additional Libraries**:
- **swift-composable-architecture** (TCA): State management (optional but recommended)
- **Alamofire**: Networking (alternative to URLSession)
- **Kingfisher**: Image loading and caching

### App Structure

```
HalextOrg/
├── App/
│   ├── HalextOrgApp.swift        # Main app entry point
│   └── AppDelegate.swift         # App lifecycle
├── Core/
│   ├── API/
│   │   ├── APIClient.swift       # Main API client
│   │   ├── APIEndpoints.swift    # Endpoint definitions
│   │   └── APIModels.swift       # Request/response models
│   ├── Auth/
│   │   ├── AuthManager.swift     # Authentication logic
│   │   └── KeychainManager.swift # Secure storage
│   ├── Storage/
│   │   ├── DataController.swift  # SwiftData controller
│   │   └── Models/               # SwiftData models
│   └── Sync/
│       └── SyncEngine.swift      # Sync coordinator
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   ├── DashboardViewModel.swift
│   │   └── Components/
│   ├── Tasks/
│   │   ├── TaskListView.swift
│   │   ├── TaskDetailView.swift
│   │   ├── TaskFormView.swift
│   │   └── TaskViewModel.swift
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   └── EventViewModel.swift
│   ├── AIChat/
│   │   ├── ChatView.swift
│   │   ├── ChatViewModel.swift
│   │   └── MessageBubbleView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Shared/
│   ├── Components/          # Reusable UI components
│   ├── Extensions/          # Swift extensions
│   ├── Utilities/          # Helper functions
│   └── Styles/             # SwiftUI styles
└── Resources/
    ├── Assets.xcassets     # Images, colors
    └── Info.plist         # App configuration
```

### Key Architectural Patterns

**MVVM (Model-View-ViewModel)**:
- **Model**: SwiftData models + API response models
- **View**: SwiftUI views
- **ViewModel**: Business logic, @Observable classes

**Repository Pattern**:
- TaskRepository
- EventRepository
- PageRepository
- Abstracts data source (local vs remote)

**Dependency Injection**:
- Use environment objects
- Protocol-based dependencies for testing

## 2. Development Workflow

### Prerequisites

1. **Hardware**: Mac with Apple Silicon or Intel processor
2. **Software**:
   - Xcode 15.0+ (latest version recommended)
   - macOS Sonoma 14.0+
   - iOS 17.0+ SDK
3. **Apple Developer Account**:
   - Personal or Team account ($99/year)
   - Required for TestFlight and App Store

### Initial Setup

```bash
# 1. Create new Xcode project
# File > New > Project > iOS App
# Name: HalextOrg
# Interface: SwiftUI
# Language: Swift
# Include Tests: Yes

# 2. Configure project
cd /path/to/HalextOrg

# 3. Add Swift Package Manager dependencies
# In Xcode: File > Add Package Dependencies
# - https://github.com/Alamofire/Alamofire (optional)
# - https://github.com/pointfreeco/swift-composable-architecture (optional)

# 4. Set up Git
git init
git remote add origin https://github.com/scawful/halext-org-ios.git
git add .
git commit -m "Initial iOS project setup"
git push -u origin main
```

### Development Environment Setup

**Info.plist Configuration**:
```xml
<key>API_BASE_URL_DEV</key>
<string>http://127.0.0.1:8000</string>
<key>API_BASE_URL_PROD</key>
<string>https://org.halext.org/api</string>
```

**Build Configurations**:
- **Debug**: Local development, http://127.0.0.1:8000
- **Release**: Production, https://org.halext.org/api

### Daily Development Workflow

```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/task-list-view

# 3. Open in Xcode
open HalextOrg.xcodeproj

# 4. Develop feature
# - Write SwiftUI views
# - Implement ViewModels
# - Add unit tests
# - Test on simulator

# 5. Test on physical device
# - Connect iPhone
# - Select device in Xcode
# - Run (Cmd+R)

# 6. Commit changes
git add .
git commit -m "Add task list view with filtering"
git push origin feature/task-list-view

# 7. Create pull request on GitHub
```

### Code Quality

**SwiftLint** for code style:
```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
line_length: 120
excluded:
  - Pods
  - Build
```

**Unit Tests**:
- Test ViewModels
- Test API client
- Test data repositories
- Minimum 70% code coverage

**UI Tests**:
- Critical user flows
- Authentication
- Task creation
- Event management

## 3. Deployment Strategy

### Option 1: TestFlight (Recommended for Testing)

**Advantages**:
- Easy distribution to testers (up to 10,000)
- Automatic updates
- Crash reports and feedback
- No need for device UDIDs

**Setup Process**:

1. **App Store Connect Setup**:
   ```
   - Go to appstoreconnect.apple.com
   - Create new app:
     - Name: Halext Org
     - Bundle ID: org.halext.app
     - Language: English
     - Platform: iOS
   ```

2. **Xcode Archive**:
   ```
   - Select "Any iOS Device"
   - Product > Archive
   - Wait for archive to complete
   - Click "Distribute App"
   - Select "TestFlight & App Store"
   - Follow prompts
   ```

3. **TestFlight Distribution**:
   ```
   - In App Store Connect:
     - Go to TestFlight tab
     - Add internal testers (you and partner)
     - Enter email addresses
   - Testers receive invitation email
   - Install TestFlight app
   - Accept invitation
   - Install Halext Org
   ```

**Automated with GitHub Actions**:
```yaml
# .github/workflows/testflight.yml
name: Deploy to TestFlight
on:
  push:
    tags:
      - 'v*'
jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and upload to TestFlight
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_API_KEY }}
        run: |
          xcodebuild archive -scheme HalextOrg
          xcodebuild -exportArchive
          xcrun altool --upload-app
```

### Option 2: Direct Installation (Development Builds)

**For Development/Testing Without TestFlight**:

1. **Connect iPhone via USB**
2. **Xcode Setup**:
   ```
   - Open project in Xcode
   - Select your iPhone in device list
   - Ensure Apple ID is signed in (Xcode > Settings > Accounts)
   - Select team in project settings
   ```

3. **Trust Developer Certificate**:
   ```
   - On iPhone: Settings > General > VPN & Device Management
   - Trust your Apple ID certificate
   ```

4. **Run App**:
   ```
   - Click Play button (Cmd+R)
   - App installs and launches on device
   - Lasts 7 days before re-signing needed
   ```

**Pros**: Instant deployment, no review
**Cons**: 7-day expiration, requires physical connection

### Option 3: Ad Hoc Distribution

**For Specific Devices Without TestFlight**:

1. **Register Device UDIDs**:
   ```
   - Connect device to Mac
   - Open Xcode > Window > Devices and Simulators
   - Copy UDID
   - Add to developer.apple.com > Devices
   ```

2. **Create Ad Hoc Provisioning Profile**:
   ```
   - developer.apple.com > Certificates, IDs & Profiles
   - Create new provisioning profile
   - Select "Ad Hoc"
   - Select app ID
   - Select devices
   - Download and double-click
   ```

3. **Export IPA**:
   ```
   - Xcode > Product > Archive
   - Distribute App > Ad Hoc
   - Select provisioning profile
   - Export IPA file
   ```

4. **Install via Xcode or Third-party Tools**:
   ```
   # Using Xcode
   - Window > Devices and Simulators
   - Drag IPA to device

   # Using AltStore (easier for non-developers)
   - Install AltStore on device
   - Open AltStore
   - Install IPA
   ```

### Recommended Deployment Flow

**For You and Your Partner**:

```
Development Phase:
├─ Use Direct Installation (Option 2)
├─ Quick iteration
└─ No upload delays

Beta Testing Phase:
├─ Use TestFlight (Option 1)
├─ Invite 2-10 friends/family
└─ Gather feedback

Production Phase:
├─ Submit to App Store
└─ Public release
```

## 4. API Integration

### API Client Implementation

```swift
// Core/API/APIClient.swift
import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL: String = {
        #if DEBUG
        return "http://127.0.0.1:8000"
        #else
        return "https://org.halext.org/api"
        #endif
    }()

    private var authToken: String? {
        get { KeychainManager.shared.getToken() }
        set { if let token = newValue {
            KeychainManager.shared.saveToken(token)
        }}
    }

    // MARK: - Authentication
    func login(username: String, password: String) async throws -> AuthResponse {
        let endpoint = "/token"
        let body = [
            "username": username,
            "password": password
        ]

        let response: AuthResponse = try await post(endpoint, body: body)
        self.authToken = response.accessToken
        return response
    }

    // MARK: - Tasks
    func getTasks() async throws -> [Task] {
        try await get("/tasks/")
    }

    func createTask(_ task: TaskCreate) async throws -> Task {
        try await post("/tasks/", body: task)
    }

    func updateTask(_ task: Task) async throws -> Task {
        try await put("/tasks/\(task.id)", body: task)
    }

    func deleteTask(id: Int) async throws {
        try await delete("/tasks/\(id)")
    }

    // MARK: - AI Features
    func getChatResponse(prompt: String, history: [ChatMessage]) async throws -> String {
        let request = AIChatRequest(prompt: prompt, history: history)
        let response: AIChatResponse = try await post("/ai/chat", body: request)
        return response.response
    }

    func streamChatResponse(prompt: String, history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let request = AIChatRequest(prompt: prompt, history: history)
                let stream = try await postStream("/ai/stream", body: request)

                for try await chunk in stream {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Generic HTTP Methods
    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(path, method: "GET")
    }

    private func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "POST", body: body)
    }

    private func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        try await request(path, method: "PUT", body: body)
    }

    private func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(path, method: "DELETE")
    }

    private func request<T: Decodable, B: Encodable>(
        _ path: String,
        method: String,
        body: B? = nil as EmptyRequest?
    ) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + path)!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIError: Error {
    case invalidResponse
    case httpError(Int)
    case decodingError
}

struct EmptyRequest: Encodable {}
struct EmptyResponse: Decodable {}
```

### Sync Strategy

**Two-Way Sync Approach**:

1. **On App Launch**:
   - Fetch all data from server
   - Update local SwiftData store
   - Display UI

2. **User Makes Changes**:
   - Update local store immediately (optimistic UI)
   - Queue sync request
   - Send to server in background
   - Handle conflicts (server wins)

3. **Periodic Sync**:
   - Every 5 minutes if app is active
   - On app foreground
   - After network reconnection

4. **Offline Support**:
   - All changes saved locally
   - Sync queue persisted
   - Upload when network available

```swift
// Core/Sync/SyncEngine.swift
@Observable
class SyncEngine {
    var isSyncing = false
    var lastSyncDate: Date?

    func sync() async throws {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        // Sync tasks
        let remoteTasks = try await APIClient.shared.getTasks()
        await updateLocalTasks(remoteTasks)

        // Sync events
        let remoteEvents = try await APIClient.shared.getEvents()
        await updateLocalEvents(remoteEvents)

        // Upload pending changes
        try await uploadPendingChanges()

        lastSyncDate = Date()
    }

    private func uploadPendingChanges() async throws {
        // Get local changes
        let pendingTasks = await getPendingTaskUpdates()

        for task in pendingTasks {
            if task.serverId == nil {
                // Create on server
                let created = try await APIClient.shared.createTask(task)
                await updateLocalTaskWithServerId(task.id, serverId: created.id)
            } else {
                // Update on server
                try await APIClient.shared.updateTask(task)
            }
        }
    }
}
```

## 5. Development Timeline

### Phase 1: Foundation (Week 1-2)
- ✓ Set up Xcode project
- ✓ Configure Git repository
- ✓ Implement API client
- ✓ Authentication flow
- ✓ Basic UI shell
- ✓ Deploy first build to devices

### Phase 2: Core Features (Week 3-5)
- Task list view
- Task creation/editing
- Event calendar
- Dashboard page system
- Local data persistence
- Sync engine

### Phase 3: AI Integration (Week 6-7)
- AI chat interface
- Task suggestions
- Event analysis
- Streaming responses

### Phase 4: Polish (Week 8-9)
- UI/UX refinements
- Animations and transitions
- Error handling
- Offline mode
- Settings screen

### Phase 5: Testing & Launch (Week 10-12)
- Beta testing via TestFlight
- Bug fixes
- Performance optimization
- App Store submission
- Public release

## 6. Getting Started Checklist

### For You (Developer)

- [ ] Install Xcode 15+
- [ ] Create Apple Developer Account
- [ ] Create new iOS project
- [ ] Set up GitHub repository
- [ ] Implement authentication
- [ ] Test backend API connectivity
- [ ] Deploy first build to your iPhone

### For Your Partner (Tester)

- [ ] Install TestFlight from App Store
- [ ] Accept TestFlight invitation email
- [ ] Install Halext Org beta
- [ ] Provide feedback via TestFlight
- [ ] Report bugs

## 7. Next Steps

**Immediate Actions**:

1. **Create Xcode Project** (Today):
   ```bash
   # In Xcode
   File > New > Project
   - iOS App
   - Name: HalextOrg
   - Team: Your Apple ID
   - Organization Identifier: org.halext
   - Interface: SwiftUI
   - Language: Swift
   ```

2. **Test Backend Connection** (Day 1):
   ```swift
   // Quick test in PlaygroundTask {
       let client = APIClient.shared
       let token = try await client.login(username: "dev", password: "dev123")
       print("Logged in:", token)
   }
   ```

3. **First TestFlight Build** (Week 1):
   - Get basic app running
   - Archive and upload
   - Install on both phones
   - Celebrate! 🎉

## Resources

- **Apple Developer**: https://developer.apple.com
- **SwiftUI Tutorials**: https://developer.apple.com/tutorials/swiftui
- **Swift by Sundell**: https://www.swiftbysundell.com
- **Hacking with Swift**: https://www.hackingwithswift.com
- **Point-Free**: https://www.pointfree.co (advanced)

## Questions?

Common questions answered in [FAQ.md](./IOS_FAQ.md)
