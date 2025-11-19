# iOS Advanced Features Documentation

## Overview
This document describes the iOS-specific advanced features exposed in the Cafe app's "Advanced Features" settings page. This information is crucial for maintaining feature parity across iOS, web, and backend platforms.

---

## 1. Siri Shortcuts & App Intents

### iOS Implementation
- **File**: `/Cafe/Core/Shortcuts/AdvancedShortcuts.swift`
- **Technology**: Apple's App Intents framework
- **Capabilities**: Voice-activated task management

### Available Shortcuts

#### Create Task Intent
```swift
struct CreateTaskIntent: AppIntent {
    @Parameter(title: "Task Title") var title: String
    @Parameter(title: "Due Date", optional: true) var dueDate: Date?
}
```

**API Requirements:**
- `POST /api/tasks`
- Request: `TaskCreate` with title, description (optional), dueDate (optional), labels (optional)
- Response: Created `Task` object with ID
- Authentication: Bearer token required

#### Complete Task Intent
```swift
struct CompleteTaskByNameIntent: AppIntent {
    @Parameter(title: "Task Name") var taskName: String
}
```

**API Requirements:**
- `GET /api/tasks` - Search for task by name (case-insensitive substring match)
- `PATCH /api/tasks/{id}` - Update task with `completed: true`
- Must handle partial matches (e.g., "grocery" matches "Buy groceries")

#### Search Tasks Intent
```swift
struct SearchTasksIntent: AppIntent {
    @Parameter(title: "Search Query") var query: String
}
```

**API Requirements:**
- `GET /api/tasks?search={query}` - Full-text search in title and description
- Must support case-insensitive matching
- Return array of matching tasks

#### Get Tasks Count Intent
```swift
struct GetTasksCountIntent: AppIntent {
    @Parameter(title: "Status") var status: TaskStatus
    // Statuses: all, incomplete, completed, overdue, today
}
```

**API Requirements:**
- `GET /api/tasks` with client-side filtering OR
- `GET /api/tasks?status={status}` with backend filtering
- Support filtering by: all, incomplete, completed, overdue, dueToday
- Return count of matching tasks

#### Create Multiple Tasks Intent
**API Requirements:**
- Batch task creation endpoint (preferred): `POST /api/tasks/batch`
- Request: Array of `TaskCreate` objects
- Response: Array of created `Task` objects with success/failure status
- Alternative: Multiple sequential `POST /api/tasks` calls

#### Get Next Event Intent
**API Requirements:**
- `GET /api/events?upcoming=true&limit=1`
- Sort by startTime ascending
- Filter for events with startTime > current time
- Return single event with location, title, startTime, endTime

### Cross-Platform Equivalents
**Web**:
- Implement keyboard shortcuts (Cmd+N for new task, etc.)
- Add URL scheme handlers for deep linking from shortcuts

**Backend**:
- Ensure all endpoints support query parameters for filtering
- Add `/api/shortcuts/available` endpoint to list available automation actions
- Consider webhook support for third-party automation tools (Zapier, IFTTT)

---

## 2. Focus Filters (iOS 16+)

### iOS Implementation
- **File**: `/Cafe/Core/Focus/FocusFilterManager.swift`
- **Technology**: SetFocusFilterIntent
- **Behavior**: Automatically filters tasks when iOS Focus mode is active

### Focus Modes Supported
- Work
- Personal
- Sleep
- Driving
- Fitness
- Reading
- Gaming

### Filtering Logic
```swift
// Example: Work Focus
filtered = tasks.filter { task in
    task.labels.contains { $0.name.lowercased().contains("work") } ||
    task.title.lowercased().contains("work") ||
    task.title.lowercased().contains("meeting")
}

// Priority Filter (when enabled)
filtered = tasks.filter { task in
    task.dueDate <= Date().addingTimeInterval(86400) // Next 24 hours
}
```

### API Requirements
**Endpoint**: None required - filtering is client-side
**Data Model**: Tasks must have:
- `labels` array with `name` field
- `title` field for keyword matching
- `dueDate` for priority filtering
- `completed` status

### Recommended Label Schema
```json
{
  "suggested_labels": {
    "work": ["work", "meeting", "project", "deadline"],
    "personal": ["personal", "home", "family", "errands"],
    "fitness": ["fitness", "health", "workout", "exercise"],
    "reading": ["reading", "book", "article", "learning"],
    "gaming": ["gaming", "entertainment", "hobby"]
  }
}
```

### Cross-Platform Equivalents
**Web**:
- Add "Focus Mode" toggle in web UI
- Store user's preferred focus mode in local storage or user preferences
- Apply same filtering logic based on selected mode

**Backend**:
- Add `GET /api/users/me/focus-preferences` endpoint
- Store user's focus filter configurations per mode
- Add `GET /api/tasks?focus_mode={mode}` to return pre-filtered tasks

---

## 3. Document Scanning with OCR

### iOS Implementation
- **File**: `/Cafe/Core/Managers/DocumentScannerManager.swift`
- **Technology**: VisionKit + Vision Framework
- **Capabilities**:
  - Multi-page document scanning
  - Text recognition (OCR) in 50+ languages
  - QR/Barcode detection

### Features
1. **Document Camera**: Built-in iOS document scanner with auto-edge detection
2. **OCR**: Extract text from images with 95%+ accuracy
3. **Barcode/QR**: Detect and decode barcodes in images

### Use Cases
- Scan receipts and attach to expense tasks
- Scan meeting notes and create tasks
- Scan business cards and create contacts
- Extract text from printed documents

### API Requirements
**File Upload Endpoint**: `POST /api/files`
- Accept multipart/form-data
- Support multiple image files per request
- Store images with task/event association
- Return file URLs and IDs

**OCR Endpoint** (Optional): `POST /api/ocr`
- Accept image file
- Return extracted text
- Useful for web platform without native OCR
- Consider using Tesseract or Google Cloud Vision API

**Data Model**:
```typescript
interface Attachment {
  id: number;
  task_id?: number;
  event_id?: number;
  file_url: string;
  file_name: string;
  file_type: string; // "image/jpeg", "application/pdf"
  extracted_text?: string; // OCR result
  created_at: Date;
}
```

### Cross-Platform Equivalents
**Web**:
- HTML5 file upload with drag-and-drop
- Use Web OCR library (Tesseract.js) for client-side text extraction
- Camera access via `getUserMedia()` API
- Consider integrating with browser-based scanning libraries

**Backend**:
- Implement OCR service using:
  - Google Cloud Vision API
  - Amazon Textract
  - Azure Computer Vision
  - Open-source: Tesseract OCR
- Store extracted text in database for searchability
- Generate thumbnails for image attachments

---

## 4. Speech Recognition

### iOS Implementation
- **File**: `/Cafe/Core/Managers/SpeechRecognitionManager.swift`
- **Technology**: Speech Framework
- **Languages**: Supports 50+ languages
- **Mode**: Real-time streaming recognition

### Features
- Live voice-to-text transcription
- Offline support after initial language download
- Punctuation and formatting
- Audio file transcription

### Permissions Required
- Microphone access: `NSMicrophoneUsageDescription`
- Speech recognition: `NSSpeechRecognitionUsageDescription`

### API Requirements
**Optional Speech-to-Text Endpoint**: `POST /api/speech/transcribe`
- Accept audio file (WebM, MP3, WAV)
- Return transcribed text
- Useful for web platform without native speech API
- Consider using:
  - Google Cloud Speech-to-Text
  - AWS Transcribe
  - Azure Speech Services

### Use Cases
- Voice input for creating tasks/notes
- Dictate task descriptions
- Hands-free task management
- Accessibility support

### Cross-Platform Equivalents
**Web**:
- Web Speech API (`webkitSpeechRecognition` / `SpeechRecognition`)
- Fallback to server-side transcription for unsupported browsers
- Microphone permission required

**Example Web Implementation**:
```javascript
const recognition = new webkitSpeechRecognition();
recognition.continuous = true;
recognition.interimResults = true;
recognition.onresult = (event) => {
  const transcript = event.results[0][0].transcript;
  // Update task input field
};
```

---

## 5. Live Activities (iOS 16.1+, Dynamic Island)

### iOS Implementation
- **Files**:
  - `/Cafe/Core/LiveActivities/TaskLiveActivity.swift`
  - `/Cafe/Core/LiveActivities/TaskLiveActivityManager.swift`
- **Technology**: ActivityKit
- **Display**: Dynamic Island, Lock Screen, StandBy mode

### Features
- Real-time task timer in Dynamic Island
- Show task progress on Lock Screen
- Interactive controls (pause/resume/stop)
- Automatic updates every second

### Live Activity States
```swift
struct TaskActivityAttributes: ActivityAttributes {
    let taskId: Int
    let taskTitle: String

    struct ContentState {
        let isRunning: Bool
        let elapsedTime: TimeInterval
        let startTime: Date
    }
}
```

### API Requirements
**Real-time Updates** (Optional but recommended):
- WebSocket connection: `wss://api.example.com/tasks/{id}/activity`
- Or Server-Sent Events: `GET /api/tasks/{id}/activity/stream`
- Push updates when:
  - Task status changes
  - Task is updated by another user/device
  - Task is deleted

**Push Notifications API**:
- Update Live Activity via push notifications
- Apple Push Notification Service (APNS) with `update-live-activity` type
- Payload includes updated `elapsedTime` and `isRunning` state

### Cross-Platform Equivalents
**Web**:
- Browser notifications with progress updates
- Background tab updates using Service Workers
- Desktop notifications (Notification API)

**Android**:
- Ongoing Notifications with progress bar
- Picture-in-Picture widgets
- Home screen widgets with auto-refresh

---

## 6. Handoff & Continuity

### iOS Implementation
- **File**: `/Cafe/Core/Continuity/HandoffManager.swift`
- **Technology**: NSUserActivity, Universal Links
- **Platforms**: iPhone, iPad, Mac, Apple Watch, web browser

### Activity Types
```swift
// View Task
activityType: "org.halext.cafe.view-task"
userInfo: { taskId: Int, taskTitle: String }
webpageURL: "https://cafe.halext.org/tasks/{id}"

// View Event
activityType: "org.halext.cafe.view-event"
userInfo: { eventId: Int, eventTitle: String, startTime: Date }
webpageURL: "https://cafe.halext.org/events/{id}"

// Chat
activityType: "org.halext.cafe.chat"
webpageURL: "https://cafe.halext.org/chat"
```

### API Requirements
**Universal Links**:
- Configure `.well-known/apple-app-site-association` on web domain
- Support URL patterns:
  - `/tasks/{id}` → Open task detail
  - `/events/{id}` → Open event detail
  - `/chat` → Open chat interface

**Deep Link Handling**:
- Web app must handle these URL patterns
- iOS app registers URL schemes: `cafe://`
- Deep links should work even when not logged in (show login first)

### Cross-Platform Implementation
**Web**:
```json
// .well-known/apple-app-site-association
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAMID.org.halext.cafe",
      "paths": ["/tasks/*", "/events/*", "/chat"]
    }]
  }
}
```

**URL Routing**:
- Ensure web routes match iOS activity types
- Preserve state when switching devices
- Handle authentication state across devices

---

## 7. Quick Actions (3D Touch / Haptic Touch)

### iOS Implementation
- **File**: `/Cafe/Core/QuickActions/QuickActionsManager.swift`
- **Technology**: UIApplicationShortcutItem
- **Trigger**: Long-press app icon on home screen

### Available Actions
1. **New Task**: Create task immediately
2. **New Event**: Schedule new event
3. **Today's Tasks**: Jump to today view
4. **AI Assistant**: Open chat interface

### API Requirements
None - Quick Actions launch the app to specific views
Deep linking handled by app navigation

### Cross-Platform Equivalents
**Web**:
- Right-click context menu on PWA icon
- Custom jump list for pinned sites
- Keyboard shortcuts (documented in help)

**Android**:
- App Shortcuts (static and dynamic)
- Long-press launcher icon

---

## 8. Spotlight Search Integration

### iOS Implementation
- **File**: `/Cafe/Core/Search/SpotlightManager.swift`
- **Technology**: Core Spotlight
- **Scope**: System-wide iOS search

### Indexed Content
**Tasks**:
```swift
CSSearchableItem(
  uniqueIdentifier: "task-{id}",
  domainIdentifier: "org.halext.cafe.tasks",
  attributes: {
    title: task.title,
    contentDescription: task.description,
    keywords: task.labels.map { $0.name },
    dueDate: task.dueDate,
    completionDate: task.completed ? task.createdAt : nil
  }
)
```

**Events**:
```swift
CSSearchableItem(
  uniqueIdentifier: "event-{id}",
  domainIdentifier: "org.halext.cafe.events",
  attributes: {
    title: event.title,
    contentDescription: event.description,
    startDate: event.startTime,
    endDate: event.endTime,
    namedLocation: event.location
  }
)
```

### API Requirements
**Batch Index Endpoint**: `GET /api/search/index`
- Return all user's tasks and events for indexing
- Paginated response (500 items per page)
- Called on app launch and after sync
- Include deleted_at timestamp for de-indexing

**Search Metadata**:
- Ensure all tasks/events have searchable text
- Support full-text search on backend for consistency
- Index updates should trigger Spotlight reindex

### Cross-Platform Equivalents
**Web**:
- Browser history integration (update page titles)
- In-app global search with fuzzy matching
- Recent items / search history

**Desktop**:
- Windows Search integration (if desktop app)
- macOS Spotlight (via file metadata)
- Linux desktop search (Tracker, Baloo)

---

## Security & Privacy Considerations

### Data Handling
1. **Local Storage**: Spotlight, Speech Recognition, and Focus Filters store data locally
2. **Encryption**: Keychain for tokens, encrypted UserDefaults for sensitive settings
3. **Permissions**: Explicit user consent for microphone, speech, notifications
4. **Data Retention**: Spotlight index cleared on logout

### GDPR Compliance
- All features respect user's right to data deletion
- Spotlight index cleared when user deletes account
- Voice recordings are processed locally (not sent to server)
- Document scans stored with explicit user consent

### Backend Security Requirements
- Rate limiting on OCR endpoints (prevent abuse)
- File upload size limits (10MB per file)
- Virus scanning on uploaded files
- Secure file storage (S3 with pre-signed URLs)
- Delete user files when account is deleted

---

## Testing Checklist

### iOS Testing
- [ ] Siri Shortcuts work with voice commands
- [ ] Focus Filters apply correctly in each mode
- [ ] Document scanner extracts text accurately
- [ ] Speech recognition transcribes in real-time
- [ ] Live Activities update in Dynamic Island
- [ ] Handoff transitions to Mac/iPad/Web
- [ ] Quick Actions launch correct views
- [ ] Spotlight search finds tasks and events

### Backend Testing
- [ ] All endpoints handle authentication
- [ ] File uploads respect size limits
- [ ] OCR service returns accurate text
- [ ] Batch operations handle errors gracefully
- [ ] Universal links redirect correctly
- [ ] WebSocket connections stay alive
- [ ] Push notifications delivered reliably

### Cross-Platform Testing
- [ ] Web app matches iOS feature set
- [ ] Deep links work bidirectionally
- [ ] Data syncs in real-time across devices
- [ ] Search results consistent across platforms
- [ ] Focus modes can be shared between platforms

---

## Future Enhancements

### Potential iOS Features
1. **Widgets**: Multiple widget sizes (small, medium, large)
2. **Apple Watch**: Complication support, Siri shortcuts on watch
3. **CarPlay**: Voice-controlled task management while driving
4. **SharePlay**: Collaborative task viewing in FaceTime
5. **App Clips**: Lightweight app for specific tasks
6. **StoreKit**: In-app purchases for premium features

### Backend Requirements for Future Features
- Real-time collaboration API (WebRTC)
- Voice AI assistant integration
- Premium subscription management
- Analytics for usage patterns
- A/B testing framework

---

## API Endpoint Summary

### Required Endpoints
| Endpoint | Method | Purpose | Platform |
|----------|--------|---------|----------|
| `/api/tasks` | GET | List tasks with filtering | All |
| `/api/tasks` | POST | Create task | All |
| `/api/tasks/{id}` | PATCH | Update task | All |
| `/api/tasks/{id}` | DELETE | Delete task | All |
| `/api/events` | GET | List events | All |
| `/api/events` | POST | Create event | All |
| `/api/files` | POST | Upload attachment | All |
| `/api/search/index` | GET | Batch index for Spotlight | iOS |

### Optional but Recommended
| Endpoint | Method | Purpose | Platform |
|----------|--------|---------|----------|
| `/api/tasks/batch` | POST | Batch create tasks | iOS Shortcuts |
| `/api/ocr` | POST | Server-side OCR | Web |
| `/api/speech/transcribe` | POST | Server-side STT | Web |
| `/api/tasks/{id}/activity` | WebSocket | Live Activity updates | iOS |
| `/api/users/me/focus-preferences` | GET/PUT | Store focus settings | All |

---

## Contact & Support

For questions about iOS implementation or cross-platform parity:
- **iOS Lead**: Review `/Cafe/Features/Settings/AdvancedFeaturesView.swift`
- **API Spec**: Check backend OpenAPI documentation
- **Testing**: See `/Cafe/Tests/` directory

**Last Updated**: 2025-11-19
**iOS Version**: 17.0+
**Backend API Version**: v1
