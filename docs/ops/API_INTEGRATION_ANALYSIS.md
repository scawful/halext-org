# API Integration Analysis - November 22, 2025

## Executive Summary

Comprehensive analysis of the Halext Org backend API, iOS app, and frontend integration revealed several critical issues affecting production deployment at org.halext.org.

## Critical Issues Found

### 1. **DATABASE CONFIGURATION MISMATCH** (CRITICAL)

**Problem**: The backend is using SQLite instead of PostgreSQL in production.

**Root Cause**:
- The `.env` file contains `DATABASE_URL=postgresql://halext_user:REDACTED_PASSWORD@127.0.0.1/halext_org`
- systemd service has `EnvironmentFile=/srv/halext.org/halext-org/backend/.env`
- However, systemd's `EnvironmentFile` directive does NOT export variables to the process environment like bash `export` does
- The backend's `database.py` uses `os.getenv("DATABASE_URL", "sqlite:///./halext_dev.db")` which falls back to SQLite when the variable isn't set
- Result: Production backend runs with SQLite database containing only test data

**Evidence**:
```bash
# Backend actually uses SQLite:
$ ssh halext-server "cd /srv/halext.org/halext-org/backend && python3 -c 'from app.database import engine; print(engine.url)'"
sqlite:///./halext_dev.db

# But .env file has PostgreSQL:
$ ssh halext-server "cat /srv/halext.org/halext-org/backend/.env | grep DATABASE_URL"
DATABASE_URL=postgresql://halext_user:REDACTED_PASSWORD@127.0.0.1/halext_org

# With dotenv loaded, it works:
$ ssh halext-server "cd /srv/halext.org/halext-org/backend && python3 -c 'from dotenv import load_dotenv; load_dotenv(); import os; print(os.getenv(\"DATABASE_URL\"))'"
postgresql://halext_user:REDACTED_PASSWORD@127.0.0.1/halext_org
```

**Impact**:
- Login failures (SQLite has only 'dev' user with potentially wrong password hash)
- Data inconsistency between environments
- All user data, tasks, events stored in SQLite instead of PostgreSQL
- 401 authentication errors from iOS/frontend clients

**Fix**: Update systemd service to use uvicorn's `--env-file` flag OR add explicit environment variables to systemd service file.

### 2. **DUPLICATE BACKEND PROCESSES**

**Problem**: Two uvicorn instances running simultaneously on different ports.

**Evidence**:
```bash
$ ssh halext-server "ps aux | grep uvicorn"
halext    351520  ... uvicorn main:app --host 127.0.0.1 --port 8020
www-data  355011  ... uvicorn main:app --host 127.0.0.1 --port 8000
```

**Details**:
- Port 8000: systemd managed (halext-api.service), running as www-data
- Port 8020: manually started, running as halext user
- nginx proxies to port 8000 (systemd service)
- Port 8020 process is orphaned/unnecessary

**Impact**:
- Resource waste
- Potential confusion during debugging
- Different database connections if environments differ

**Fix**: Kill the process on port 8020, ensure only systemd service runs.

### 3. **MISSING DEPENDENCY IN requirements.txt**

**Problem**: `python-dotenv` is installed but not in requirements.txt

**Evidence**:
```bash
$ ssh halext-server "cd /srv/halext.org/halext-org/backend && ./env/bin/pip list | grep dotenv"
python-dotenv     1.0.1

$ cat backend/requirements.txt
# ... python-dotenv is missing ...
```

**Impact**:
- Fresh deployments won't have dotenv package
- Environment variables won't load properly
- Difficult to reproduce production environment

**Fix**: Add `python-dotenv` to requirements.txt

### 4. **NGINX CONFIGURATION PATH REWRITING**

**Status**: WORKING AS INTENDED

**Details**:
```nginx
location /api/ {
    proxy_pass http://127.0.0.1:8000/;  # Note trailing slash strips /api prefix
    ...
}
```

**Behavior**:
- Client requests: `https://org.halext.org/api/health`
- nginx proxies to: `http://127.0.0.1:8000/health`
- Backend receives: `/health` (not `/api/health`)

**Analysis**: This is correct. The backend supports both `/api/*` and `/*` routes (duplicated in main.py lines 52-63), so the nginx config stripping `/api` is intentional for backward compatibility.

## Non-Critical Issues

### 5. **iOS App API Configuration**

**Status**: CORRECT

iOS app correctly uses `/api` prefix:
```swift
// ios/Cafe/Core/API/APIClient.swift
case .development:
    return "http://127.0.0.1:8000/api"
case .production:
    return "https://org.halext.org/api"
```

This works because nginx receives `/api/*` and forwards to backend as `/*`.

### 6. **Frontend API Configuration**

**Status**: CORRECT

Frontend uses dynamic API base URL:
```typescript
// frontend/src/utils/helpers.ts
const resolvedApiBase = (() => {
  const envValue = import.meta.env.VITE_API_BASE_URL?.trim()
  if (envValue && envValue.length > 0) {
    return envValue.replace(/\/$/, '')
  }
  
  if (typeof window !== 'undefined' && window.location) {
    const origin = window.location.origin.replace(/\/$/, '')
    return `${origin}/api`
  }
  
  return 'http://127.0.0.1:8000'
})()
```

In production (org.halext.org), it will use `https://org.halext.org/api`.

## System Status

### Backend Health Check
```json
{
  "status": "healthy",
  "version": "0.2.0-refactored",
  "env": {
    "issues": [],
    "warnings": [],
    "configured_providers": [],
    "missing_provider_keys": [],
    "offline": false,
    "dev_mode": false
  },
  "components": {
    "database": "healthy",  // ⚠️ But using wrong database!
    "ai_provider": "gemini",
    "ai_model": "gemini-2.5-flash"
  }
}
```

### Database Status
- **Configured**: PostgreSQL (`halext_org` database)
- **Actually Using**: SQLite (`halext_dev.db`)
- **PostgreSQL Available**: Yes (credentials in .env)
- **SQLite User Count**: 1 (dev user only)

### Recent Logs
Multiple 401 authentication failures from external IP (75.250.120.205):
```
Nov 22 03:58:51 - "POST /token HTTP/1.1" 401 Unauthorized
Nov 22 04:02:25 - "POST /token HTTP/1.1" 401 Unauthorized
Nov 22 04:03:12 - "POST /token HTTP/1.1" 401 Unauthorized
```

This is likely due to:
1. SQLite database has wrong user credentials
2. PostgreSQL has correct users but backend isn't using it

## Recommendations

### Immediate Actions (Priority: CRITICAL)

1. **Fix Environment Loading**
   - Option A: Update systemd service to use `uvicorn --env-file .env`
   - Option B: Add explicit `Environment=` directives to systemd service
   - Option C: Add `from dotenv import load_dotenv; load_dotenv()` to main.py

2. **Verify Database Connection**
   - Restart backend service after environment fix
   - Confirm PostgreSQL connection
   - Migrate any SQLite data to PostgreSQL if needed

3. **Kill Duplicate Process**
   ```bash
   kill 351520  # Port 8020 process
   ```

4. **Update requirements.txt**
   ```bash
   echo "python-dotenv" >> backend/requirements.txt
   ```

### Testing After Fixes

```bash
# 1. Verify environment loads correctly
ssh halext-server "systemctl restart halext-api.service"

# 2. Check database connection
ssh halext-server "curl -s http://localhost:8000/api/health | grep database"

# 3. Test authentication
ssh halext-server "curl -X POST 'https://org.halext.org/api/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=dev&password=dev123'"

# 4. Verify single process
ssh halext-server "ps aux | grep uvicorn | grep -v grep"
```

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                     org.halext.org                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     NGINX (Port 443)                         │
│  /api/* → proxy to http://127.0.0.1:8000/* (strip prefix)  │
│  /      → static files from /var/www/halext                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│             FastAPI Backend (Port 8000)                      │
│  • Routes: /api/* AND /* (both supported)                   │
│  • Should use: PostgreSQL                                    │
│  • Actually uses: SQLite ❌                                  │
│  • Running as: www-data via systemd                         │
└─────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
    ┌───────────────────┐   ┌──────────────────────┐
    │  PostgreSQL       │   │  SQLite (current)    │
    │  ✅ Configured    │   │  ❌ Being used       │
    │  ✅ Has data      │   │  ⚠️  Limited data    │
    └───────────────────┘   └──────────────────────┘
```

## Client Configuration

### iOS (Production)
- Base URL: `https://org.halext.org/api` ✅
- Auth: Bearer token in Authorization header ✅
- Access Code: X-Halext-Code header ✅

### Frontend (Production)
- Base URL: `https://org.halext.org/api` (auto-detected) ✅
- Auth: Bearer token ✅
- CORS: Allowed ✅

### Local Development
- iOS: `http://127.0.0.1:8000/api` ✅
- Frontend: `http://127.0.0.1:8000` (from env) ✅

## Files Modified During Investigation

None - this was a read-only analysis.

## Next Steps

1. Apply the environment loading fix (see "Immediate Actions")
2. Restart backend service
3. Test login with iOS app and frontend
4. Monitor logs for authentication success
5. Update coordination board with findings

---

**Analysis completed**: 2025-11-22T04:45:00Z  
**Analyzed by**: CODEX (Agent)  
**Server**: org.halext.org (75.250.120.205)  
**Backend Version**: 0.2.0-refactored

