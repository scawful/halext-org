# Ubuntu Server Deployment Checklist

Quick reference for deploying the distributed Ollama setup to org.halext.org

## Prerequisites

- [ ] macOS Ollama server setup completed (✅ DONE)
- [ ] Mac IP address noted: `YOUR_MAC_LOCAL_IP`
- [ ] Code pushed to GitHub/GitLab
- [ ] SSH access to Ubuntu server

## Deployment Steps

### 1. Deploy Backend Code

```bash
# SSH into Ubuntu server
ssh user@org.halext.org

# Navigate to project directory
cd halext-org

# Pull latest changes
git pull origin main

# Activate virtual environment
cd backend
source env/bin/activate

# Install any new dependencies
pip install -r requirements.txt
```

### 2. Run Database Migration

This creates the tables for AI client management:

```bash
# Should still be in backend directory with venv activated
python migrations/add_api_keys.py
```

Expected output:
```
✅ Migration completed successfully!
New tables created:
  - api_keys
  - ai_provider_configs
  - ai_client_nodes
```

### 3. Update Backend Dependencies

If `httpx` is not installed (needed for testing connections):

```bash
pip install httpx
pip freeze > requirements.txt  # Update requirements
```

### 4. Restart Backend Service

```bash
# If using systemd
sudo systemctl restart halext-backend

# Or if running manually
# Kill existing process and restart
pkill -f "uvicorn main:app"
cd ~/halext-org/backend
source env/bin/activate
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > backend.log 2>&1 &
```

### 5. Deploy Frontend Code

```bash
cd ~/halext-org/frontend

# Install any new dependencies
npm install

# Build production version
npm run build

# If using nginx to serve, copy build to web root
sudo cp -r dist/* /var/www/html/halext-org/
```

### 6. Test Mac Connectivity

Upload and run the test script:

```bash
# Make scripts directory if it doesn't exist
mkdir -p ~/halext-org/scripts

# Copy the test script from local Mac
# (Run this from your Mac in a new terminal)
scp ~/Code/halext-org/scripts/ubuntu-test-mac-ollama.sh user@org.halext.org:~/halext-org/scripts/

# Back on Ubuntu server
cd ~/halext-org/scripts
chmod +x ubuntu-test-mac-ollama.sh

# Run the test
./ubuntu-test-mac-ollama.sh YOUR_MAC_LOCAL_IP
```

Expected results:
- ✅ Can ping Mac
- ✅ Port 11434 accessible
- ✅ Ollama API responding
- ✅ Models listed

### 7. Add Mac as Client (Web UI Method)

1. Open browser to: `https://org.halext.org`
2. Login with your credentials
3. Click **Admin Panel** icon (shield with settings)
4. Click **"Add Client"** button
5. Fill in form:
   ```
   Name: Mac Studio
   Type: ollama
   Hostname: YOUR_MAC_LOCAL_IP
   Port: 11434
   Make public: ✓ (checked)
   ```
6. Click **"Add Client"**
7. Click **"Test"** button to verify connection
8. Verify status shows **"online"** with green indicator

### 7. Alternative: Add Mac as Client (CLI Method)

```bash
# First, get your auth token
# Login via web UI, then check browser localStorage
# Or login programmatically:

TOKEN=$(curl -s -X POST https://org.halext.org/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=YOUR_USERNAME&password=YOUR_PASSWORD&grant_type=password" \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

# Add the Mac as a client
curl -X POST https://org.halext.org/admin/ai-clients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Mac Studio",
    "node_type": "ollama",
    "hostname": "YOUR_MAC_LOCAL_IP",
    "port": 11434,
    "is_public": true,
    "metadata": {
      "location": "home",
      "model": "M1 Max",
      "ram": "32GB"
    }
  }'
```

### 8. Verify Everything Works

#### Check Admin Panel
1. Go to Admin Panel
2. Verify Mac shows as **"online"**
3. Check that models are listed
4. Note the response time

#### Test AI Chat
1. Go to Chat section
2. Start a new conversation
3. Send a test message
4. Verify response comes from your Mac's Ollama

#### Check Backend Logs
```bash
# If using systemd
sudo journalctl -u halext-backend -f

# Or check log file
tail -f ~/halext-org/backend/backend.log
```

Look for successful requests to Mac's Ollama server.

## Troubleshooting

### Migration Fails

**Error:** `Table already exists`

**Solution:**
```bash
# Tables might already exist from previous run
# Check database
sqlite3 cafe.db ".tables"

# If tables exist, skip migration
# If they don't exist, check error and fix
```

### Can't Connect to Mac from Ubuntu

**Test 1: Basic connectivity**
```bash
ping YOUR_MAC_LOCAL_IP
```

**Test 2: Port accessibility**
```bash
nc -zv YOUR_MAC_LOCAL_IP 11434
```

**Test 3: API check**
```bash
curl http://YOUR_MAC_LOCAL_IP:11434/api/tags
```

**If any fail:**
- Check Mac firewall settings
- Check router/network configuration
- Verify Mac's IP hasn't changed
- Check if VPN is interfering

### Admin Panel Not Showing

**Check 1: Frontend deployed?**
```bash
ls -la /var/www/html/halext-org/
# Should see index.html and assets/
```

**Check 2: Nginx serving correctly?**
```bash
sudo nginx -t
sudo systemctl status nginx
```

**Check 3: Browser cache**
- Hard refresh: Ctrl+Shift+R (Linux/Windows) or Cmd+Shift+R (Mac)
- Or clear browser cache

### Backend Errors

**Check 1: Migration completed?**
```bash
cd ~/halext-org/backend
source env/bin/activate
python -c "from app import models; from app.database import engine; print(models.AIClientNode.__table__.exists(engine))"
# Should print: True
```

**Check 2: Dependencies installed?**
```bash
pip list | grep httpx
# Should show: httpx x.x.x
```

**Check 3: Service running?**
```bash
ps aux | grep uvicorn
# Should show running process
```

## Post-Deployment Verification

### Quick Health Check

Run this on Ubuntu server:

```bash
#!/bin/bash
echo "=== Backend Health Check ==="
curl -s http://localhost:8000/docs >/dev/null && echo "✅ Backend API responding" || echo "❌ Backend not responding"

echo ""
echo "=== Mac Connectivity Check ==="
curl -s http://YOUR_MAC_LOCAL_IP:11434/api/tags >/dev/null && echo "✅ Mac Ollama accessible" || echo "❌ Cannot reach Mac"

echo ""
echo "=== Database Check ==="
cd ~/halext-org/backend
source env/bin/activate
python -c "from app.database import SessionLocal; from app.models import AIClientNode; db = SessionLocal(); print(f'✅ AI Clients in DB: {db.query(AIClientNode).count()}'); db.close()"
```

### Expected Results

After successful deployment, you should have:

- ✅ Backend running and accessible
- ✅ Frontend deployed and accessible
- ✅ Database migration completed
- ✅ Mac Ollama accessible from Ubuntu
- ✅ Mac added as client in admin panel
- ✅ Mac showing as "online" with models listed
- ✅ AI chat using Mac's models

## Files Changed/Added

### Backend
- `backend/app/models.py` - Added AIClientNode, APIKey, AIProviderConfig
- `backend/app/admin_routes.py` - NEW: Admin API endpoints
- `backend/app/ai_client_manager.py` - NEW: Client management logic
- `backend/main.py` - Added admin router
- `backend/migrations/add_api_keys.py` - NEW: Migration script

### Frontend
- `frontend/src/components/sections/AdminSection.tsx` - NEW: Admin UI
- `frontend/src/components/sections/AdminSection.css` - NEW: Admin UI styles
- `frontend/src/components/layout/MenuBar.tsx` - Added admin menu item
- `frontend/src/App.tsx` - Added admin section routing

### Scripts
- `scripts/macos-ollama-server-setup.sh` - NEW: Mac setup
- `scripts/ubuntu-test-mac-ollama.sh` - NEW: Ubuntu test script

### Documentation
- `docs/DISTRIBUTED_OLLAMA_SETUP.md` - NEW: Complete guide
- `scripts/README.md` - Updated with new scripts

## Next Steps After Deployment

1. **Add Windows PC** (if available)
   - Run similar setup on Windows with WSL or native Ollama
   - Add as another client node

2. **Configure AI Provider Selection**
   - Add user preferences for which client to use
   - Implement load balancing

3. **Set up Monitoring**
   - Health check dashboard
   - Client uptime tracking
   - Model usage statistics

4. **Security Hardening**
   - Add VPN for remote Mac access
   - Implement rate limiting
   - Add admin role management

## Rollback Plan

If something goes wrong:

```bash
# Restore database
cd ~/halext-org/backend
cp cafe.db cafe.db.backup-$(date +%Y%m%d)

# Rollback code
git checkout <previous-commit>

# Restart services
sudo systemctl restart halext-backend
sudo systemctl restart nginx
```

## Support

If issues persist:
- Check logs: `sudo journalctl -u halext-backend -f`
- Review [DISTRIBUTED_OLLAMA_SETUP.md](docs/DISTRIBUTED_OLLAMA_SETUP.md)
- Verify Mac is still accessible: `./scripts/ubuntu-test-mac-ollama.sh YOUR_MAC_LOCAL_IP`
