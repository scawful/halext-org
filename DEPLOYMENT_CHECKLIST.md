# AI Routing Deployment Checklist

**Date:** 2025-11-19
**Feature:** Comprehensive AI Model Routing Implementation
**Commits:** d8f572b, 3407c36, dba31cf, 6a1d06d

---

## Pre-Deployment Verification

### ✅ Completed
- [x] Backend modules import successfully
- [x] Frontend builds without TypeScript errors
- [x] Database migration created and tested locally
- [x] All code committed to main branch
- [x] Documentation updated and committed
- [x] 4 feature commits created with proper commit messages

### ⚠️ Known Issues
- [ ] iOS deployment target needs adjustment (build configuration)
- [ ] Test suite authentication dependencies need fixing (non-blocking)

---

## Backend Deployment Steps

### 1. SSH to Server
```bash
ssh halext-server
cd /var/www/halext-org
```

### 2. Pull Latest Code
```bash
git fetch origin
git pull origin main
```

### 3. Activate Virtual Environment
```bash
cd backend
source env/bin/activate
```

### 4. Install Dependencies
```bash
pip install -r requirements.txt
```

### 5. Apply Database Migration
```bash
python -m migrations.add_conversation_default_model
```

**Expected Output:**
```
Running migration: Add default_model_id to conversations
Successfully added default_model_id column to conversations table
```

### 6. Restart Backend Service
```bash
sudo systemctl restart halext-api
sudo systemctl status halext-api
```

### 7. Verify Backend Health
```bash
curl -I http://localhost:8000/health
# Expected: 200 OK

curl http://localhost:8000/ai/models
# Expected: Unauthorized (requires auth)
```

---

## Frontend Deployment Steps

### 1. Build Frontend (on server or locally)

**Option A: Build on Server**
```bash
cd /var/www/halext-org/frontend
npm install
npm run build
```

**Option B: Build Locally and SCP**
```bash
cd /Users/scawful/Code/halext-org/frontend
npm run build
scp -r dist/* halext-server:/var/www/halext-org/frontend/dist/
```

### 2. Reload Nginx
```bash
sudo systemctl reload nginx
sudo systemctl status nginx
```

### 3. Clear CDN Cache (if applicable)
```bash
# Cloudflare purge or similar
```

---

## Post-Deployment Verification

### Backend API Tests

1. **AI Models Endpoint**
```bash
# Get auth token first
TOKEN=$(curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"your_user","password":"your_pass"}' \
  | jq -r '.access_token')

# Test models endpoint
curl http://localhost:8000/ai/models \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:** JSON with `models`, `provider`, `current_model`, `default_model_id` fields

2. **Chat with Model Selection**
```bash
curl -X POST http://localhost:8000/ai/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Test message",
    "model": "openai:gpt-4o-mini"
  }'
```

**Expected:** Response with model routing information

3. **Task Suggestions with Model**
```bash
curl -X POST http://localhost:8000/ai/tasks/suggest \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test task",
    "description": "Test description",
    "model": "openai:gpt-4o-mini"
  }'
```

**Expected:** Task suggestions response

4. **Usage Logging Verification**
```bash
# Check database for usage logs
psql halext_db -c "SELECT * FROM ai_usage_logs ORDER BY created_at DESC LIMIT 5;"
```

**Expected:** Recent AI usage entries with model_identifier, user_id, conversation_id

---

### Frontend Web App Tests

1. **Model Selector Visibility**
   - Navigate to AI Chat section
   - Verify model dropdown appears in header
   - Select different models and verify selection persists

2. **Settings Section**
   - Navigate to Settings
   - Verify AI Settings section exists
   - Test "Disable Cloud Providers" toggle
   - Test "Reset to Default" button

3. **Admin Panel**
   - Navigate to Admin → AI Clients
   - Verify "Show Models" button appears for each client
   - Test "Copy ID" functionality for model identifiers

4. **Chat Functionality**
   - Send a message in AI Chat
   - Verify model chip displays (e.g., "AI • openai:gpt-4o-mini")
   - Switch models and send another message
   - Verify new model is used

5. **Task Assistant**
   - Create a new task
   - Use AI Task Assistant
   - Verify model selector appears
   - Get suggestions and verify they work

---

### Database Verification

```sql
-- Check conversation model field exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'conversations' AND column_name = 'default_model_id';

-- Check AI usage logs table exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'ai_usage_logs';

-- Verify some conversations exist
SELECT id, title, default_model_id FROM conversations LIMIT 5;
```

---

## Monitoring

### What to Monitor

1. **Error Logs**
```bash
# Backend errors
sudo journalctl -u halext-api -f

# Nginx errors
sudo tail -f /var/log/nginx/error.log
```

2. **AI Usage Patterns**
```sql
-- Model usage distribution
SELECT model_identifier, COUNT(*) as usage_count
FROM ai_usage_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY model_identifier
ORDER BY usage_count DESC;

-- Average latency by model
SELECT model_identifier, AVG(latency_ms) as avg_latency
FROM ai_usage_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY model_identifier;
```

3. **Performance Metrics**
   - API response times
   - Model selection frequency
   - Error rates per model

---

## Rollback Plan

If critical issues arise:

### Backend Rollback
```bash
cd /var/www/halext-org
git log --oneline -10  # Find commit before d8f572b
git checkout <previous_commit>
sudo systemctl restart halext-api
```

### Database Rollback
```sql
-- Remove default_model_id column if needed
ALTER TABLE conversations DROP COLUMN default_model_id;

-- Drop usage logs table if needed (CAUTION: data loss)
DROP TABLE IF EXISTS ai_usage_logs;
```

### Frontend Rollback
```bash
cd /var/www/halext-org/frontend
git checkout <previous_commit>
npm run build
sudo systemctl reload nginx
```

---

## iOS Deployment (Deferred)

**Status:** iOS build has deployment target configuration issues. Deploy after fixing:
- Xcode doesn't support macOS 26.0.1 error
- iOS deployment target mismatch (18.6.2 vs 26.1)

**Action Items:**
1. Lower Cafe.app deployment target to iOS 18.0
2. Update project settings in Xcode
3. Test build on available devices
4. Submit to TestFlight once stable

---

## Success Criteria

### Must Pass:
- [ ] Backend starts without errors
- [ ] Database migration completes successfully
- [ ] Frontend loads without console errors
- [ ] Model selector appears in web UI
- [ ] Can select and switch between models
- [ ] AI responses include model attribution
- [ ] Usage logging captures all requests

### Should Pass:
- [ ] Settings section fully functional
- [ ] Admin panel model management works
- [ ] Task/Event/Note assistants integrate model selection
- [ ] Performance is comparable to pre-deployment

### Nice to Have:
- [ ] All automated tests pass (auth fixtures need work)
- [ ] iOS app builds successfully (config issues)

---

## Deployment Timeline

1. **Backend** (15 minutes)
   - Pull code: 2 min
   - Install deps: 3 min
   - Run migration: 1 min
   - Restart service: 2 min
   - Verification: 7 min

2. **Frontend** (10 minutes)
   - Build: 5 min
   - Deploy: 2 min
   - Nginx reload: 1 min
   - Verification: 2 min

3. **Testing** (20 minutes)
   - API tests: 10 min
   - Web UI tests: 10 min

**Total Estimated Time:** 45 minutes

---

## Contact Information

**Deployment Lead:** Claude Code Agent
**Documentation:**
- `/docs/ai/AI_ROUTING_IMPLEMENTATION_PLAN.md`
- `/docs/ai/AI_ROUTING_MANUAL_QA.md`
- `/backend/README_TESTING.md`

**Support:**
- Backend logs: `sudo journalctl -u halext-api -f`
- Frontend logs: Browser DevTools Console
- Database: `psql halext_db`

---

## Completion

Once deployment is complete:
- [ ] Update `docs/ops/DEPLOYMENT.md` with deployment notes
- [ ] Tag release: `git tag -a v1.x.x-ai-routing -m "AI routing feature release"`
- [ ] Push tags: `git push origin --tags`
- [ ] Update project board/issue tracker
- [ ] Notify team of new features

---

**Deployment Ready:** ✅ YES
**Blocker Issues:** ❌ NONE (iOS deferred)
**Ready to Deploy:** Backend + Frontend (Server deployment ready)
