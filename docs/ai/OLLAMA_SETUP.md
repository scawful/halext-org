# Ollama Setup Guide

Complete guide for setting up Ollama servers and connecting them to your Halext backend. This guide covers both local network setups and remote/exposed setups.

## Overview

There are two main scenarios for connecting Ollama to your Halext backend:

1. **Local Network Setup** - macOS and Ubuntu server on the same network (LAN)
2. **Remote/Exposed Setup** - Home machines exposed to cloud server via port forwarding

Choose the section that matches your setup.

---

## Part 1: Local Network Setup (Same Network)

Use this when your macOS Ollama server and Ubuntu backend are on the same local network.

### Architecture

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
                          │ Local Network (LAN)
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              macOS Client (Mac Studio/MacBook)              │
│                  YOUR_MAC_LOCAL_IP:11434                    │
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

### Prerequisites

**On macOS (Ollama Server)**:
- macOS (tested on M1/M2/M3)
- Ollama installed (Download from https://ollama.ai or `brew install ollama`)
- At least one model pulled (e.g., `ollama pull llama3.1`)
- Local network connectivity to Ubuntu server

**On Ubuntu Server**:
- Halext backend deployed and running
- SSH access to server
- Network connectivity to macOS

### Step 1: Configure Ollama on macOS

1. **Install Ollama** (if not already installed):
   ```bash
   brew install ollama
   # Or download from https://ollama.ai
   ```

2. **Start Ollama**:
   ```bash
   ollama serve
   ```
   By default, Ollama listens on `127.0.0.1:11434`. We need to expose it to the network.

3. **Configure Ollama to listen on all interfaces**:
   
   Create or edit `~/.ollama/env`:
   ```bash
   mkdir -p ~/.ollama
   echo 'OLLAMA_HOST=0.0.0.0:11434' > ~/.ollama/env
   ```

   Or set environment variable before starting:
   ```bash
   export OLLAMA_HOST=0.0.0.0:11434
   ollama serve
   ```

4. **Test Ollama is accessible**:
   ```bash
   # On macOS, check it's listening
   lsof -i :11434
   # Should show ollama listening on 0.0.0.0:11434
   
   # Test locally
   curl http://localhost:11434/api/tags
   ```

5. **Pull a model** (if you haven't already):
   ```bash
   ollama pull llama3.1
   # Or: ollama pull mistral
   ```

### Step 2: Find Your Mac's Local IP

```bash
# On macOS
ifconfig | grep "inet " | grep -v 127.0.0.1
# Or use:
ipconfig getifaddr en0  # For WiFi
ipconfig getifaddr en1  # For Ethernet
```

Note your Mac's local IP (e.g., `192.168.1.100`). You'll need this for the Ubuntu server.

### Step 3: Configure Firewall on macOS

Allow incoming connections on port 11434:

```bash
# macOS firewall (if enabled)
# System Settings > Network > Firewall > Options
# Add Ollama as allowed application
# Or disable firewall temporarily for testing

# Using pfctl (if firewall is active)
sudo pfctl -d  # Disable (for testing only)
```

### Step 4: Add Mac as Client on Ubuntu Server

1. **SSH to Ubuntu server**:
   ```bash
   ssh user@org.halext.org
   ```

2. **Navigate to project directory**:
   ```bash
   cd /srv/halext.org/halext-org
   ```

3. **Test connectivity from Ubuntu to Mac**:
   ```bash
   # Replace YOUR_MAC_LOCAL_IP with your Mac's IP
   ping YOUR_MAC_LOCAL_IP
   curl http://YOUR_MAC_LOCAL_IP:11434/api/tags
   ```

   If this fails, check:
   - Mac firewall settings
   - Both machines on same network
   - Mac's IP hasn't changed

4. **Add Mac as client via Admin Panel**:
   - Open `https://org.halext.org` in browser
   - Login with admin credentials
   - Navigate to **Admin Panel** → **AI Clients**
   - Click **"Add Client"**
   - Fill in form:
     ```
     Name: Mac Studio
     Type: ollama
     Hostname: YOUR_MAC_LOCAL_IP
     Port: 11434
     Make public: ✓ (checked)
     ```
   - Click **"Add Client"**
   - Click **"Test"** to verify connection
   - Verify status shows **"online"** with green indicator

5. **Alternative: Add via API**:
   ```bash
   # Get auth token first
   TOKEN=$(curl -s -X POST https://org.halext.org/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username":"YOUR_USERNAME","password":"YOUR_PASSWORD"}' \
     | jq -r '.access_token')

   # Add the Mac as a client
   curl -X POST https://org.halext.org/api/admin/ai-clients \
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
         "model": "M1 Max"
       }
     }'
   ```

### Step 5: Verify Everything Works

1. **Check Admin Panel**:
   - Mac should show as **"online"**
   - Models should be listed (e.g., llama3.1)
   - Response time should be displayed

2. **Test AI Chat**:
   - Go to Chat section
   - Start a new conversation
   - Send a test message
   - Verify response comes from your Mac's Ollama

3. **Check Backend Logs**:
   ```bash
   sudo journalctl -u halext-api -f
   ```
   Look for successful requests to Mac's Ollama server.

---

## Part 2: Remote/Exposed Setup (Port Forwarding)

Use this when your macOS is on a home network and your Ubuntu server is a cloud VPS on a different network. This requires port forwarding on your router.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│           Cloud/VPS (Different Network)                      │
│           Ubuntu Server @ org.halext.org                     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  FastAPI Backend + Admin Panel                      │    │
│  └────────────────────────────────────────────────────┘    │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          │
                          │ Internet (HTTP)
                          │ http://YOUR_PUBLIC_IP:11434
                          │
┌─────────────────────────┼────────────────────────────────────┐
│                         ▼                                    │
│                  Router (Verizon 5G)                        │
│                  Public IP: YOUR_PUBLIC_IP                  │
│                  Port Forward: 11434 → YOUR_MAC_LOCAL_IP:11434 │
│                                                              │
│     ┌──────────────────────────┬──────────────────────┐    │
│     │                          │                       │    │
│  ┌──▼───────────────┐   ┌──────▼──────────┐          │    │
│  │  Mac Studio       │   │  Windows PC     │          │    │
│  │  YOUR_MAC_LOCAL_IP│   │  YOUR_WINDOWS_IP│          │    │
│  │  Ollama Server    │   │  Ollama Server  │          │    │
│  │  llama3.1, etc.   │   │  deepseek, etc. │          │    │
│  └──────────────────┘   └─────────────────┘          │    │
│                                                              │
│                    Home Network                             │
└─────────────────────────────────────────────────────────────┘
```

### Prerequisites

- Router with port forwarding capability
- Public IP address (static or dynamic with DDNS)
- macOS with Ollama installed
- Cloud Ubuntu server with Halext backend

### Step 1: Find Your Public IP

```bash
# Check your public IP
curl ifconfig.me
# Or visit: https://whatismyipaddress.com
```

Note your public IP (you may need DDNS if it changes - see Step 4).

### Step 2: Configure Port Forwarding

1. **Access your router admin panel**:
   - Usually `http://192.168.1.1` or `http://192.168.0.1`
   - Login with admin credentials

2. **Find Port Forwarding settings**:
   - Look for "Port Forwarding", "Virtual Server", or "NAT" section
   - On Verizon 5G routers, it's usually under "Advanced" → "Port Forwarding"

3. **Create port forward rule**:
   ```
   External Port: 11434
   Internal IP: YOUR_MAC_LOCAL_IP (e.g., 192.168.1.100)
   Internal Port: 11434
   Protocol: TCP
   Description: Ollama Server
   ```

4. **Save and apply changes**

5. **Verify port forwarding**:
   ```bash
   # From external network (or use online port checker)
   # Visit: https://www.yougetsignal.com/tools/open-ports/
   # Enter your public IP and port 11434
   # Should show as "Open"
   ```

### Step 3: Configure Ollama on macOS

Same as Part 1, Step 1 - ensure Ollama listens on `0.0.0.0:11434`:

```bash
export OLLAMA_HOST=0.0.0.0:11434
ollama serve
```

Or set in `~/.ollama/env`:
```bash
echo 'OLLAMA_HOST=0.0.0.0:11434' > ~/.ollama/env
```

### Step 4: Handle Dynamic IP (Optional but Recommended)

If your public IP changes, use Dynamic DNS (DDNS):

1. **Sign up for DDNS service** (e.g., DuckDNS, No-IP, DynDNS)
2. **Configure router** to update DDNS automatically
3. **Use DDNS hostname** instead of IP address

Example with DuckDNS:
- Get hostname: `yourname.duckdns.org`
- Use this instead of `YOUR_PUBLIC_IP` in backend configuration

### Step 5: Configure Firewall on macOS

Ensure macOS firewall allows incoming connections:

```bash
# Check firewall status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# If firewall is enabled, add Ollama exception
# System Settings > Network > Firewall > Options
# Add Ollama as allowed application
```

### Step 6: Add Mac as Client on Ubuntu Server

Same as Part 1, Step 4, but use your **public IP** (or DDNS hostname) instead of local IP:

```
Hostname: YOUR_PUBLIC_IP (or yourname.duckdns.org)
Port: 11434
```

### Step 7: Security Considerations

⚠️ **Important**: Exposing Ollama to the internet has security implications:

1. **Use Access Control**: Ensure your Halext backend requires authentication
2. **Restrict Access**: Consider whitelisting only your server's IP in router firewall rules
3. **Use VPN** (Better option): Set up VPN between home network and server instead of exposing ports
4. **Monitor Access**: Check Ollama logs regularly for unauthorized access attempts

### Step 8: Test End-to-End

1. **From Ubuntu server**, test connectivity:
   ```bash
   curl http://YOUR_PUBLIC_IP:11434/api/tags
   ```

2. **Add client** via Admin Panel using public IP

3. **Test AI chat** and verify responses come from Mac's Ollama

---

## Troubleshooting

### Can't Connect from Ubuntu to Mac (Local Network)

1. **Check Mac's IP hasn't changed**:
   ```bash
   # On Mac
   ifconfig | grep "inet "
   ```

2. **Verify Ollama is listening**:
   ```bash
   # On Mac
   lsof -i :11434
   curl http://localhost:11434/api/tags
   ```

3. **Test network connectivity**:
   ```bash
   # From Ubuntu
   ping YOUR_MAC_LOCAL_IP
   telnet YOUR_MAC_LOCAL_IP 11434
   ```

4. **Check firewall**:
   - macOS: System Settings > Network > Firewall
   - Router: Ensure devices can communicate on same network

### Can't Connect via Public IP (Remote Setup)

1. **Verify port forwarding**:
   - Use online port checker: https://www.yougetsignal.com/tools/open-ports/
   - Should show port 11434 as "Open"

2. **Check router firewall**:
   - Some routers have separate firewall rules that block forwarded ports
   - May need to add firewall exception

3. **Test from local network** (should work):
   ```bash
   curl http://YOUR_MAC_LOCAL_IP:11434/api/tags
   ```

4. **Test from external network**:
   ```bash
   # From Ubuntu server
   curl http://YOUR_PUBLIC_IP:11434/api/tags
   ```

5. **Check ISP blocking**:
   - Some ISPs block common ports
   - May need to use different external port and forward to 11434

### Ollama Shows Offline in Admin Panel

1. **Check Ollama is running**:
   ```bash
   # On Mac
   ps aux | grep ollama
   ```

2. **Restart Ollama**:
   ```bash
   # Stop
   pkill ollama
   # Start
   ollama serve
   ```

3. **Verify connection test passes**:
   - Admin Panel → AI Clients → Test button
   - Should show "Connection successful"

4. **Check backend logs**:
   ```bash
   sudo journalctl -u halext-api -f
   ```

---

## Multiple Machines Setup

You can add multiple Ollama servers:

1. **Mac Studio** (primary, local network)
2. **Windows PC** (GPU-accelerated, local network)
3. **Another Mac** (remote location, exposed via port forwarding)

Each machine:
- Must have Ollama installed and configured
- Should have unique identifier in Admin Panel
- Can serve different models

In Admin Panel, add each machine as a separate client node. The backend will automatically route requests based on model availability and latency.

---

## Additional Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [AI Architecture Guide](AI_ARCHITECTURE.md)
- [Mac-to-Ubuntu Connection Guide](CONNECTING_MAC_TO_UBUNTU.md)
- [Backend Deployment Guide](../ops/DEPLOYMENT.md)

