# Project Structure

Clean, flat structure for easy navigation.

```
ios/
├── Cafe.xcodeproj           # ← Open this!
│   └── project.pbxproj
│
├── Cafe/                     # Source files
│   ├── CafeApp.swift        # App entry point
│   ├── ContentView.swift    # Legacy (can delete)
│   │
│   ├── App/                 # Application layer
│   │   ├── AppState.swift   # Global state
│   │   └── RootView.swift   # Main navigation
│   │
│   ├── Core/                # Core infrastructure
│   │   ├── API/
│   │   │   └── APIClient.swift     # Network layer
│   │   ├── Auth/
│   │   │   └── KeychainManager.swift  # Secure storage
│   │   └── Models/
│   │       └── Models.swift        # Data models
│   │
│   ├── Features/            # Feature modules
│   │   ├── Auth/
│   │   │   ├── LoginView.swift
│   │   │   └── RegisterView.swift
│   │   └── Tasks/
│   │       ├── TaskListView.swift
│   │       └── NewTaskView.swift
│   │
│   └── Assets.xcassets      # Images, colors, icons
│
├── scripts/                 # Build automation
│   ├── preflight-check.sh          # Pre-upload validation
│   ├── archive-for-testflight.sh   # Archive automation
│   ├── upload-to-testflight.sh     # Upload prep
│   └── increment-build.sh          # Bump build number
│
├── README.md                # Main documentation
├── QUICK_TESTFLIGHT.md      # TestFlight guide
├── DEPLOYMENT_GUIDE.md      # Full deployment docs
├── TESTFLIGHT_SETUP.md      # Step-by-step setup
└── STRUCTURE.md             # This file
```

## Opening in Xcode

```bash
cd /Users/scawful/Code/halext-org/ios
open Cafe.xcodeproj
```

Or double-click `Cafe.xcodeproj` in Finder.

## Architecture

**App Layer** (`App/`):
- AppState: @Observable global state
- RootView: Navigation logic (login vs main)

**Core Layer** (`Core/`):
- APIClient: All backend communication
- KeychainManager: Token storage
- Models: Data structures

**Features Layer** (`Features/`):
- Auth: Login, registration
- Tasks: Task list, creation
- (Future: Calendar, Dashboard, Chat)

## Build Configurations

- **Debug**: Uses `http://127.0.0.1:8000`
- **Release**: Uses `https://org.halext.org/api`

Set in `Core/API/APIClient.swift`:
```swift
#if DEBUG
let environment: APIEnvironment = .development
#else
let environment: APIEnvironment = .production
#endif
```

## Bundle Information

- **Bundle ID**: org.halext.Cafe
- **Display Name**: Cafe
- **Version**: 1.0
- **Build**: 1

## Next Steps

1. Open in Xcode
2. Build (Cmd+B)
3. Run on simulator or device
4. When ready: Archive for TestFlight

See `QUICK_TESTFLIGHT.md` for deployment.
