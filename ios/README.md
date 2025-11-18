# Cafe ☕ - Halext Org iOS App

> **Status**: Xcode project created and ready to develop!
> **Theme**: Pairs perfectly with your Barista macOS setup

## Quick Start

### Open Your Existing Project

```bash
# Navigate to iOS directory
cd /Users/scawful/Code/halext-org/ios

# Open in Xcode
open Cafe.xcodeproj
```

**Or**: Double-click `Cafe.xcodeproj` in Finder

### Current Project Structure

```
ios/
├── Cafe.xcodeproj            # ← Open this in Xcode!
├── Cafe/                      # Source files
│   ├── CafeApp.swift         # App entry point
│   ├── App/                  # App state and navigation
│   ├── Core/                 # API, Auth, Models
│   ├── Features/             # Auth, Tasks views
│   └── Assets.xcassets       # Images, colors
├── scripts/                   # Build and deployment
│   ├── preflight-check.sh
│   ├── archive-for-testflight.sh
│   └── increment-build.sh
└── Models/                    # Legacy starter code (can delete)
```

## Development Workflow

### 1. Run the App

1. Open `Cafe.xcodeproj` in Xcode:
   ```bash
   open Cafe.xcodeproj
   ```
2. Select a simulator (iPhone 15 Pro recommended) or your physical iPhone
3. Press `Cmd+R` or click ▶️ Play button
4. App launches!

### 2. Test API Connection

The app needs to connect to your local backend. Make sure:

```bash
# Backend is running at http://127.0.0.1:8000
cd /Users/scawful/Code/halext-org
./dev-reload.sh

# Verify it's up
curl http://127.0.0.1:8000/
```

In Xcode, update `HalextAPI.swift` if needed:
```swift
private let baseURL = "http://127.0.0.1:8000"  // For simulator
// or
private let baseURL = "http://YOUR-MAC-IP:8000"  // For physical iPhone
```

### 3. Next Features to Build

**Immediate (This Week)**:
- [ ] Login screen using existing `HalextAPI`
- [ ] Store auth token in Keychain
- [ ] Display task list from API
- [ ] Pull-to-refresh functionality

**Short-term (Next 2 Weeks)**:
- [ ] Task creation form
- [ ] Event calendar view
- [ ] Dashboard with widgets
- [ ] Basic sync engine

**Medium-term (Month 1-2)**:
- [ ] AI chat interface
- [ ] Offline support with SwiftData
- [ ] Push notifications
- [ ] Settings screen

## Integrating Existing Code

You have great starter code! Here's how to integrate it into the Cafe project:

### Add Existing Models

1. In Xcode sidebar, right-click `Cafe` folder
2. Select "Add Files to Cafe..."
3. Navigate to `ios/Models/`
4. Select all `.swift` files
5. ✅ Check "Copy items if needed"
6. ✅ Check target: Cafe
7. Click "Add"

**Repeat for**:
- `ios/Networking/HalextAPI.swift`
- Any useful code from `ios/App/`

### Update Cafe App Structure

Organize files like this in Xcode:

```
Cafe/
├── App/
│   └── CafeApp.swift
├── Core/
│   ├── API/
│   │   └── HalextAPI.swift (moved)
│   └── Models/
│       ├── Task.swift (moved)
│       └── LayoutPreset.swift (moved)
├── Features/
│   ├── Auth/
│   │   └── LoginView.swift (new)
│   ├── Tasks/
│   │   └── TaskListView.swift (new)
│   └── Dashboard/
│       └── DashboardView.swift (new)
└── Resources/
    └── Assets.xcassets
```

## Testing on Your iPhone

### Connect Device

1. Connect iPhone via USB
2. Trust computer on iPhone
3. In Xcode, select your iPhone from device dropdown
4. Click Run (Cmd+R)

### First Time Setup

On your iPhone:
1. Settings > General > VPN & Device Management
2. Trust your Apple ID developer certificate
3. App should now launch!

**Note**: Development builds expire after 7 days. Rebuild weekly or use TestFlight.

## Deploy to Partner via TestFlight

### Archive and Upload

1. **Set Scheme to Release**:
   - Product > Scheme > Edit Scheme
   - Run > Build Configuration > Release

2. **Archive**:
   - Product > Archive
   - Wait for archive to complete (2-5 minutes)

3. **Distribute**:
   - Click "Distribute App"
   - Select "TestFlight & App Store"
   - Click "Next" through the wizard
   - Click "Upload"

### Invite Beta Tester

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps > Cafe > TestFlight tab
3. Internal Testing > + (Add Testers)
4. Enter partner's email address
5. Click "Add"

**Partner's side**:
1. Install TestFlight from App Store
2. Check email for invitation
3. Tap "View in TestFlight"
4. Install Cafe
5. Done! ✅

## API Integration Examples

### Login

```swift
// In LoginView.swift
import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 80))
                .foregroundStyle(.brown)

            Text("Welcome to Cafe")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                login()
            } label: {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding()
    }

    func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Use your existing HalextAPI
                let token = try await HalextAPI.shared.login(
                    username: username,
                    password: password
                )

                // Save token to Keychain (implement KeychainManager)
                KeychainManager.shared.saveToken(token)

                // Navigate to main app
                // (implement navigation)

                isLoading = false
            } catch {
                errorMessage = "Login failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
```

### Fetch Tasks

```swift
// In TaskListView.swift
import SwiftUI

struct TaskListView: View {
    @State private var tasks: [Task] = []
    @State private var isLoading = false

    var body: some View {
        List(tasks) { task in
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .refreshable {
            await loadTasks()
        }
        .task {
            await loadTasks()
        }
    }

    func loadTasks() async {
        isLoading = true
        do {
            tasks = try await HalextAPI.shared.fetchTasks()
            isLoading = false
        } catch {
            print("Error loading tasks:", error)
            isLoading = false
        }
    }
}
```

## Configuration

### Development vs Production

Use build configurations to switch between environments:

```swift
#if DEBUG
let API_URL = "http://127.0.0.1:8000"
#else
let API_URL = "https://org.halext.org/api"
#endif
```

### Access Code (if required)

In production, you'll need to handle the access code:

```swift
// Prompt user for access code on registration
// Store in Keychain
// Send as X-Halext-Code header

headers["X-Halext-Code"] = KeychainManager.shared.getAccessCode()
```

## Resources

- **Full iOS Plan**: `docs/IOS_DEVELOPMENT_PLAN.md`
- **User Guide**: `docs/USER_GUIDE.md`
- **Apple Developer**: https://developer.apple.com
- **SwiftUI Tutorials**: https://developer.apple.com/tutorials/swiftui

## Troubleshooting

**Can't connect to backend from simulator**:
- Backend must be running: `./dev-reload.sh`
- Check firewall isn't blocking port 8000
- Use `http://127.0.0.1:8000` for simulator

**Can't connect from physical iPhone**:
- iPhone must be on same WiFi network
- Use your Mac's IP address instead of localhost:
  ```bash
  # Find your Mac's IP
  ifconfig | grep "inet " | grep -v 127.0.0.1

  # Use in API client
  let baseURL = "http://192.168.1.XXX:8000"
  ```

**App crashes on launch**:
- Check console for error messages
- Verify all files are added to target
- Clean build folder (Shift+Cmd+K)
- Delete app from device and reinstall

## Next Steps

1. ✅ Project exists - Open `Cafe.xcodeproj`
2. Run app on simulator
3. Add existing files (Models, Networking) to project
4. Build login screen
5. Test API connection
6. Deploy to your iPhone
7. Set up TestFlight for partner

---

*Brew something amazing! ☕*
