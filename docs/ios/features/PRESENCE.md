# Presence Feature - Cross-Platform Documentation

This document describes the presence tracking feature implemented in the iOS app, with specifications for backend and web platforms to ensure feature parity across the halext-org ecosystem.

## Overview

The presence system tracks user online/offline status and provides real-time updates through both polling and WebSocket connections. It enables features like:
- Showing which users are currently online
- Last seen timestamps for offline users
- Real-time typing indicators in conversations

## iOS Implementation

**Files:**
- `/ios/Cafe/Core/Presence/PresenceManager.swift` - Main presence manager with API integration
- `/ios/Cafe/Core/API/APIClient+Presence.swift` - API client extension for presence endpoints

**Key Components:**
- `PresenceManager` - Singleton that manages presence state, API calls, and WebSocket connection
- `PresenceWebSocketManager` - WebSocket client for real-time presence updates
- `PresenceStatus` - Enum with values: `online`, `away`, `offline`
- `UserPresence` - Model representing a user's presence state

## API Requirements

### 1. Update Own Presence Status

**Endpoint:** `POST /api/presence/status`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
    "status": "online" | "away" | "offline"
}
```

**Response (200 OK):**
```json
{
    "user_id": 1,
    "status": "online",
    "last_seen": "2024-01-01T12:00:00Z"
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or expired token
- `422 Unprocessable Entity` - Invalid status value

**Business Logic:**
- Update the user's presence status in the database
- Update the `last_seen` timestamp to current time
- Broadcast presence update to all subscribed WebSocket clients
- Status values must be one of: `online`, `away`, `offline`

---

### 2. Get Multiple User Presences

**Endpoint:** `GET /api/presence/users`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `user_ids` (optional): Comma-separated list of user IDs to fetch

**Response (200 OK):**
```json
[
    {
        "user_id": 1,
        "status": "online",
        "last_seen": "2024-01-01T12:00:00Z",
        "is_typing": false
    },
    {
        "user_id": 2,
        "status": "offline",
        "last_seen": "2024-01-01T10:30:00Z",
        "is_typing": false
    }
]
```

**Business Logic:**
- If `user_ids` is provided, return presence only for those users
- If `user_ids` is not provided, return presence for all users the authenticated user can see (partners, social circle members, etc.)
- Include `is_typing` field showing if user is currently typing in any conversation with the requester

---

### 3. Get Single User Presence

**Endpoint:** `GET /api/presence/users/{user_id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
    "user_id": 1,
    "status": "online",
    "last_seen": "2024-01-01T12:00:00Z",
    "is_typing": false
}
```

**Error Responses:**
- `401 Unauthorized` - Invalid or expired token
- `404 Not Found` - User not found or not visible to requester

---

### 4. Send Typing Indicator

**Endpoint:** `POST /api/conversations/{conversation_id}/typing`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
    "is_typing": true
}
```

**Response (200 OK):**
Empty response or acknowledgment

**Business Logic:**
- Validate user is a participant in the conversation
- Store typing state with timestamp
- Auto-expire typing status after 5 seconds if not refreshed
- Broadcast typing update to conversation participants via WebSocket

**Client-Side Behavior:**
- Send `is_typing: true` on first keystroke
- Send `is_typing: false` after 3 seconds of inactivity
- Debounce to avoid excessive requests (max 1 request per 2 seconds)

---

## WebSocket Endpoint

**URL:** `ws[s]://[host]/api/presence/subscribe`

**Authentication:**
```
Authorization: Bearer {token}
```
Or via query parameter: `?token={token}`

### Connection Flow

1. Client connects with authentication token
2. Server validates token and establishes connection
3. Server sends initial presence state for all relevant users
4. Server pushes real-time updates as they occur

### Message Types (Server -> Client)

**Initial State:**
```json
{
    "type": "initial_state",
    "data": {
        "presences": [
            {
                "user_id": 1,
                "status": "online",
                "last_seen": "2024-01-01T12:00:00Z"
            }
        ]
    }
}
```

**Presence Update:**
```json
{
    "type": "presence_update",
    "data": {
        "user_id": 1,
        "status": "online",
        "last_seen": "2024-01-01T12:00:00Z"
    }
}
```

**Typing Update:**
```json
{
    "type": "typing_update",
    "data": {
        "user_id": 1,
        "conversation_id": 123,
        "is_typing": true
    }
}
```

### Reconnection Strategy

Clients should implement exponential backoff:
- Initial delay: 1 second
- Max delay: 16 seconds
- Formula: `min(16, 2^attempt)` seconds

---

## State Management

### iOS Behavior

| App State | Presence Status | Actions |
|-----------|-----------------|---------|
| Foreground | `online` | Start timer, connect WebSocket |
| Background | `away` | Send final update, stop timer, disconnect WebSocket |
| Terminated | `offline` | Server should timeout presence after no heartbeat |

### Rate Limiting

- Minimum 5 seconds between presence status updates
- iOS queues updates and sends when rate limit allows
- Failed updates are stored and retried on next successful operation

### Offline Support

- Pending presence updates are stored in memory
- When connectivity returns (detected via successful API call), pending updates are sent
- No persistence needed - app restart will send fresh `online` status

---

## Database Schema Recommendations

### Option 1: Add to Users Table

```sql
ALTER TABLE users ADD COLUMN presence_status VARCHAR(10) DEFAULT 'offline';
ALTER TABLE users ADD COLUMN last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

### Option 2: Separate Presence Table (Recommended for High Traffic)

```sql
CREATE TABLE user_presence (
    user_id INTEGER PRIMARY KEY REFERENCES users(id),
    status VARCHAR(10) NOT NULL DEFAULT 'offline',
    last_seen TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE typing_indicators (
    user_id INTEGER NOT NULL REFERENCES users(id),
    conversation_id INTEGER NOT NULL REFERENCES conversations(id),
    is_typing BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, conversation_id)
);
```

**Indexes:**
```sql
CREATE INDEX idx_user_presence_status ON user_presence(status);
CREATE INDEX idx_typing_indicators_conversation ON typing_indicators(conversation_id);
```

---

## Testing Criteria

### Backend Tests

- [ ] POST /presence/status updates user's presence correctly
- [ ] POST /presence/status broadcasts to WebSocket subscribers
- [ ] GET /presence/users returns correct presences for visible users
- [ ] GET /presence/users/{id} returns 404 for non-visible users
- [ ] WebSocket authentication works with Bearer token
- [ ] WebSocket reconnection preserves subscription state
- [ ] Typing indicators auto-expire after timeout

### iOS Tests

- [ ] PresenceManager updates status on app lifecycle changes
- [ ] Rate limiting prevents excessive API calls
- [ ] Offline scenarios queue updates for retry
- [ ] WebSocket reconnects automatically with backoff
- [ ] Authentication errors stop presence updates
- [ ] handleLogin() and handleLogout() properly manage state

### Cross-Platform Parity Tests

- [ ] Status enum values match across all platforms
- [ ] Date formats are ISO 8601 on all platforms
- [ ] WebSocket message formats are consistent
- [ ] Typing indicator timeout matches (5 seconds server-side)

---

## Platform-Specific Considerations

### iOS Specifics
- Uses URLSessionWebSocketTask for WebSocket
- Background mode limited - must disconnect when backgrounded
- App lifecycle managed via NotificationCenter

### Web Specifics
- Can maintain WebSocket while tab is open
- Consider visibility API for away status
- Use window.onbeforeunload for offline notification

### Backend Specifics
- Should handle concurrent connections from same user (multiple devices)
- Consider Redis for real-time presence state in distributed systems
- Implement heartbeat mechanism for detecting stale connections

---

## Security Considerations

- All endpoints require authentication
- Users can only see presence of users they have permission to view
- WebSocket connections must be authenticated before sending any data
- Rate limiting should be enforced server-side to prevent abuse

---

## Related Files

- `/ios/Cafe/Core/Presence/PresenceManager.swift` - iOS presence manager
- `/ios/Cafe/Core/API/APIClient+Presence.swift` - iOS API client extension
- `/ios/Cafe/Core/Models/CollaborationModels.swift` - Existing PartnerPresence model
- `/ios/Cafe/Core/API/APIClient+Collaboration.swift` - Existing getPartnerPresence endpoint
