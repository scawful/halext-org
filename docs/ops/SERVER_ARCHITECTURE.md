# Halext Org Server Architecture

## Overview

The Halext Org backend is a FastAPI application that serves as the API server for the web frontend, iOS app, and other clients. This document explains how the server is structured, how routing works, and how it integrates with the production infrastructure.

## Architecture Components

### 1. Backend Application (FastAPI)

**Location**: `backend/main.py`  
**Port**: `8000` (development), `8000` (production, behind nginx)  
**Framework**: FastAPI (Python)

The backend is organized into modular routers:

#### Router Structure

```
/api/                          # All API endpoints use /api prefix
├── /token                     # Authentication (POST)
├── /users/                    # User management
│   ├── /                      # List/search users
│   ├── /me/                   # Current user
│   └── /                      # Create user (POST)
├── /tasks/                    # Task management
├── /events/                   # Calendar events
├── /labels/                   # Task labels
├── /pages/                    # Custom pages
├── /conversations/            # Messaging
├── /finance/                  # Financial tracking
├── /social/                   # Social features
├── /ai/                       # AI features
│   ├── /chat                  # Chat endpoint
│   ├── /chat/stream           # Streaming chat
│   ├── /tasks/suggest         # Task suggestions
│   └── ...
├── /admin/                    # Admin endpoints (admin only)
│   ├── /ai-clients            # AI client management
│   ├── /server/status         # Server status
│   └── ...
├── /content/                  # Content management
├── /api/v1/                   # Legacy AI routes (image generation)
├── /health                    # Health check
└── /version                   # API version info
```

#### Router Prefixes

All routers are mounted with the `/api` prefix in `main.py`:

```python
# New modular routers (all have /api prefix)
app.include_router(users.router, prefix="/api")
app.include_router(tasks.router, prefix="/api")
app.include_router(events.router, prefix="/api")
# ... etc

# Legacy routers (also have /api prefix)
app.include_router(admin_router, prefix="/api")      # Router has /admin prefix → /api/admin/*
app.include_router(content_router, prefix="/api")     # Router has /content prefix → /api/content/*
app.include_router(ai_router_legacy, prefix="/api/v1")  # → /api/v1/*
```

**Important**: The `/api` prefix is applied at the application level, not in individual router files. This ensures consistency across all endpoints.

#### Special Endpoints (No Router)

Some endpoints are defined directly in `main.py`:

- `/ws/{conversation_id}` - WebSocket endpoint for real-time messaging
- `/ws/health` - WebSocket health check
- `/api/health` - HTTP health check
- `/api/version` - API version information

### 2. Reverse Proxy (Nginx)

**Purpose**: Routes HTTP/HTTPS traffic to the FastAPI backend  
**Configuration**: `/etc/nginx/sites-enabled/halext-org` (or similar)

#### Production Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name org.halext.org;

    # API proxy - forwards /api/* to backend
    location /api/ {
        proxy_pass http://localhost:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Frontend static files
    location / {
        root /srv/halext.org/halext-org/frontend/dist;
        try_files $uri $uri/ /index.html;
    }
}
```

**Key Points**:
- Nginx receives requests at `https://org.halext.org/api/*`
- Nginx forwards to `http://localhost:8000/api/*` (keeps the `/api` prefix)
- Backend expects requests at `/api/*` (matches what nginx sends)
- Frontend static files are served directly by nginx

#### Alternative Configuration (Strips Prefix)

Some configurations strip the `/api` prefix:

```nginx
location /api/ {
    proxy_pass http://127.0.0.1:8000/;  # Note: no /api/ in proxy_pass
}
```

**If using this configuration**: Backend routers should NOT have `/api` prefix, or you need to adjust the nginx config to match.

### 3. Client Configuration

#### iOS App

**File**: `ios/Cafe/Core/API/APIClient.swift`

```swift
enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "http://127.0.0.1:8000/api"  // Direct to backend with /api
        case .production:
            return "https://org.halext.org/api"  // Through nginx with /api
        }
    }
}
```

**Endpoints**: All endpoints are relative to `baseURL`:
- `baseURL + "/tasks/"` → `http://127.0.0.1:8000/api/tasks/` (dev)
- `baseURL + "/tasks/"` → `https://org.halext.org/api/tasks/` (prod)

#### Web Frontend

**File**: `frontend/src/utils/helpers.ts`

```typescript
const API_BASE_URL = resolvedApiBase  // e.g., "https://org.halext.org/api" or "http://127.0.0.1:8000/api"
```

**Endpoints**: All endpoints use `API_BASE_URL` as prefix:
- `fetch(`${API_BASE_URL}/tasks/`)` → Full URL with `/api` prefix

## Request Flow

### Development Flow

```
iOS App / Frontend
    ↓
http://127.0.0.1:8000/api/tasks/
    ↓
FastAPI Backend (port 8000)
    ↓
Router: /api/tasks/ → tasks.router
    ↓
Handler: GET /tasks/ → list_tasks()
    ↓
Response: JSON
```

### Production Flow

```
iOS App / Frontend
    ↓
https://org.halext.org/api/tasks/
    ↓
Nginx (port 443)
    ↓
proxy_pass → http://localhost:8000/api/tasks/
    ↓
FastAPI Backend (port 8000)
    ↓
Router: /api/tasks/ → tasks.router
    ↓
Handler: GET /tasks/ → list_tasks()
    ↓
Response: JSON
    ↓
Nginx → Client
```

## Endpoint Path Resolution

### Example: Getting Tasks

1. **Client Request**: `GET /tasks/` (relative to baseURL)
2. **Full URL (Dev)**: `http://127.0.0.1:8000/api/tasks/`
3. **Full URL (Prod)**: `https://org.halext.org/api/tasks/`
4. **Nginx (Prod)**: Forwards to `http://localhost:8000/api/tasks/`
5. **FastAPI**: Matches router with prefix `/api` → `tasks.router`
6. **Router**: Matches `GET /tasks/` → `list_tasks()` handler
7. **Response**: JSON array of tasks

### Router Prefix Resolution

When a router is included with a prefix:

```python
app.include_router(tasks.router, prefix="/api")
```

And the router defines:

```python
@router.get("/tasks/")
def list_tasks():
    ...
```

The final endpoint path is: `/api` (prefix) + `/tasks/` (route) = `/api/tasks/`

## WebSocket Endpoints

WebSocket endpoints are handled differently:

- **Endpoint**: `/ws/{conversation_id}` (no `/api` prefix)
- **Purpose**: Real-time messaging for conversations
- **Client Connection**: 
  - Dev: `ws://127.0.0.1:8000/ws/{conversation_id}`
  - Prod: `wss://org.halext.org/ws/{conversation_id}` (requires nginx WebSocket config)

**Note**: WebSocket endpoints bypass the `/api` prefix because they're defined directly in `main.py` and serve a different purpose than REST API endpoints.

## Health Checks

### HTTP Health Check

- **Endpoint**: `/api/health`
- **Purpose**: Monitor backend status
- **Response**: JSON with status, version, database health, AI provider info

### WebSocket Health Check

- **Endpoint**: `/ws/health`
- **Purpose**: Monitor WebSocket connections
- **Response**: JSON with active conversation counts

## Environment Differences

### Development

- Backend runs directly on `http://127.0.0.1:8000`
- No nginx proxy
- Clients connect directly to backend
- All endpoints accessible at `/api/*`

### Production

- Backend runs on `http://localhost:8000` (not publicly accessible)
- Nginx proxy handles HTTPS and routing
- Clients connect through `https://org.halext.org`
- All API endpoints at `/api/*` are proxied to backend

## Troubleshooting

### Endpoint Not Found (404)

1. **Check router prefix**: Ensure router is included with `/api` prefix in `main.py`
2. **Check route path**: Verify the route decorator path matches the expected URL
3. **Check nginx config**: Verify `proxy_pass` includes `/api/` in the URL
4. **Test directly**: `curl http://localhost:8000/api/health` (should work if backend is running)

### CORS Errors

- Backend has CORS middleware configured to allow all origins
- If issues persist, check nginx headers and backend CORS settings

### WebSocket Connection Failed

- Verify nginx has WebSocket upgrade headers configured
- Check that WebSocket endpoint doesn't require `/api` prefix
- Test with: `wscat -c ws://localhost:8000/ws/test123`

## Configuration Files

- **Backend**: `backend/main.py` - Router configuration
- **Nginx**: `/etc/nginx/sites-enabled/halext-org` - Reverse proxy config
- **iOS**: `ios/Cafe/Core/API/APIClient.swift` - Base URL configuration
- **Frontend**: `frontend/src/utils/helpers.ts` - API base URL

## Deployment Checklist

When deploying changes:

1. ✅ Verify all routers have `/api` prefix in `main.py`
2. ✅ Verify nginx `proxy_pass` includes `/api/` in URL
3. ✅ Verify iOS baseURL includes `/api` for both dev and prod
4. ✅ Verify frontend `API_BASE_URL` includes `/api`
5. ✅ Test health endpoint: `curl https://org.halext.org/api/health`
6. ✅ Test a sample endpoint: `curl https://org.halext.org/api/tasks/` (with auth)
7. ✅ Check nginx logs: `/var/log/nginx/halext-error.log`
8. ✅ Check backend logs: `journalctl -u halext-api -f`

## Summary

- **All API endpoints use `/api` prefix** for consistency
- **Routers are mounted with `/api` prefix** in `main.py`
- **Nginx forwards `/api/*` to backend** keeping the prefix
- **Clients use baseURL with `/api`** included
- **WebSocket endpoints** are at `/ws/*` (no `/api` prefix)
- **Health checks** are at `/api/health` and `/ws/health`

This architecture ensures consistent endpoint paths across development and production environments.

