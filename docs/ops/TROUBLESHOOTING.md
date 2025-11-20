# Halext.org Troubleshooting Guide

**Comprehensive solutions to common issues**

This guide documents real issues encountered during development and deployment, along with their solutions.

---

## Table of Contents

1. [Backend Issues](#backend-issues)
2. [Frontend Build Issues](#frontend-build-issues)
3. [Database Issues](#database-issues)
4. [Network & Connectivity](#network--connectivity)
5. [macOS Ollama Issues](#macos-ollama-issues)
6. [Ubuntu Server Performance](#ubuntu-server-performance)
7. [SSH & Deployment](#ssh--deployment)
8. [Security Issues](#security-issues)
9. [Quick Reference](#quick-reference)

---

## Backend Issues

### Error: "Attribute name 'metadata' is reserved"

**Symptoms:**
```
sqlalchemy.exc.InvalidRequestError: Attribute name 'metadata' is reserved when using the Declarative API.
```

**Cause:** SQLAlchemy reserves `metadata` as a class attribute in declarative models.

**Solution:**
1. Rename the field in your model:
```python
# backend/app/models.py
class AIClientNode(Base):
    # WRONG:
    # metadata = Column(JSON, default=dict)

    # CORRECT:
    node_metadata = Column(JSON, default=dict)
```

2. Update all schemas:
```python
# backend/app/admin_routes.py
class AIClientNodeCreate(BaseModel):
    node_metadata: dict = {}  # Changed from metadata

class AIClientNodeResponse(BaseModel):
    node_metadata: dict  # Changed from metadata
```

3. Update frontend interfaces:
```typescript
// frontend/src/components/sections/AdminSection.tsx
interface AIClient {
  node_metadata: Record<string, any>  // Changed from metadata
}
```

4. Run migration:
```bash
cd backend
source env/bin/activate
python migrations/add_api_keys.py
```

---

### Backend Won't Start

**Symptoms:**
```
ModuleNotFoundError: No module named 'httpx'
sqlalchemy.exc.OperationalError: (psycopg2.OperationalError) connection to server failed
```

**Solutions:**

**Missing Dependencies:**
```bash
cd backend
source env/bin/activate
pip install -r requirements.txt
```

**Database Connection Failed:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Verify credentials in .env
cat backend/.env
# Should have: DATABASE_URL=postgresql://halext:PASSWORD@localhost/halext_db

# Test connection manually
psql -h localhost -U halext -d halext_db
```

**Port Already in Use:**
```bash
# Find what's using port 8000
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or change port in systemd service
sudo nano /etc/systemd/system/halext-backend.service
# Change: --port 8001

sudo systemctl daemon-reload
sudo systemctl restart halext-backend
```

---

### Admin Endpoints Return 403 Forbidden

**Symptoms:**
```
{"detail": "Admin access required"}
```

**Cause:** Current user doesn't have admin privileges.

**Solution:**
Check admin logic in `backend/app/admin_routes.py:34`:
```python
def get_current_admin_user(current_user: models.User = Depends(auth.get_current_active_user)):
    # Current check: user ID is 1 OR username is "admin" or "scawful"
    if current_user.id == 1 or current_user.username in ["admin", "scawful"]:
        return current_user
    raise HTTPException(status_code=403, detail="Admin access required")
```

To add more admins, either:
1. Make sure they have user_id == 1
2. Add their username to the list
3. Implement proper role-based access control (future enhancement)

---

## Frontend Build Issues

### TypeScript Error: "is declared but never used"

**Symptoms:**
```
error TS6133: 'MdCloudDownload' is declared but its value is never read.
error TS6133: 'pullingModel' is declared but its value is never read.
```

**Cause:** Unused imports and variables flagged by TypeScript strict mode.

**Solution:**
Remove all unused code:
```typescript
// WRONG:
import { MdCloudDownload, MdDeleteForever, MdComputer } from 'react-icons/md'
const [pullingModel, setPullingModel] = useState<number | null>(null)

// CORRECT:
import { MdComputer } from 'react-icons/md'
// Only import what you actually use
```

See `frontend/src/components/sections/AdminSection.tsx:2-12` for correct imports.

---

### TypeScript Error: "must be imported using a type-only import"

**Symptoms:**
```
error TS1484: 'FormEvent' is a type and must be imported using a type-only import when 'verbatimModuleSyntax' is enabled.
```

**Cause:** TypeScript 5+ with `verbatimModuleSyntax` requires explicit type imports.

**Solution:**
```typescript
// WRONG:
import { useState, FormEvent } from 'react'

// CORRECT:
import { useState, type FormEvent } from 'react'
```

See `frontend/src/components/sections/TasksSection.tsx:1` for reference.

---

### Frontend Build Extremely Slow (20+ minutes)

**Symptoms:**
- `npm run build` takes 20+ minutes
- High memory usage during build
- Ubuntu server has only 2GB RAM

**Cause:** Vite builds are memory-intensive, 2GB is insufficient for fast builds.

**Solutions:**

**Option 1: Pre-build locally and rsync** (RECOMMENDED)
```bash
# On your local machine (Mac)
cd frontend
npm run build

# Rsync to server
rsync -avz --delete dist/ halext@YOUR_SERVER:/srv/halext.org/halext-org/frontend/dist/
```

**Option 2: Add swap file**
```bash
# On Ubuntu server
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

**Option 3: Limit build parallelism**
```bash
# Modify package.json build script
"build": "NODE_OPTIONS='--max-old-space-size=1024' vite build"
```

**Option 4: Use remote rebuild**
Use the admin panel "Rebuild Frontend" button (see `backend/app/admin_routes.py:278`), but be patient - it will take time.

---

### Build Fails: "Cannot find module"

**Symptoms:**
```
Error: Cannot find module '@/utils/api'
Module not found: Can't resolve './components/ChatSection'
```

**Solutions:**

**Missing Node Modules:**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run build
```

**Path Alias Issues:**
Check `vite.config.ts`:
```typescript
export default defineConfig({
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

**Case Sensitivity:**
```typescript
// WRONG: (file is ChatSection.tsx)
import ChatSection from './components/chatsection'

// CORRECT:
import ChatSection from './components/ChatSection'
```

---

## Database Issues

### Migration Fails: "relation already exists"

**Symptoms:**
```
psycopg2.errors.DuplicateTable: relation "ai_client_nodes" already exists
```

**Solution:**
```bash
# Check existing tables
psql -h localhost -U halext -d halext_db -c "\dt"

# If table exists but is wrong version, drop and recreate:
psql -h localhost -U halext -d halext_db

DROP TABLE IF EXISTS ai_client_nodes CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS ai_provider_configs CASCADE;
\q

# Re-run migration
cd backend
source env/bin/activate
python migrations/add_api_keys.py
```

---

### Database Connection Pool Exhausted

**Symptoms:**
```
sqlalchemy.exc.TimeoutError: QueuePool limit exceeded
```

**Cause:** Too many open database connections.

**Solution:**
```python
# backend/app/database.py
engine = create_engine(
    DATABASE_URL,
    pool_size=5,        # Default is 5
    max_overflow=10,    # Default is 10
    pool_recycle=3600,  # Recycle connections after 1 hour
    pool_pre_ping=True  # Verify connections before using
)
```

**Quick Fix:**
```bash
# Restart backend
sudo systemctl restart halext-backend

# Or restart PostgreSQL
sudo systemctl restart postgresql
```

---

## Network & Connectivity

### Cannot Connect to Mac from Ubuntu Server

**Symptoms:**
```bash
$ curl http://YOUR_PUBLIC_IP:11434/api/tags
curl: (28) Failed to connect to YOUR_PUBLIC_IP port 11434: Connection timed out
```

**Diagnosis Steps:**

**1. Check Ollama is running on Mac:**
```bash
# On Mac
lsof -i :11434 -P -n | grep LISTEN
# Should show: ollama ... *:11434 (LISTEN)

# If shows 127.0.0.1:11434 instead of *:11434
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
launchctl setenv OLLAMA_ORIGINS "*"
pkill ollama
# Restart Ollama.app
```

**2. Test local connectivity:**
```bash
# On Mac
curl http://localhost:11434/api/tags
# Should return JSON with models

curl http://YOUR_MAC_LOCAL_IP:11434/api/tags
# Example: curl http://192.168.1.204:11434/api/tags
```

**3. Check macOS Firewall:**
```bash
# On Mac
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
# If enabled, add Ollama to allowed apps:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Ollama.app/Contents/MacOS/ollama
```

**4. Verify Port Forwarding:**
Log into your router admin panel (usually `192.168.1.1` or `192.168.0.1`) and verify:
- Application: Mac Ollama
- Original Port: 11434
- Protocol: TCP
- Fwd to Addr: YOUR_MAC_LOCAL_IP (e.g., 192.168.1.204)
- Fwd to Port: 11434
- Schedule: Always

See `PORT_FORWARDING_GUIDE.md` for Verizon 5G router specific instructions.

**5. Test from outside network:**
```bash
# IMPORTANT: Cannot test from inside your home network (hairpin NAT issue)
# Use mobile data or ask a friend to test:
curl http://YOUR_PUBLIC_IP:11434/api/tags
```

**6. Reboot router:**
Many routers require a reboot for port forwarding rules to take effect:
```bash
# Log into router admin panel → Reboot
# Or power cycle the router
```

---

### "Connection refused" vs "Connection timed out"

**Connection Refused:**
- Means: Server is reachable, but nothing is listening on that port
- Check: Is Ollama running? Is it listening on correct port?

**Connection Timed Out:**
- Means: Cannot reach the server at all
- Check: Firewall blocking? Port forwarding configured? Router rebooted?

---

### Hairpin NAT / NAT Loopback Issue

**Symptoms:**
- Mac Ollama works locally (`curl localhost:11434`)
- Cannot access from inside home network using public IP
- Works from external networks (mobile data)

**Explanation:**
Many routers don't support "hairpin NAT" - accessing your own public IP from inside your network.

**Solutions:**

**Option 1: Use local IP internally**
```python
# backend/app/ai_client_manager.py
def get_base_url(self, node: AIClientNode, from_internal: bool = False):
    if from_internal and node.hostname == "YOUR_PUBLIC_IP":
        return f"http://192.168.1.204:{node.port}"
    return f"http://{node.hostname}:{node.port}"
```

**Option 2: Use DDNS hostname instead of IP**
```bash
# Setup DuckDNS (free)
# Create account at https://www.duckdns.org/
# Install updater:
echo "url='https://www.duckdns.org/update?domains=yourname&token=YOUR_TOKEN&ip='" | curl -k -o ~/duckdns/duck.sh -K -
chmod 700 ~/duckdns/duck.sh

# Add to crontab
crontab -e
# Add: */5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1

# Use hostname in admin panel:
# Hostname: yourname.duckdns.org
```

**Option 3: Enable hairpin NAT on router** (if supported)
Look for settings like:
- "NAT Loopback"
- "Hairpin NAT"
- "NAT Reflection"

Enable this in router settings.

---

### Cloudflare Tunnel Alternative

**Why:** Avoids port forwarding entirely, more secure.

**Setup:**
```bash
# On Mac
brew install cloudflared

# Login to Cloudflare
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create mac-ollama

# Configure
nano ~/.cloudflared/config.yml
```

**Config:**
```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: /Users/YOU/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: ollama.yourname.com
    service: http://localhost:11434
  - service: http_status:404
```

**Run:**
```bash
cloudflared tunnel run mac-ollama
```

**Route DNS:**
```bash
cloudflared tunnel route dns mac-ollama ollama.yourname.com
```

Now use `https://ollama.yourname.com` in admin panel instead of public IP. See `docs/REMOTE_OLLAMA_SETUP.md` for complete guide.

---

## macOS Ollama Issues

### Ollama Only Listening on Localhost

**Symptoms:**
```bash
$ lsof -i :11434 -P -n | grep LISTEN
ollama ... 127.0.0.1:11434 (LISTEN)  # Wrong!
```

**Solution:**
```bash
# Set environment variables
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
launchctl setenv OLLAMA_ORIGINS "*"

# Restart Ollama
pkill ollama
# Relaunch Ollama.app from Applications

# Verify
lsof -i :11434 -P -n | grep LISTEN
# Should show: ollama ... *:11434 (LISTEN)
```

**Make Permanent (Launch Agent):**
```bash
nano ~/Library/LaunchAgents/org.halext.ollama.plist
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.halext.ollama</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>0.0.0.0:11434</string>
        <key>OLLAMA_ORIGINS</key>
        <string>*</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

```bash
# Load agent
launchctl load ~/Library/LaunchAgents/org.halext.ollama.plist

# Verify
launchctl list | grep ollama
```

See `scripts/macos-ollama-server-setup.sh` for automated setup.

---

### Ollama "404 Not Found" on API Calls

**Symptoms:**
```bash
$ curl http://localhost:11434/api/tags
404 page not found
```

**Cause:** Ollama API endpoints require exact paths.

**Correct Endpoints:**
```bash
# List models
curl http://localhost:11434/api/tags

# Generate (chat)
curl http://localhost:11434/api/generate -d '{
  "model": "llama3",
  "prompt": "Hello"
}'

# Pull model
curl http://localhost:11434/api/pull -d '{
  "name": "llama3"
}'

# Delete model
curl -X DELETE http://localhost:11434/api/delete -d '{
  "name": "llama3"
}'
```

---

### "Model Not Found" Error

**Symptoms:**
```json
{"error": "model 'llama3' not found"}
```

**Solution:**
```bash
# List available models
ollama list

# Pull the model
ollama pull llama3

# Verify
curl http://localhost:11434/api/tags
```

---

## Ubuntu Server Performance

### Server Unresponsive / Too Slow to SSH

**Symptoms:**
- SSH hangs on connection
- Takes 5+ minutes to login
- Commands timeout

**Emergency Recovery:**
```bash
# From your local machine, use aggressive timeouts
ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 halext@YOUR_SERVER "pkill ollama && pkill python && sudo systemctl restart docker"

# If that doesn't work, use emergency script:
./scripts/emergency-ubuntu-cleanup.sh
```

**Root Cause:** 2GB RAM exhausted by Ollama + Docker + OpenWebUI

**Prevention:**
```bash
# On Ubuntu server, DISABLE Ollama permanently
sudo systemctl stop ollama
sudo systemctl disable ollama

# Remove OpenWebUI if not needed
docker stop open-webui
docker rm open-webui

# Only run lightweight coordination services
```

**Why this matters:** The Ubuntu server should NOT run AI models - it's only a coordinator. AI workloads run on home machines (Mac M1, Windows PC). See `docs/ARCHITECTURE_OVERVIEW.md`.

---

### High Memory Usage

**Diagnosis:**
```bash
# Check memory
free -h
# If "available" is < 200MB, system will be slow

# Find memory hogs
ps aux --sort=-%mem | head -10

# Docker stats
docker stats --no-stream
```

**Solutions:**

**Add Swap:**
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

**Limit Docker Memory:**
```bash
# Edit docker-compose.yml
version: '3'
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    deploy:
      resources:
        limits:
          memory: 512M
```

**Stop Unused Services:**
```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
docker stop $(docker ps -q)
```

---

### Disk Full

**Diagnosis:**
```bash
df -h
# Check "Use%" column

# Find large directories
du -sh /* 2>/dev/null | sort -hr | head -10
```

**Common Culprits:**

**Docker Images:**
```bash
docker system df
docker system prune -a --volumes
```

**Logs:**
```bash
sudo journalctl --disk-usage
sudo journalctl --vacuum-time=7d
```

**Ollama Models:**
```bash
du -sh ~/.ollama
# If too large, delete models:
ollama rm llama3
```

---

## SSH & Deployment

### SSH Permission Denied (Password)

**Symptoms:**
```
Permission denied (publickey,password).
ssh_askpass: exec(/usr/X11R6/bin/ssh-askpass): No such file or directory
```

**Cause:** SSH key not set up, server doesn't allow password auth.

**Solution:**
```bash
# Option 1: Use helper script
./scripts/setup-ssh-key.sh

# Option 2: Manual setup
ssh-keygen -t ed25519 -C "your_email@example.com"
ssh-copy-id halext@YOUR_SERVER

# Option 3: Manual copy
cat ~/.ssh/id_ed25519.pub
# Copy output

ssh halext@YOUR_SERVER
# Enter password
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
# Paste public key, save
chmod 600 ~/.ssh/authorized_keys
exit

# Test
ssh halext@YOUR_SERVER "echo 'Success!'"
```

---

### SSH "Host Key Verification Failed"

**Symptoms:**
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

**Cause:** Server was reinstalled or SSH keys changed.

**Solution:**
```bash
# Remove old key
ssh-keygen -R YOUR_SERVER_IP

# Or edit known_hosts
nano ~/.ssh/known_hosts
# Delete the line with YOUR_SERVER_IP

# Reconnect (will prompt to add new key)
ssh halext@YOUR_SERVER
```

---

### Deployment Script Fails: "command not found"

**Symptoms:**
```
./scripts/deploy-to-ubuntu.sh: line 42: npm: command not found
python: command not found
```

**Cause:** Commands not in PATH when running via SSH non-interactive shell.

**Solution:**
```bash
# Use full paths in script
/usr/bin/python3 instead of python
/usr/bin/npm instead of npm

# Or source profile
ssh halext@YOUR_SERVER "source ~/.profile && npm run build"

# Or use login shell
ssh -t halext@YOUR_SERVER "bash -l -c 'npm run build'"
```

---

## Security Issues

### Hardcoded Credentials in Git

**Prevention:**
```bash
# Check before committing
git diff
git status

# Search for IPs and passwords
grep -r "YOUR_PUBLIC_IP" .
grep -r "password" .
```

**If Already Committed:**
```bash
# Remove from history (careful!)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch docs/DEPLOYMENT_CHECKLIST.md" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (DANGEROUS)
git push origin --force --all
```

**Better: Use `.gitignore`:**
```
# .gitignore
.env
.env.local
.env.network
*.local.md
scripts/deploy-to-ubuntu.sh
scripts/emergency-*.sh
```

See `.gitignore` and `.env.network.example` for reference.

---

### Ollama Exposed to Internet Without Auth

**Symptoms:**
- Port 11434 forwarded to internet
- No authentication on Ollama API
- Anyone can use your models

**Solutions:**

**Option 1: IP Allowlist in macOS Firewall:**
```bash
# Allow only Ubuntu server IP
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Ollama.app/Contents/MacOS/ollama
# Then configure in System Preferences → Security & Privacy → Firewall
```

**Option 2: Cloudflare Access:**
Use Cloudflare Tunnel with Access policy (requires login). See `docs/REMOTE_OLLAMA_SETUP.md`.

**Option 3: VPN:**
```bash
# Install WireGuard on both Mac and Ubuntu
# Only allow connections over VPN
```

**Option 4: Reverse Proxy with Auth:**
```bash
# On Mac, run nginx:
brew install nginx

# Configure nginx to proxy Ollama with basic auth
# /usr/local/etc/nginx/nginx.conf
server {
    listen 11434;
    location / {
        auth_basic "Ollama Access";
        auth_basic_user_file /usr/local/etc/nginx/.htpasswd;
        proxy_pass http://localhost:11435;  # Ollama on different port
    }
}

# Create password file
htpasswd -c /usr/local/etc/nginx/.htpasswd admin
```

---

## Quick Reference

### Emergency Commands

```bash
# Kill everything on Ubuntu
ssh halext@YOUR_SERVER "pkill ollama && pkill python && docker stop $(docker ps -q)"

# Restart backend
ssh halext@YOUR_SERVER "sudo systemctl restart halext-backend"

# Rebuild frontend (quick)
ssh halext@YOUR_SERVER "cd /srv/halext.org/halext-org/frontend && npm run build"

# Check logs
ssh halext@YOUR_SERVER "sudo journalctl -u halext-backend -f"
```

### Health Check Script

```bash
#!/bin/bash
# Save as: check-health.sh

echo "=== Backend Status ==="
curl -s http://localhost:8000/api/health || echo "Backend down"

echo -e "\n=== Mac Ollama Status ==="
curl -s http://YOUR_PUBLIC_IP:11434/api/tags | jq '.models | length' || echo "Ollama unreachable"

echo -e "\n=== Ubuntu Memory ==="
ssh halext@YOUR_SERVER "free -h | grep Mem"

echo -e "\n=== Docker Status ==="
ssh halext@YOUR_SERVER "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

### Diagnostic Information to Include

When asking for help, always include:

**1. System Info:**
```bash
# Ubuntu
uname -a
lsb_release -a
free -h
df -h

# Mac
sw_vers
sysctl hw.memsize
df -h
```

**2. Service Status:**
```bash
# Ubuntu
sudo systemctl status halext-backend
sudo systemctl status postgresql
sudo systemctl status nginx
docker ps

# Mac
lsof -i :11434
launchctl list | grep ollama
```

**3. Logs:**
```bash
# Backend
sudo journalctl -u halext-backend -n 50 --no-pager

# Nginx
sudo tail -50 /var/log/nginx/error.log

# Ollama (Mac)
tail -50 ~/.ollama/logs/server.log
```

**4. Network:**
```bash
# Can you reach Mac from Ubuntu?
ssh halext@YOUR_SERVER "curl -m 5 http://YOUR_PUBLIC_IP:11434/api/tags"

# Is Ollama listening?
lsof -i :11434 -P -n
```

---

## Related Documentation

- [Architecture Overview](ARCHITECTURE_OVERVIEW.md) - System design and components
- [Quickstart Guide](QUICKSTART.md) - 15-minute setup
- [Remote Ollama Setup](REMOTE_OLLAMA_SETUP.md) - Port forwarding and Cloudflare Tunnel
- [Port Forwarding Guide](../PORT_FORWARDING_GUIDE.md) - Router configuration
- [Emergency Recovery](EMERGENCY_SERVER_RECOVERY.md) - When things go wrong

---

**Last Updated:** 2025-11-18
**Maintained by:** scawful
**Questions?** https://github.com/scawful/halext-org/issues
