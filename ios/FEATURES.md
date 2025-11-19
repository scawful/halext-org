# Cafe iOS App - Feature Guide

Complete guide to all features implemented in the Cafe iOS app.

---

## 🎯 Core Features

### 1. AI Chat with Streaming Responses
**Location**: AI Chat tab
**Files**: `Features/Chat/ChatView.swift`, `ChatViewModel.swift`

**Features:**
- Real-time streaming responses (token-by-token like ChatGPT)
- Message history with user/assistant differentiation
- Copy and share messages
- Regenerate last response
- Clear conversation
- Beautiful gradient UI with message bubbles
- Typing indicator with animated dots

**Usage:**
1. Tap the AI Chat tab
2. Type your question
3. Watch the AI response stream in real-time
4. Long-press messages for copy/share options

---

### 2. Dashboard with Widgets
**Location**: Dashboard tab
**Files**: `Features/Dashboard/DashboardView.swift`, `DashboardViewModel.swift`

**Features:**
- Time-based greeting (Good Morning/Afternoon/Evening)
- Stats cards: Completed Today, This Week, Upcoming events
- Today's Tasks widget
- Overdue Tasks alert widget
- Upcoming Events widget
- Quick Actions buttons
- Pull-to-refresh

**Widgets Display:**
- Tasks completed today count
- Tasks due this week
- Upcoming events in next 7 days
- Overdue tasks with red alert styling
- Next 5 upcoming events

---

### 3. Calendar & Events
**Location**: Calendar tab
**Files**: `Features/Calendar/CalendarView.swift`, `CalendarViewModel.swift`, `NewEventView.swift`

**Features:**
- Interactive month calendar
- Visual indicators for dates with events
- Date selection with smooth animations
- Event list for selected date
- Create events with form validation
- Recurrence support (None/Daily/Weekly/Monthly)
- Location field for events

**Usage:**
1. Tap dates to view events
2. Use "+" to create new events
3. Swipe to see upcoming events
4. "Today" button to jump to current date

---

### 4. Task Management
**Location**: Tasks tab
**Files**: `Features/Tasks/TaskListView.swift`, `NewTaskView.swift`

**Features:**
- Create, complete, and delete tasks
- Task labels with color coding
- Due dates with overdue indicators
- AI-powered task suggestions
- Filter completed tasks
- Swipe-to-delete
- Pull-to-refresh
- Haptic feedback on all actions

**AI Task Suggestions:**
- Smart subtask recommendations
- Automatic label suggestions
- Priority assessment with reasoning
- Estimated time calculation

---

## 📱 iOS-Native Features

### 5. Push Notifications
**Files**: `Core/Notifications/NotificationManager.swift`

**Notification Types:**
- **Task Due Reminders**: 1 hour before due date
- **Event Reminders**: 15 minutes before event (customizable)
- **Daily Summary**: Morning digest at 8:00 AM

**Notification Actions:**
- Complete Task (from notification)
- Snooze 1 Hour
- View Event

**Setup:**
1. Go to Settings → Notifications
2. Tap "Enable Notifications"
3. Allow when iOS prompts
4. Notifications automatically scheduled for tasks/events with dates

---

### 6. Biometric Authentication (Face ID / Touch ID)
**Files**: `Core/Auth/BiometricAuthManager.swift`, `Features/Auth/BiometricAuthView.swift`

**Features:**
- App lock with Face ID or Touch ID
- Auto-lock on app launch
- Fallback to passcode
- Beautiful lock screen with gradient background
- Automatic detection of available biometric type

**Setup:**
1. Go to Settings → Security
2. Toggle "App Lock with Face ID/Touch ID"
3. Next app launch will require authentication

**Requirements:**
- Face ID or Touch ID must be set up in iOS Settings
- Device passcode required

---

### 7. Siri Shortcuts & App Intents
**Files**: `Core/Intents/AppIntents.swift`

**Available Commands:**
1. **"Add a task in Cafe"**
   - Siri asks for task title and details
   - Creates task with optional due date
   - Schedules notification automatically

2. **"Show my tasks in Cafe"**
   - Opens app and shows today's tasks
   - Speaks number of tasks and first few titles
   - Shows snippet view in Shortcuts

3. **"Add an event in Cafe"**
   - Siri asks for event title, time, duration
   - Optional location
   - Schedules event reminder

4. **"Ask AI in Cafe"**
   - Ask your AI assistant any question
   - Get immediate voice response
   - No need to open the app

**Setup:**
1. Say "Hey Siri, add a task in Cafe"
2. Or open Shortcuts app → search "Cafe"
3. Add shortcuts to Home Screen or automations

---

### 8. Spotlight Search
**Files**: `Core/Search/SpotlightManager.swift`

**Searchable Content:**
- All tasks with title, description, labels, due dates
- All events with title, location, times
- Shows thumbnails in search results
- Deep links directly to items

**Usage:**
1. Swipe down on Home Screen
2. Type task or event name
3. Tap result to open app at that item

**Auto-indexed:**
- Tasks indexed when created/updated
- Events indexed when created/updated
- Removed from search when deleted

---

## 🎨 UI/UX Enhancements

### 9. Haptic Feedback
**Files**: `Core/Utilities/HapticManager.swift`

**Haptic Events:**
- ✅ Task completion: Success haptic
- ⭕ Task uncomplete: Light haptic
- 🗑️ Task delete: Medium haptic
- ➕ Task create: Success haptic
- 🔒 Authentication: Varies by result

**Types Used:**
- **Success**: Completing tasks, successful actions
- **Light**: Minor actions, uncompleting
- **Medium**: Deletions, significant actions
- **Selection**: Taps and selections (planned)

---

### 10. Smooth Animations
**Implementation**: Throughout all views

**Animation Types:**
- **Spring animations**: Task list operations (0.3-0.4s response)
- **Ease-out**: Deletions and removals
- **Fade & slide**: View transitions
- **Smooth scrolling**: Chat messages, calendar navigation

**Examples:**
- Task completion checkbox animates with spring
- New tasks slide in with bounce
- Calendar dates fade when selected
- Chat messages scroll smoothly to bottom

---

### 11. Theme System
**Files**: `Core/Theme/ThemeManager.swift`, `Features/Settings/ThemeSwitcherView.swift`

**Themes:**
- **System**: Follows iOS appearance
- **Light**: Always light mode
- **Dark**: Always dark mode

**Features:**
- Persistent across app restarts
- Smooth transitions
- Updates immediately
- Applies to all windows

**Usage:**
Settings → Appearance → Select theme

---

## 🔐 Security Features

### 12. Keychain Storage
**Files**: `Core/Auth/KeychainManager.swift`

**Secured Data:**
- Authentication tokens
- Access codes
- All credentials

**Security Level:**
- `kSecAttrAccessibleWhenUnlocked`
- Data only accessible when device is unlocked
- Automatic cleanup on logout

---

### 13. Session Management
**Files**: `App/AppState.swift`

**Features:**
- Auto-logout on 401 Unauthorized
- Token validation on app launch
- Session expired messages
- Secure token refresh

---

## ⚙️ Settings & Configuration

### Available Settings

**Account Section:**
- Username display
- Email display
- Full name (if set)

**Security Section:**
- App Lock toggle (Face ID/Touch ID)
- Biometric type display
- Setup instructions

**Notifications Section:**
- Enable/disable notifications
- Permission status indicator
- Quick link to iOS Settings

**Appearance Section:**
- Theme switcher (System/Light/Dark)
- Real-time preview

---

## 📊 Architecture Highlights

### State Management
- **Pattern**: iOS 17+ `@Observable`
- **Global State**: `AppState` via Environment
- **View Models**: Per-feature ViewModels
- **Reactivity**: Automatic UI updates

### Networking
- **Client**: Centralized `APIClient`
- **Auth**: Bearer token with Keychain
- **Streaming**: AsyncThrowingStream for chat
- **Error Handling**: Typed errors with recovery

### Data Flow
```
User Action
    ↓
View Model (async/await)
    ↓
API Client
    ↓
Backend
    ↓
Response Processing
    ↓
State Update (@Observable)
    ↓
UI Auto-Update
```

---

## 🎯 Best Practices Implemented

### Code Quality
- ✅ SwiftUI best practices
- ✅ Async/await throughout (no completion handlers)
- ✅ Proper error handling
- ✅ Type-safe networking
- ✅ Separation of concerns
- ✅ Reusable components

### iOS Integration
- ✅ Face ID/Touch ID
- ✅ Push Notifications
- ✅ Siri Shortcuts
- ✅ Spotlight Search
- ✅ Haptic Feedback
- ✅ System Themes
- ✅ Accessibility ready

### User Experience
- ✅ Loading states
- ✅ Error messages
- ✅ Empty states
- ✅ Pull-to-refresh
- ✅ Smooth animations
- ✅ Haptic feedback
- ✅ Optimistic updates

---

## 📱 iOS Version Requirements

**Minimum**: iOS 17.0
**Recommended**: iOS 17.4+

### iOS 17+ Features Used:
- `@Observable` macro
- App Intents framework
- Live Activities APIs (prepared)
- Improved AsyncSequence
- Enhanced SwiftUI views

---

## 🚀 Future Enhancements

### Planned (Not Yet Implemented)

#### 1. **WidgetKit Home Screen Widgets**
- Today's Tasks widget
- Calendar month widget
- Quick Add widget
- Lock Screen widgets

**Implementation**: Requires separate Widget Extension target in Xcode

#### 2. **Live Activities (Dynamic Island)**
- Active task timer
- Event countdown
- Progress tracking
- Real-time updates

**Requirements**: iOS 16.1+, separate Live Activity target

#### 3. **Offline Support**
- SwiftData local persistence
- Offline queue for API calls
- Sync when online
- Conflict resolution

**Implementation**: SwiftData integration, background sync

#### 4. **Advanced Accessibility**
- Complete VoiceOver labels
- Dynamic Type support
- Reduce Motion respect
- Color contrast improvements

#### 5. **Additional Features**
- Share Extension (add tasks from other apps)
- Watch App companion
- Mac Catalyst version
- CloudKit sync
- Collaborative tasks
- Rich text notes
- File attachments

---

## 🐛 Known Limitations

### Current Constraints:

1. **Widgets**: Require Widget Extension target (Xcode project config)
2. **Live Activities**: Require Activity target and backend support
3. **Remote Notifications**: Require APNs configuration and server integration
4. **Offline Mode**: Full offline support not yet implemented
5. **Deep Linking**: URL scheme handling not yet configured

---

## 📖 Usage Examples

### Example 1: Morning Routine
```
1. App opens → Face ID unlocks
2. Dashboard shows: "Good Morning"
3. View today's 3 tasks
4. Complete task → Success haptic
5. Check calendar → 2 events today
6. Ask AI: "What should I prioritize?"
```

### Example 2: Siri Workflow
```
"Hey Siri, add a task in Cafe"
Siri: "What do you want to do?"
You: "Buy groceries"
Siri: "Any additional details?"
You: "Milk, bread, eggs"
Siri: "Created task: Buy groceries"
```

### Example 3: Notification Flow
```
1. Create task with 2pm due date
2. At 1pm: Notification appears
3. 3D Touch notification
4. Tap "Complete Task"
5. Task marked done without opening app
```

---

## 🎨 Design System

### Colors
- **Primary**: Blue gradient
- **AI**: Purple gradient
- **Success**: Green
- **Warning**: Orange
- **Error**: Red
- **Secondary**: System gray

### Typography
- **Large Title**: Dashboard headers
- **Title**: Section headers
- **Headline**: Task titles
- **Subheadline**: Descriptions
- **Caption**: Metadata

### Spacing
- **Small**: 4-8pt
- **Medium**: 12-16pt
- **Large**: 20-24pt
- **XLarge**: 32-40pt

---

## 📞 Support & Feedback

For issues or feature requests:
- GitHub: https://github.com/anthropics/claude-code/issues
- Provide: iOS version, device model, steps to reproduce

---

**Last Updated**: November 2025
**Version**: 1.0.0
**Built with**: SwiftUI, iOS 17+, App Intents, Siri Shortcuts
