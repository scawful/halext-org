# iOS Admin Interface - Feature Documentation

**Created:** 2025-11-19
**iOS Version:** Swift 6.0+ / iOS 18.0+
**Backend Integration:** Halext Org Backend (commit: f62bf9a)

## Overview

This document provides comprehensive documentation for the iOS admin interface implementation, detailing all features, API requirements, and cross-platform considerations for backend and web developers to maintain feature parity.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [User Model Changes](#user-model-changes)
3. [Admin Detection & Authorization](#admin-detection--authorization)
4. [API Endpoints Required](#api-endpoints-required)
5. [Feature Specifications](#feature-specifications)
6. [Security Considerations](#security-considerations)
7. [Error Handling](#error-handling)
8. [Testing Criteria](#testing-criteria)

---

## Architecture Overview

### File Structure

```
ios/Cafe/
├── App/
│   ├── AppState.swift                  [Modified] - Added isAdmin property
│   └── RootView.swift                  [Modified] - Added admin section to Settings
├── Core/
│   ├── API/
│   │   └── APIClient+Admin.swift       [New] - Admin API endpoints
│   └── Models/
│       └── Models.swift                [Modified] - Added isAdmin to User model
└── Features/
    └── Admin/                          [New]
        ├── AdminModels.swift           - Admin-specific data models
        ├── AdminView.swift             - Main admin interface
        ├── AdminStatsView.swift        - System statistics dashboard
        ├── UserManagementView.swift    - User administration
        ├── AIClientManagementView.swift - AI client node management
        └── ContentManagementView.swift  - CMS interface
```

### Design Pattern

- **MVVM Architecture**: Views bind to view models, separation of concerns
- **Async/Await**: Modern Swift concurrency for all API calls
- **Observable State**: Uses `@Observable` macro for state management
- **Conditional UI**: Admin sections only visible when `appState.isAdmin == true`
- **Navigation**: Admin panel accessible via Settings > Administration

---

## User Model Changes

### iOS Implementation

**File:** `/ios/Cafe/Core/Models/Models.swift`

```swift
struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let fullName: String?
    let createdAt: Date
    let isAdmin: Bool  // ← NEW FIELD

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case fullName = "full_name"
        case createdAt = "created_at"
        case isAdmin = "is_admin"  // ← NEW KEY
    }
}
```

### Backend Requirements

**Endpoint:** `GET /api/users/me/`

**Response Format:**
```json
{
  "id": 1,
  "username": "admin_user",
  "email": "admin@example.com",
  "full_name": "Admin User",
  "created_at": "2025-01-01T00:00:00Z",
  "is_admin": true  // ← REQUIRED: Boolean flag for admin privileges
}
```

**Database Schema Update:**
```sql
-- Add is_admin column to users table if not exists
ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE NOT NULL;

-- Create index for admin queries
CREATE INDEX idx_users_is_admin ON users(is_admin) WHERE is_admin = true;
```

**Business Logic:**
- Default value for new users: `is_admin = false`
- Only existing admins can promote users to admin
- At least one admin user must exist in the system
- Admin status is returned in all user-related API responses

---

## Admin Detection & Authorization

### iOS Implementation

**File:** `/ios/Cafe/App/AppState.swift`

```swift
class AppState {
    var currentUser: User?

    var isAdmin: Bool {
        currentUser?.isAdmin ?? false
    }
}
```

**Conditional UI Display:**
```swift
// In Settings view
if appState.isAdmin {
    Section("Administration") {
        NavigationLink(destination: AdminView()) {
            Label("Admin Panel", systemImage: "shield.fill")
        }
    }
}
```

### Backend Requirements

**Authorization Check:**
- All admin endpoints MUST verify `is_admin = true` in JWT token or session
- Return HTTP 403 Forbidden if user is not admin
- Log all admin actions for audit trail

**Recommended Middleware (Python/FastAPI):**
```python
from fastapi import Depends, HTTPException, status

async def get_current_admin_user(
    current_user: User = Depends(get_current_user)
) -> User:
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required"
        )
    return current_user

# Usage in routes
@router.get("/admin/stats")
async def get_stats(
    admin: User = Depends(get_current_admin_user)
):
    # Admin endpoint logic
    pass
```

---

## API Endpoints Required

### 1. System Statistics

**Endpoint:** `GET /api/admin/stats`

**Authorization:** Admin only

**Response:**
```json
{
  "total_users": 150,
  "total_tasks": 2340,
  "total_events": 567,
  "total_messages": 8901,
  "active_users": 45,
  "tasks_completed_today": 123,
  "events_today": 12
}
```

**Business Logic:**
- `total_users`: Count of all registered users
- `active_users`: Users with activity in last 24 hours
- `tasks_completed_today`: Tasks marked complete since midnight (server timezone)
- `events_today`: Events scheduled for current date

---

### 2. Server Health

**Endpoint:** `GET /api/admin/health`

**Authorization:** Admin only

**Response:**
```json
{
  "status": "healthy",
  "api_status": "online",
  "database_status": "online",
  "ai_service_status": "online",
  "average_response_time": 45.3,
  "uptime": 864000,
  "timestamp": "2025-11-19T10:30:00Z"
}
```

**Status Values:**
- `"healthy"` | `"degraded"` | `"down"`
- `average_response_time`: milliseconds (double)
- `uptime`: seconds since last restart (integer)

**Health Check Logic:**
- Ping database with simple query
- Check AI service connectivity
- Calculate average response time from last 100 requests
- Return degraded if any service is slow (>2s response)

---

### 3. User Management

#### Get All Users
**Endpoint:** `GET /api/admin/users`

**Response:**
```json
[
  {
    "id": 1,
    "username": "john_doe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "is_admin": false,
    "is_active": true,
    "created_at": "2025-01-01T00:00:00Z",
    "last_login_at": "2025-11-19T09:30:00Z"
  }
]
```

**Query Parameters (Optional):**
- `?is_admin=true` - Filter admin users only
- `?is_active=true` - Filter active users only
- `?limit=100&offset=0` - Pagination

---

#### Get User by ID
**Endpoint:** `GET /api/admin/users/{user_id}`

**Response:** Same as individual user object above

**Error Cases:**
- 404 if user not found
- 403 if not admin

---

#### Update User Role
**Endpoint:** `PUT /api/admin/users/{user_id}/role`

**Request Body:**
```json
{
  "is_admin": true
}
```

**Response:** Updated user object

**Business Logic:**
- Verify requesting user is admin
- Cannot remove admin status from self (prevent lockout)
- Ensure at least one admin exists after operation
- Log role changes with timestamp and performing admin ID

---

#### Update User Status
**Endpoint:** `PUT /api/admin/users/{user_id}/status`

**Request Body:**
```json
{
  "is_active": false
}
```

**Response:** Updated user object

**Business Logic:**
- Inactive users cannot log in
- Cannot deactivate self
- Preserve user data when inactive
- All user sessions should be invalidated on deactivation

---

#### Delete User
**Endpoint:** `DELETE /api/admin/users/{user_id}`

**Response:** 204 No Content

**Business Logic:**
- Soft delete (mark as deleted, preserve data) OR hard delete
- Cannot delete self
- Cannot delete last admin user
- Cascade delete or reassign user's resources (tasks, events, etc.)
- Option to anonymize data for GDPR compliance

---

### 4. AI Client Management

#### List AI Clients
**Endpoint:** `GET /api/admin/ai-clients`

**Response:**
```json
[
  {
    "id": 1,
    "name": "Primary Ollama",
    "node_type": "ollama",
    "hostname": "localhost",
    "port": 11434,
    "is_active": true,
    "is_public": false,
    "status": "online",
    "last_seen_at": "2025-11-19T10:29:00Z",
    "capabilities": {
      "models": "3",
      "version": "0.1.0"
    },
    "node_metadata": {
      "location": "us-west-1"
    },
    "base_url": "http://localhost:11434",
    "owner_id": 1
  }
]
```

**Status Values:** `"online"` | `"offline"` | `"degraded"`

---

#### Create AI Client
**Endpoint:** `POST /api/admin/ai-clients`

**Request Body:**
```json
{
  "name": "New AI Node",
  "node_type": "ollama",
  "hostname": "ai.example.com",
  "port": 11434,
  "is_public": false,
  "node_metadata": {}
}
```

**Response:** Created client object with ID

**Validation:**
- `node_type` must be `"ollama"` or `"openwebui"`
- `hostname` must be valid domain/IP
- `port` must be 1-65535
- Unique constraint on (hostname, port)
- Auto-test connection on creation

---

#### Update AI Client
**Endpoint:** `PUT /api/admin/ai-clients/{client_id}`

**Request Body:**
```json
{
  "name": "Updated Name",
  "is_active": false,
  "is_public": true,
  "node_metadata": {"region": "us-east"}
}
```

**Response:** Updated client object

---

#### Delete AI Client
**Endpoint:** `DELETE /api/admin/ai-clients/{client_id}`

**Response:** 204 No Content

**Business Logic:**
- Remove from load balancer rotation first
- Ensure no active requests to this node
- Clean up associated monitoring data

---

#### Test AI Client Connection
**Endpoint:** `POST /api/admin/ai-clients/{client_id}/test`

**Response:**
```json
{
  "status": "success",
  "online": true,
  "message": "Connection successful",
  "models": ["llama3", "codellama"],
  "model_count": 2,
  "response_time_ms": 123
}
```

**Test Logic:**
- Attempt HTTP connection to node
- Fetch available models list
- Measure response time
- Update `last_seen_at` timestamp
- Update node status based on result

---

#### Get Client Models
**Endpoint:** `GET /api/admin/ai-clients/{client_id}/models`

**Response:**
```json
{
  "models": ["llama3", "codellama", "mixtral"]
}
```

---

#### Health Check All Clients
**Endpoint:** `POST /api/admin/ai-clients/health-check-all`

**Response:**
```json
{
  "results": [
    {
      "node_id": "1",
      "name": "Primary Ollama",
      "status": "success",
      "online": "true",
      "response_time_ms": "145"
    }
  ]
}
```

**Logic:** Run connection test on all active nodes in parallel

---

### 5. Content Management (CMS)

#### Get Site Pages
**Endpoint:** `GET /api/content/admin/pages`

**Response:**
```json
[
  {
    "id": 1,
    "slug": "home",
    "title": "Home Page",
    "summary": "Main landing page",
    "hero_image_url": "https://example.com/hero.jpg",
    "sections": [{"type": "hero", "content": "..."}],
    "nav_links": [{"text": "Home", "url": "/"}],
    "theme": "default",
    "is_published": true,
    "owner_id": 1,
    "updated_by_id": 1,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-11-19T10:00:00Z"
  }
]
```

---

#### Get Photo Albums
**Endpoint:** `GET /api/content/admin/photo-albums`

**Response:**
```json
[
  {
    "id": 1,
    "slug": "vacation-2025",
    "title": "Vacation 2025",
    "description": "Summer vacation photos",
    "cover_image_url": "https://example.com/cover.jpg",
    "hero_text": "Summer Adventures",
    "photos": [
      {"url": "https://example.com/1.jpg", "caption": "Beach day"}
    ],
    "is_public": true,
    "owner_id": 1,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-11-19T10:00:00Z"
  }
]
```

---

#### Get Blog Posts
**Endpoint:** `GET /api/content/admin/blog-posts`

**Response:**
```json
[
  {
    "id": 1,
    "slug": "my-first-post",
    "title": "My First Post",
    "excerpt": "Introduction to the blog",
    "content": "Full blog post content in markdown...",
    "cover_image_url": "https://example.com/post.jpg",
    "author_name": "John Doe",
    "is_published": true,
    "published_at": "2025-11-19T10:00:00Z",
    "owner_id": 1,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-11-19T10:00:00Z"
  }
]
```

---

### 6. System Actions

#### Clear Cache
**Endpoint:** `POST /api/admin/cache/clear`

**Response:**
```json
{
  "status": "success",
  "message": "Cache cleared successfully",
  "items_cleared": 1234
}
```

**Logic:**
- Clear Redis/Memcached cache
- Clear application-level caches
- Clear CDN cache (if applicable)
- Return count of items cleared

---

#### Rebuild Frontend
**Endpoint:** `POST /api/admin/rebuild-frontend`

**Response:**
```json
{
  "status": "success",
  "message": "Frontend rebuilt successfully",
  "output": "Build completed in 45s..."
}
```

**Logic:**
- Trigger `npm run build` in frontend directory
- Return build output (truncated to last 500 chars)
- Timeout after 5 minutes
- Run in background job queue for large builds

**Note:** This endpoint already exists in backend (commit f62bf9a)

---

#### Rebuild Indexes
**Endpoint:** `POST /api/admin/rebuild-indexes`

**Response:**
```json
{
  "status": "success",
  "message": "Indexes rebuilt successfully"
}
```

**Logic:**
- Rebuild database indexes
- Rebuild search indexes (Elasticsearch, etc.)
- Optimize database tables
- Run in background job queue

---

## Feature Specifications

### 1. Admin Dashboard (AdminStatsView)

**User Flow:**
1. Admin navigates to Settings > Administration > Admin Panel
2. Views system statistics dashboard
3. Sees server health status with color-coded indicators
4. Can pull-to-refresh to update stats
5. Views recent activity metrics

**UI Components:**
- Server health section (API, DB, AI service status)
- System overview (user count, task count, event count, message count)
- Recent activity (active users, tasks completed today, events today)
- Last updated timestamp
- Pull-to-refresh functionality

**Data Refresh:**
- Auto-refresh on view appear
- Manual refresh via toolbar button
- Pull-to-refresh gesture

---

### 2. User Management (UserManagementView)

**User Flow:**
1. Navigate to Admin Panel > User Management
2. View list of all users with search functionality
3. Tap user to view detailed information
4. Grant/revoke admin privileges
5. Activate/deactivate accounts
6. Delete users (with confirmation)

**Search Functionality:**
- Filter by username, email, or full name
- Case-insensitive search
- Real-time filtering

**User Details:**
- Username, email, full name
- Admin status badge
- Active/inactive status
- Join date and last login
- Actions: Change role, toggle status, delete

**Confirmation Dialogs:**
- Role change: "Grant/Remove admin access to [username]?"
- Delete user: "Delete [username]? This cannot be undone."
- Self-action prevention: Cannot modify own status or delete self

---

### 3. AI Client Management (AIClientManagementView)

**User Flow:**
1. Navigate to Admin Panel > AI Client Nodes
2. View list of configured AI nodes
3. See online/offline status for each node
4. Test connections individually or all at once
5. View detailed node information
6. Manage node configurations

**Node Status Indicators:**
- Green circle: Online
- Red circle: Offline
- Yellow circle: Degraded
- Gray circle: Unknown/Inactive

**Node Details:**
- Name, type (Ollama/OpenWebUI), hostname, port
- Base URL, status, last seen timestamp
- Available models list
- Connection test results (response time, model count)
- Active/inactive toggle
- Public/private visibility

**Actions:**
- Test connection
- Refresh models list
- Delete node (with confirmation)

---

### 4. Content Management (ContentManagementView)

**User Flow:**
1. Navigate to Admin Panel > Content Management
2. Switch between three tabs: Pages, Albums, Blog
3. View list of content items with publish status
4. See content statistics (total, published count)
5. Pull-to-refresh to update content lists

**Pages Tab:**
- List all site pages with slug, title, summary
- Show theme and published status
- Display last updated timestamp
- Badge for published/draft status

**Albums Tab:**
- List photo albums with slug, title
- Show photo count
- Public/private indicator
- Last updated timestamp

**Blog Tab:**
- List blog posts with slug, title, excerpt
- Show author name
- Published/draft status
- Published date or "Draft" label

**Note:** Current implementation is read-only. Full CRUD operations (create/update/delete) can be added in future iterations.

---

## Security Considerations

### iOS Security

**1. Authorization Checks:**
```swift
// Always check admin status before showing UI
if appState.isAdmin {
    // Show admin features
}
```

**2. Token Management:**
- Admin tokens stored securely in Keychain
- Auto-logout on 401 Unauthorized
- Session validation on app launch

**3. Secure Communication:**
- All admin API calls use HTTPS in production
- Bearer token authentication on all requests
- Request/response logging for debugging (dev only)

### Backend Security

**1. Authentication & Authorization:**
- JWT tokens with `is_admin` claim
- Middleware to verify admin status on all admin routes
- Rate limiting on admin endpoints to prevent abuse

**2. Audit Logging:**
```python
# Log all admin actions
async def log_admin_action(
    admin_id: int,
    action: str,
    target: str,
    result: str
):
    await db.execute(
        "INSERT INTO admin_audit_log (admin_id, action, target, result, timestamp) "
        "VALUES ($1, $2, $3, $4, NOW())",
        admin_id, action, target, result
    )

# Example usage
await log_admin_action(
    admin_id=admin.id,
    action="UPDATE_USER_ROLE",
    target=f"user_id={user_id}",
    result="success"
)
```

**3. Input Validation:**
- Sanitize all user inputs
- Validate user IDs, client IDs exist before operations
- Prevent SQL injection with parameterized queries
- Validate enum values (status, node_type, etc.)

**4. Protection Against Common Attacks:**
- CSRF tokens for state-changing operations
- SQL injection prevention (use ORMs)
- XSS prevention (sanitize HTML content)
- Rate limiting per IP address
- Admin IP whitelist (optional, for high-security environments)

---

## Error Handling

### iOS Error Handling

**Pattern:**
```swift
@MainActor
private func performAction() async {
    isLoading = true
    errorMessage = nil

    do {
        let result = try await APIClient.shared.adminAction()
        // Handle success
    } catch let error as APIError {
        // Handle specific API errors
        switch error {
        case .unauthorized:
            errorMessage = "Admin access required"
        case .serverError(let message):
            errorMessage = message
        default:
            errorMessage = error.localizedDescription
        }
    } catch {
        errorMessage = "An unexpected error occurred"
    }

    isLoading = false
}
```

**User-Friendly Error Messages:**
- "Admin access required" (403 Forbidden)
- "Session expired. Please login again." (401 Unauthorized)
- "User not found" (404 Not Found)
- "Cannot perform action on yourself"
- "At least one admin must exist"

### Backend Error Responses

**Standard Error Format:**
```json
{
  "detail": "User-friendly error message",
  "error_code": "ADMIN_REQUIRED",
  "timestamp": "2025-11-19T10:30:00Z"
}
```

**HTTP Status Codes:**
- 200 OK - Success
- 204 No Content - Successful deletion
- 400 Bad Request - Invalid input
- 401 Unauthorized - Not authenticated
- 403 Forbidden - Not admin
- 404 Not Found - Resource doesn't exist
- 500 Internal Server Error - Server error
- 503 Service Unavailable - Service down

---

## Testing Criteria

### Unit Tests (iOS)

**Models:**
- [ ] User model correctly decodes `is_admin` field
- [ ] AppState.isAdmin returns false when user is nil
- [ ] AppState.isAdmin returns correct value based on currentUser

**API Client:**
- [ ] Admin endpoints use correct HTTP methods
- [ ] Authorization header included in all requests
- [ ] Error handling for 401/403/404 responses
- [ ] Request body encoding for update operations

### Integration Tests (Backend)

**Authorization:**
- [ ] Non-admin users receive 403 on admin endpoints
- [ ] Admin users can access all admin endpoints
- [ ] Unauthenticated requests receive 401

**User Management:**
- [ ] List all users returns complete user list
- [ ] Update user role changes admin status
- [ ] Cannot delete last admin user
- [ ] Cannot deactivate self
- [ ] Deleted users are properly cleaned up

**AI Client Management:**
- [ ] Create client with valid data succeeds
- [ ] Duplicate hostname/port returns error
- [ ] Connection test updates node status
- [ ] Health check all processes multiple nodes

**System Actions:**
- [ ] Clear cache actually clears cached data
- [ ] Rebuild frontend triggers build process
- [ ] Long-running actions have proper timeouts

### UI Tests (iOS)

**Admin Access:**
- [ ] Admin section hidden when user is not admin
- [ ] Admin section visible when user is admin
- [ ] Navigation to admin views works correctly

**User Management:**
- [ ] Search filters users correctly
- [ ] User detail view displays all information
- [ ] Role change confirmation dialog appears
- [ ] Delete confirmation dialog appears
- [ ] Actions disabled during loading

**Error Handling:**
- [ ] Error messages display correctly
- [ ] Network errors handled gracefully
- [ ] Loading indicators appear during operations
- [ ] Pull-to-refresh works on all list views

---

## Cross-Platform Considerations

### iOS vs Web Differences

**1. Navigation:**
- **iOS:** Tab-based navigation, Settings > Administration
- **Web:** Sidebar navigation, dedicated /admin route

**2. UI Patterns:**
- **iOS:** Native SwiftUI components, iOS design patterns
- **Web:** React components, web design patterns
- **Recommendation:** Both should follow their platform conventions while maintaining functional parity

**3. Real-time Updates:**
- **iOS:** Pull-to-refresh, manual refresh button
- **Web:** Can use WebSockets for real-time updates, auto-refresh
- **Recommendation:** Backend should support both polling and WebSocket patterns

**4. Offline Support:**
- **iOS:** Can cache admin data locally, show last known state when offline
- **Web:** Typically requires connection, can show connection status
- **Recommendation:** Admin operations require connection, read-only views can cache

### API Design Best Practices

**1. Consistent Response Format:**
- Use same field names across all platforms
- Use snake_case for JSON keys (Python convention)
- Always include timestamp fields as ISO 8601 strings

**2. Pagination:**
```json
{
  "items": [...],
  "total": 150,
  "page": 1,
  "per_page": 50,
  "pages": 3
}
```

**3. Filtering & Sorting:**
- Query parameters: `?is_admin=true&sort=created_at&order=desc`
- Support common filters across platforms

**4. Versioning:**
- Include API version in URL: `/api/v1/admin/...`
- Maintain backward compatibility for at least 2 versions

---

## Future Enhancements

### Phase 2 Features (Recommended)

1. **Full CMS CRUD Operations:**
   - Create/edit/delete pages, albums, blog posts
   - Rich text editor for blog content
   - Image upload and management

2. **Advanced User Management:**
   - Bulk user operations (activate/deactivate multiple)
   - User roles beyond admin (moderator, editor, etc.)
   - Permission management system

3. **System Monitoring:**
   - Real-time server metrics dashboard
   - Error log viewer
   - API request logs and analytics
   - Resource usage graphs (CPU, memory, disk)

4. **AI Client Advanced Features:**
   - Model pulling and deletion
   - Load balancing configuration
   - Performance metrics per node
   - Auto-failover configuration

5. **Notification System:**
   - Admin notifications for system events
   - Push notifications for critical alerts
   - Email notifications for admin actions

6. **Backup & Restore:**
   - Database backup triggers
   - System configuration export/import
   - Disaster recovery tools

---

## Support & Maintenance

### Contact

- **iOS Developer:** iOS Agent
- **Backend Team:** Halext Org Backend Team
- **Documentation:** This file + inline code comments

### Version History

- **v1.0.0** (2025-11-19): Initial admin interface implementation
  - User management
  - AI client management
  - Content management (read-only)
  - System statistics and health monitoring
  - Basic system actions (cache clear, frontend rebuild)

---

## Appendix: Complete API Endpoint Summary

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/users/me/` | Get current user (includes is_admin) | User |
| GET | `/api/admin/stats` | System statistics | Admin |
| GET | `/api/admin/health` | Server health check | Admin |
| GET | `/api/admin/users` | List all users | Admin |
| GET | `/api/admin/users/{id}` | Get user by ID | Admin |
| PUT | `/api/admin/users/{id}/role` | Update user role | Admin |
| PUT | `/api/admin/users/{id}/status` | Update user status | Admin |
| DELETE | `/api/admin/users/{id}` | Delete user | Admin |
| GET | `/api/admin/ai-clients` | List AI clients | Admin |
| POST | `/api/admin/ai-clients` | Create AI client | Admin |
| GET | `/api/admin/ai-clients/{id}` | Get AI client | Admin |
| PUT | `/api/admin/ai-clients/{id}` | Update AI client | Admin |
| DELETE | `/api/admin/ai-clients/{id}` | Delete AI client | Admin |
| POST | `/api/admin/ai-clients/{id}/test` | Test connection | Admin |
| GET | `/api/admin/ai-clients/{id}/models` | Get models | Admin |
| POST | `/api/admin/ai-clients/health-check-all` | Test all nodes | Admin |
| GET | `/api/content/admin/pages` | List site pages | Admin |
| GET | `/api/content/admin/photo-albums` | List photo albums | Admin |
| GET | `/api/content/admin/blog-posts` | List blog posts | Admin |
| POST | `/api/admin/cache/clear` | Clear cache | Admin |
| POST | `/api/admin/rebuild-frontend` | Rebuild frontend | Admin |
| POST | `/api/admin/rebuild-indexes` | Rebuild indexes | Admin |

---

**End of Documentation**
