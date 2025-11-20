# Distributed Ollama Setup Guide

Complete guide for setting up your macOS as an Ollama server for your Ubuntu org.halext.org instance.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Ubuntu Server (VM)                        │
│                  org.halext.org                             │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  FastAPI Backend + React Frontend                   │    │
│  │  - Web UI                                           │    │
│  │  - Admin Panel                                      │    │
│  │  - Client Management                                │    │
│  └────────────────────────────────────────────────────┘    │
│                         │                                    │
│                         │ HTTP Requests                      │
│                         ▼                                    │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Network (LAN/WAN)
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              macOS Client (Mac Studio/MacBook)              │
│                  YOUR_MAC_LOCAL_IP:11434                        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Ollama Server                                      │    │
│  │  - Listens on 0.0.0.0:11434                        │    │
│  │  - Serves local models                              │    │
│  │  - Models: llama3.1, mistral, etc.                 │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### On macOS (Ollama Server)

- macOS (tested on M1/M2/M3)
- Ollama installed (Download from https://ollama.ai or `brew install ollama`)
- At least one model pulled (e.g., `ollama pull llama3.1`)
- Local network connectivity to Ubuntu server

### On Ubuntu Server (org.halext.org)

- FastAPI backend running
- Admin panel accessible
- Network access to macOS machine

## Step-by-Step Setup

### Part 1: Configure macOS as Ollama Server

#### Step 1: Run the Setup Script

From your Mac (this repo should be cloned):

```bash
cd ~/Code/halext-org
./scripts/macos-ollama-server-setup.sh
```

The script will:
1. Detect existing Ollama processes
2. Show current network binding status
3. Offer two configuration options:
   - **Option 1: Use Ollama.app with network access (RECOMMENDED)**
     - Keeps your familiar Ollama.app workflow
     - System tray icon still works
     - Just needs a restart to apply network settings

   - **Option 2: Use Launch Agent**
     - Runs as background service
     - Auto-starts on login
     - No system tray icon

#### Step 2: Verify Configuration

The script will automatically verify:
- ✅ Network binding (`*:11434` for all interfaces)
- ✅ Local API accessibility
- ✅ Firewall status
- ✅ Available models

You should see:
```
✅ Listening on all interfaces (*:11434) - Network accessible
✅ Local API responding
📋 Available models:
  llama3.1:latest
  mistral:latest
```

#### Step 3: Note Your Mac's IP

The script will display your Mac's IP address:
```
🌐 Your Mac's local IP: YOUR_MAC_LOCAL_IP
```

**Important:** Keep this IP handy for the next steps.

### Part 2: Verify Connectivity from Ubuntu Server

SSH into your Ubuntu server and test connectivity:

```bash
# On Ubuntu server
ssh user@org.halext.org

# Upload and run the test script
# (Or run these commands manually)

# Test 1: Ping
ping -c 3 YOUR_MAC_LOCAL_IP

# Test 2: Port check
nc -zv YOUR_MAC_LOCAL_IP 11434

# Test 3: API check
curl http://YOUR_MAC_LOCAL_IP:11434/api/tags

# Test 4: Use the comprehensive test script
./scripts/ubuntu-test-mac-ollama.sh YOUR_MAC_LOCAL_IP
```

### Part 3: Add Mac to org.halext.org Admin Panel

#### Option A: Using Web Admin UI (Recommended)

1. Go to **https://org.halext.org**
2. **Login** with your credentials
3. Click the **Admin Panel** icon (shield with settings)
4. Click **"Add Client"**
5. Fill in the form:
   - **Name:** `Mac Studio` (or whatever you want to call it)
   - **Type:** `ollama`
   - **Hostname:** `YOUR_MAC_LOCAL_IP` (your Mac's IP)
   - **Port:** `11434`
   - **Make public:** ✓ (check if you want all users to access it)
6. Click **"Add Client"**

The admin panel will automatically:
- Test the connection
- Retrieve available models
- Display status (online/offline)
- Show response time

#### Option B: Using API (Advanced)

From your Ubuntu server:

```bash
# First, get your auth token by logging in
TOKEN="your_jwt_token_here"

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
      "description": "M1 Max with 32GB RAM"
    }
  }'
```

### Part 4: Run Database Migration (First Time Only)

On your Ubuntu server, run the migration to create AI client tables:

```bash
# SSH into Ubuntu server
ssh user@org.halext.org

# Navigate to backend
cd halext-org/backend

# Activate virtual environment
source env/bin/activate

# Run migration
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

## Network Configuration

### Firewall Rules (macOS)

If macOS Firewall is enabled:

1. Open **System Settings** → **Network** → **Firewall**
2. Click **Options**
3. Find **Ollama** or **ollama** in the list
4. Ensure it's set to **Allow incoming connections**

Or disable firewall temporarily for testing:
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
```

### Router/Network Considerations

If your Ubuntu server is on a different network:

1. **Port Forwarding:** Configure your router to forward port 11434 to your Mac
2. **Dynamic DNS:** Use a service like DuckDNS if your home IP changes
3. **VPN:** Consider setting up a VPN (WireGuard/Tailscale) for secure access
4. **Cloudflare Tunnel:** Use Cloudflare Tunnel for secure public access

## Troubleshooting

### Mac Shows "Offline" in Admin Panel

**Check 1: Verify Ollama is running**
```bash
ps aux | grep ollama
```

**Check 2: Verify network binding**
```bash
lsof -i :11434 -P -n | grep LISTEN
```
Should show: `*:11434` not `127.0.0.1:11434`

**Check 3: Test locally**
```bash
curl http://localhost:11434/api/tags
```

**Fix:** Re-run the setup script and choose Option 1 or 2

### Ubuntu Can't Connect to Mac

**Check 1: Network connectivity**
```bash
ping YOUR_MAC_LOCAL_IP
```

**Check 2: Port accessibility**
```bash
nc -zv YOUR_MAC_LOCAL_IP 11434
```

**Check 3: Firewall**
- macOS Firewall may be blocking
- Router may be blocking
- VPN may be interfering

**Fix:**
```bash
# On Mac, temporarily disable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off

# Test again from Ubuntu
curl http://YOUR_MAC_LOCAL_IP:11434/api/tags

# Re-enable firewall and add exception
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
```

### Ollama.app Not Applying Network Settings

**Symptom:** Still listening on `127.0.0.1:11434` after restart

**Fix 1:** Manually set environment
```bash
# Add to ~/.zshrc or ~/.bash_profile
export OLLAMA_HOST=0.0.0.0:11434
export OLLAMA_ORIGINS=*

# Quit Ollama.app
pkill -f Ollama.app

# Restart from terminal
/Applications/Ollama.app/Contents/MacOS/Ollama &
```

**Fix 2:** Use Launch Agent (Option 2)
```bash
./scripts/macos-ollama-server-setup.sh
# Choose Option 2
```

### Multiple Ollama Processes Running

**Check:**
```bash
ps aux | grep ollama | grep -v grep
lsof -i :11434 -P -n
```

**Fix:**
```bash
# Kill all Ollama processes
pkill -f ollama

# If using Ollama.app, just restart it
# If using launch agent:
launchctl unload ~/Library/LaunchAgents/org.halext.ollama.plist
launchctl load ~/Library/LaunchAgents/org.halext.ollama.plist
```

### Models Not Loading/Slow

**Check available models:**
```bash
ollama list
```

**Pull a model if needed:**
```bash
ollama pull llama3.1
```

**Check model performance:**
```bash
curl http://localhost:11434/api/generate \
  -d '{
    "model": "llama3.1",
    "prompt": "Hello!",
    "stream": false
  }'
```

## Advanced Configuration

### Using Multiple Macs/PCs

You can add multiple client machines:

1. Configure each machine with the setup script
2. Each gets a unique IP
3. Add each as a separate client in admin panel
4. The system will distribute load across available nodes

Example:
- Mac Studio (YOUR_MAC_LOCAL_IP) - M1 Max with llama3.1, mistral
- Windows PC (YOUR_WINDOWS_LOCAL_IP) - RTX 5060 Ti with llama3.1, deepseek
- MacBook Pro (192.168.1.XXX) - M2 with smaller models

### Auto-Discovery (Future Feature)

Planned: Auto-discovery of Ollama instances on local network using mDNS/Bonjour.

### Security Considerations

**Current Setup:**
- Ollama API has no authentication by default
- Anyone on your network can access it
- Suitable for home/private networks

**For Production:**
- Use VPN (WireGuard/Tailscale)
- Use Cloudflare Tunnel with access policies
- Add reverse proxy with authentication (Nginx + OAuth)
- Restrict by IP in firewall rules

### Performance Tuning

**Keep models loaded:**
```bash
# In launch agent plist or environment
OLLAMA_KEEP_ALIVE=24h
```

**Increase concurrent requests:**
```bash
OLLAMA_MAX_LOADED_MODELS=3
```

**GPU settings (if using discrete GPU):**
```bash
OLLAMA_GPU_LAYERS=35  # Adjust based on VRAM
```

## Monitoring & Maintenance

### View Logs (if using Launch Agent)

```bash
# Stdout
tail -f ~/Library/Logs/halext/ollama.log

# Stderr
tail -f ~/Library/Logs/halext/ollama-error.log
```

### Check Service Status

```bash
# If using launch agent
launchctl list | grep ollama

# Check process
ps aux | grep ollama

# Check network binding
lsof -i :11434 -P -n
```

### Restart Service

**If using Ollama.app:**
```bash
pkill -f Ollama.app
open -a Ollama
```

**If using Launch Agent:**
```bash
launchctl unload ~/Library/LaunchAgents/org.halext.ollama.plist
launchctl load ~/Library/LaunchAgents/org.halext.ollama.plist
```

### Update Ollama

```bash
# If installed via Homebrew
brew upgrade ollama

# If using Ollama.app, download latest from ollama.ai

# Restart service after update
```

## Admin Panel Features

Once your Mac is added as a client, you can:

- **View Status:** Real-time online/offline status
- **Test Connection:** Click "Test" to verify connectivity
- **View Models:** See all available models and their sizes
- **Pull Models:** Download new models directly from admin panel
- **Delete Models:** Remove models to free up space
- **View Details:** See model count, response time, last seen timestamp
- **Delete Client:** Remove the client from your network

## Next Steps

1. ✅ Configure macOS Ollama for network access
2. ✅ Test connectivity from Ubuntu
3. ✅ Add Mac to admin panel
4. ⏭️ Repeat for other machines (Windows PC, etc.)
5. ⏭️ Configure AI provider selection in application settings
6. ⏭️ Test AI chat with your local models

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Run the verification script: `./scripts/macos-ollama-server-setup.sh` (Option 3)
3. Check logs on both Mac and Ubuntu
4. Verify network connectivity and firewall rules

## Architecture Benefits

- **Privacy:** Models run locally, data never leaves your network
- **Performance:** Low latency to local models
- **Cost:** No API fees for cloud providers
- **Flexibility:** Run any model your hardware supports
- **Scalability:** Add more client machines as needed
