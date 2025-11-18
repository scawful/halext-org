# Adding New Swift Files to Xcode Project

I've created a complete iOS app structure with authentication, task management, and AI integration. Here's how to add these files to your Xcode project.

## New Files Created

### Core Infrastructure
- `Cafe/Core/Auth/KeychainManager.swift` - Secure token storage
- `Cafe/Core/API/APIClient.swift` - Network layer
- `Cafe/Core/Models/Models.swift` - Data models

### App Structure
- `Cafe/App/AppState.swift` - Global app state and auth
- `Cafe/App/RootView.swift` - Main navigation
- `Cafe/App/CafeApp.swift` - Updated app entry point

### Features
- `Cafe/Features/Auth/LoginView.swift` - Login screen
- `Cafe/Features/Auth/RegisterView.swift` - Registration screen
- `Cafe/Features/Tasks/TaskListView.swift` - Task list with pull-to-refresh
- `Cafe/Features/Tasks/NewTaskView.swift` - Task creation with AI suggestions

## Step 1: Add Files to Xcode Project

### Option A: Drag and Drop (Easiest)

1. Open `Cafe.xcodeproj` in Xcode
2. In Finder, navigate to `/Users/scawful/Code/halext-org/ios/Cafe/Cafe/`
3. Drag the following folders into Xcode's Project Navigator:
   - **Core/** folder → Drag into "Cafe" group
   - **Features/** folder → Drag into "Cafe" group
   - **App/AppState.swift** → Drag into existing "App" folder
   - **App/RootView.swift** → Drag into existing "App" folder

4. When prompted:
   - ✅ **Check** "Copy items if needed" (even though they're already there)
   - ✅ **Check** "Create groups"
   - ✅ **Check** target: **Cafe**
   - Click **Finish**

### Option B: Add Files Via Menu

1. In Xcode, right-click the "Cafe" group in Project Navigator
2. Select **Add Files to "Cafe"...**
3. Navigate to each file/folder listed above
4. Select and add with same options as Option A

## Step 2: Verify Project Structure

Your Xcode Project Navigator should look like this:

```
Cafe
├── App
│   ├── CafeApp.swift (updated)
│   ├── AppState.swift (new)
│   └── RootView.swift (new)
├── Core
│   ├── API
│   │   └── APIClient.swift
│   ├── Auth
│   │   └── KeychainManager.swift
│   └── Models
│       └── Models.swift
├── Features
│   ├── Auth
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   └── Tasks
│       ├── TaskListView.swift
│       └── NewTaskView.swift
├── ContentView.swift (can be deleted later)
└── Assets.xcassets
```

## Step 3: Build the Project

1. Select a simulator (iPhone 15 Pro recommended) or your device
2. Press **Cmd+B** to build
3. Fix any build errors if they appear

### Common Build Errors and Fixes

**Error**: "Cannot find 'AppState' in scope"
- **Fix**: Make sure AppState.swift is added to the Cafe target

**Error**: "Cannot find 'APIClient' in scope"
- **Fix**: Make sure all Core files are added to the Cafe target

**Error**: Missing Foundation/SwiftUI imports
- **Fix**: Files should already have correct imports, but verify they're there

## Step 4: Run the App

1. Press **Cmd+R** or click the Play button ▶️
2. You should see the login screen with the Cafe logo ☕
3. The app is ready to use!

## Step 5: Test the Features

### Test Login (Dev Account)
1. Username: `dev`
2. Password: `dev123`
3. Make sure backend is running: `./dev-reload.sh`

### Test Registration
1. Tap "Don't have an account? **Register**"
2. Fill in the form
3. Create a new account

### Test Tasks
1. After logging in, go to the "Tasks" tab
2. You should see demo tasks automatically created
3. Tap + to create a new task
4. Use the AI suggestions feature

## Step 6: Clean Up (Optional)

You can now delete the old ContentView.swift since we're using the new structure:

1. In Xcode, select `ContentView.swift`
2. Right-click → Delete
3. Choose "Move to Trash"

## What Each Component Does

### AppState
- Manages authentication state
- Stores current user info
- Handles login/logout globally
- Persists auth token in Keychain

### RootView
- Shows LoginView when logged out
- Shows MainTabView when logged in
- Provides tab navigation for main features

### APIClient
- All network requests to backend
- Automatic token injection
- Environment switching (dev/production)
- Error handling

### KeychainManager
- Secure storage for auth token
- Secure storage for access code
- iOS Keychain integration

### LoginView & RegisterView
- Beautiful SwiftUI forms
- Input validation
- Error handling
- Access code support

### TaskListView
- Lists all tasks from API
- Pull-to-refresh
- Mark complete/incomplete
- Swipe to delete
- Filter completed tasks

### NewTaskView
- Create new tasks
- Set due dates
- Add labels
- AI-powered suggestions for subtasks and labels

## Next Development Steps

1. **Add Event Views** - Calendar functionality
2. **Add Dashboard** - Personalized widgets
3. **Add AI Chat** - Full chat interface
4. **Offline Support** - SwiftData for local caching
5. **Push Notifications** - For task reminders
6. **Widgets** - iOS home screen widgets

## Testing on Your iPhone

### Connect Device
1. Connect iPhone via USB-C
2. Trust computer on iPhone
3. Select your iPhone from device dropdown
4. Run the app (Cmd+R)

### First Time Setup
1. Xcode may ask to register your device
2. Settings > General > VPN & Device Management
3. Trust your developer certificate
4. App should launch!

### Connect to Backend
Since your iPhone can't access `127.0.0.1`, you'll need to:

1. Find your Mac's IP address:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```

2. Update APIClient.swift temporarily for testing:
   ```swift
   #if DEBUG
   let environment: APIEnvironment = .development
   // Change baseURL to your Mac's IP:
   // return "http://YOUR-MAC-IP:8000"
   #else
   ```

Or better: Add a settings screen to switch API endpoints dynamically.

## Deploy to Partner via TestFlight

See the main iOS README for TestFlight deployment instructions.

## Troubleshooting

**App crashes on launch**:
- Clean build folder: Shift+Cmd+K
- Delete app from simulator/device
- Rebuild and run

**Can't see new files in Xcode**:
- Make sure you added them to the Cafe target
- Check they're in the correct group

**Network requests fail**:
- Verify backend is running
- Check API_BASE_URL in APIClient
- Check console for detailed error messages

**Keychain errors on simulator**:
- Reset simulator: Device > Erase All Content and Settings
- Keychain sometimes needs reset on simulator

---

**Ready to build?** Open `Cafe.xcodeproj` and start adding files!
