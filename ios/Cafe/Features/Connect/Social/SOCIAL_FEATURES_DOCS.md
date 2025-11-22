# Social Features Documentation

## Overview

The Cafe iOS app now includes comprehensive social features that allow two users to connect, share tasks, track activities, and stay in sync with each other. All social data is stored in CloudKit for real-time synchronization across devices.

## Architecture

### Core Components

1. **Models** (`/Core/Models/SocialModels.swift`)
   - `SocialProfile`: User profile with avatar, status, and presence
   - `Connection`: Partner relationships with invite codes
   - `SharedTask`: Tasks shared between connected users
   - `ActivityItem`: Timeline of social activities
   - `TaskComment`: Comments on shared tasks
   - `PresenceStatus`: Real-time online/offline status
   - `InviteCode`: QR code and invite code system

2. **Managers**
   - `SocialManager` (`/Core/Managers/SocialManager.swift`): CloudKit sync and social operations
   - `SocialPresenceManager` (`/Core/Managers/SocialPresenceManager.swift`): Presence tracking and status updates

3. **Views** (`/Features/Social/`)
   - `SocialDashboardView`: Main social hub with tabs
   - `UserProfileView`: Profile management and connections
   - `SharedTasksView`: Task management with partner
   - `ActivityFeedView`: Timeline of shared activities

## Features

### 1. User Profile & Connection

**UserProfileView** provides:
- Profile creation with username and display name
- Avatar display (auto-generated from initials)
- Status message and current activity
- Online/offline presence indicator
- Connection management

**Connection System**:
- Generate 6-digit invite codes (valid for 1 hour)
- QR code generation for easy sharing
- Accept connections via code entry
- View connected partners
- CloudKit-based connection storage

**Usage**:
```swift
// Generate invite code
let code = try await SocialManager.shared.generateInviteCode()

// Connect with partner
let connection = try await SocialManager.shared.connectWithInviteCode("123456")
```

### 2. Shared Tasks

**SharedTasksView** features:
- Create shared tasks visible to both partners
- Filter tasks by: All, My Tasks, Partner's, Unassigned, Completed
- Assign tasks to yourself or partner
- Real-time sync via CloudKit subscriptions
- Task completion tracking with timestamp and completer info
- Swipe actions for quick completion/deletion

**Task Assignment**:
- Tasks can be unassigned, assigned to you, or assigned to partner
- Visual indicators show who's responsible
- Assignment changes sync immediately

**Usage**:
```swift
// Create shared task
let sharedTask = try await socialManager.createSharedTask(
    task,
    assignedTo: partnerProfileId
)

// Update task
try await socialManager.updateSharedTask(updatedTask)
```

### 3. Activity Feed

**ActivityFeedView** displays:
- Timeline of all shared activities
- Filter by timeframe (Today, Week, Month, All Time)
- Grouped by date with headers
- Activity types:
  - Task created/completed/assigned/commented
  - Event created/updated
  - Status changes
  - New connections

**Activity Items**:
- Actor identification (You vs Partner)
- Timestamp with relative formatting
- Related items (tasks, events)
- Icon and color coding by type

### 4. Status & Presence

**Presence System**:
- Real-time online/offline status
- Current activity ("Working on tasks", "In a meeting", etc.)
- Custom status messages
- Last seen timestamps
- Automatic updates on app lifecycle

**Status Presets**:
- Working
- Meeting
- Lunch
- Break
- Focus Mode
- Custom

**Usage**:
```swift
// Update presence
await presenceManager.updatePresence(
    isOnline: true,
    currentActivity: "Working on tasks",
    statusMessage: "Available"
)

// Set status preset
await presenceManager.setStatusPreset(.working)
```

### 5. Social Dashboard

**SocialDashboardView** combines:
- Partner status widget showing:
  - Online/offline status
  - Current activity
  - Active tasks count
  - Tasks completed today
- Tabbed interface (Tasks, Activity, Profile)
- Quick actions for common operations

**CompactPartnerStatusWidget**:
- Can be embedded in Dashboard
- Shows at-a-glance partner info
- Task count summary

## CloudKit Schema

### Record Types

1. **SocialProfile**
   - userId (Int)
   - username (String)
   - displayName (String, optional)
   - avatarURL (String, optional)
   - statusMessage (String, optional)
   - currentActivity (String, optional)
   - isOnline (Int: 0 or 1)
   - lastSeen (Date, optional)
   - createdAt (Date)
   - updatedAt (Date)

2. **Connection**
   - profileId (String)
   - partnerProfileId (String)
   - status (String: "pending", "accepted", "blocked")
   - inviteCode (String, optional)
   - createdAt (Date)
   - acceptedAt (Date, optional)

3. **SharedTask**
   - taskId (Int)
   - title (String)
   - description (String, optional)
   - completed (Int: 0 or 1)
   - dueDate (Date, optional)
   - assignedToProfileId (String, optional)
   - createdByProfileId (String)
   - connectionId (String)
   - createdAt (Date)
   - updatedAt (Date)
   - completedAt (Date, optional)
   - completedByProfileId (String, optional)

4. **ActivityItem**
   - connectionId (String)
   - profileId (String)
   - activityType (String)
   - title (String)
   - description (String, optional)
   - relatedTaskId (String, optional)
   - relatedEventId (Int, optional)
   - timestamp (Date)

5. **InviteCode**
   - code (String)
   - profileId (String)
   - expiresAt (Date)
   - createdAt (Date)
   - maxUses (Int)
   - currentUses (Int)

### Database Configuration

- **Container ID**: `iCloud.org.halext.Cafe`
- **Public Database**: Used for connections, shared tasks, activities, invite codes
- **Private Database**: Used for user profiles
- **Subscriptions**: Real-time updates for shared tasks and activities

## Integration

### Adding Social Tab to Navigation

The social tab is available in the navigation bar:

```swift
// In NavigationTab enum
case social = "Social"

// Icon
case .social: return "person.2"

// In RootView
case .social:
    SocialDashboardView()
```

### Dashboard Integration

Add the compact widget to Dashboard:

```swift
CompactPartnerStatusWidget()
    .padding()
```

### Navigation Presets

New "Collaboration" preset includes:
- Dashboard
- Tasks
- Social
- Messages
- More

## Privacy & Security

- **Explicit Sharing**: Users must explicitly create connections and share tasks
- **Connection Control**: Users can only connect via invite codes
- **iCloud Authentication**: Requires signed-in iCloud account
- **Data Encryption**: CloudKit handles encryption at rest and in transit
- **Privacy by Design**: No data shared without explicit user action

## Setup Requirements

1. **iCloud Capability**
   - Enable iCloud in Xcode project
   - Add CloudKit capability
   - Configure container: `iCloud.org.halext.Cafe`

2. **Backend Integration**
   - Tasks created via `APIClient.shared.createTask()`
   - Social features use CloudKit independently
   - Backend user IDs linked to CloudKit profiles

3. **Permissions**
   - iCloud account required
   - Background app refresh for presence updates
   - Push notifications for real-time sync (optional)

## Usage Flow

### First-Time Setup

1. User logs into app (backend authentication)
2. User creates social profile (CloudKit)
3. User generates invite code
4. User shares code with partner (QR or text)
5. Partner enters code to connect
6. Both users can now share tasks and activities

### Daily Usage

1. App tracks presence automatically
2. Users create tasks and assign to partner
3. Activities logged automatically
4. Real-time sync keeps both users updated
5. Status messages show current availability

## Best Practices

1. **Presence Updates**: Run every 60 seconds to balance battery/accuracy
2. **Task Sync**: Fetch on app launch and after modifications
3. **Activity Feed**: Limit to recent items (50 by default)
4. **Error Handling**: Gracefully handle CloudKit unavailability
5. **Offline Support**: Queue operations when offline (future enhancement)

## Future Enhancements

- [ ] Multiple connections (currently 1:1)
- [ ] Task comments with rich text
- [ ] File attachments on shared tasks
- [ ] Push notifications for task assignments
- [ ] Shared calendars and events
- [ ] Task templates sharing
- [ ] Analytics and insights
- [ ] Group chat integration
- [ ] Task prioritization voting
- [ ] Shared goals and milestones

## Troubleshooting

### CloudKit Not Available
- Check iCloud account in Settings
- Verify container configuration
- Check network connectivity

### Invite Code Not Working
- Verify code hasn't expired (1 hour limit)
- Check code hasn't reached max uses
- Ensure both users have iCloud enabled

### Tasks Not Syncing
- Check CloudKit subscriptions are set up
- Verify both users are connected
- Check network connectivity
- Try manual refresh

### Presence Not Updating
- Check app is in foreground
- Verify presence manager is started
- Check background app refresh setting

## API Reference

### SocialManager

```swift
// Profile Management
func createProfile(username: String, displayName: String?, userId: Int) async throws -> SocialProfile
func updateProfile(_ profile: SocialProfile) async throws
func fetchProfile(byUserId userId: Int) async throws -> SocialProfile?

// Connections
func generateInviteCode() async throws -> InviteCode
func connectWithInviteCode(_ code: String) async throws -> Connection
func fetchConnections() async throws

// Shared Tasks
func createSharedTask(_ task: Task, assignedTo: String?) async throws -> SharedTask
func updateSharedTask(_ sharedTask: SharedTask) async throws
func fetchSharedTasks() async throws

// Activities
func createActivity(_ activity: ActivityItem) async throws
func fetchActivities(limit: Int) async throws

// Presence
func updatePresence(isOnline: Bool, currentActivity: String?, statusMessage: String?) async throws
func fetchPartnerPresence() async throws
```

### SocialPresenceManager

```swift
// Tracking
func startTrackingPresence()
func stopTrackingPresence()
func updatePresence(isOnline: Bool, currentActivity: String?, statusMessage: String?) async

// Status Management
func updateCurrentActivity(_ activity: String?) async
func updateStatusMessage(_ message: String?) async
func setStatusPreset(_ preset: StatusPreset) async

// Partner Monitoring
func startMonitoringPartnerPresence()
func stopMonitoringPartnerPresence()
func fetchPartnerPresence() async
```

## Files Created

### Models
- `/Core/Models/SocialModels.swift` (400+ lines)

### Managers
- `/Core/Managers/SocialManager.swift` (900+ lines)
- `/Core/Managers/SocialPresenceManager.swift` (400+ lines)

### Views
- `/Features/Social/UserProfileView.swift` (550+ lines)
- `/Features/Social/SharedTasksView.swift` (600+ lines)
- `/Features/Social/ActivityFeedView.swift` (450+ lines)
- `/Features/Social/SocialDashboardView.swift` (400+ lines)

### Configuration
- Updated `/Core/Navigation/NavigationBarManager.swift`
- Updated `/App/RootView.swift`

**Total**: ~3,700 lines of new code

## Support

For issues or questions:
1. Check CloudKit Dashboard for data
2. Review Xcode console for error messages
3. Verify all setup requirements are met
4. Check this documentation for usage examples
