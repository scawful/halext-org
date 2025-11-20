# Connecting Mac Ollama to Remote Ubuntu Server

Quick guide for adding your Mac as an AI client to your remote Ubuntu server when they're on different networks.

## Current Situation

- **Mac:** Home network, running Ollama with models
- **Ubuntu Server:** Remote VPS (org.halext.org) on different network
- **Goal:** Add Mac as AI client in Admin Panel

## Problem: Cloudflare Tunnel Limitation

Cloudflare Tunnel works great for web traffic but has issues with Ollama's API:
- Returns `500 Internal Server Error` for API requests
- HTTPS/SSL termination may interfere with Ollama's HTTP API
- Not recommended for this use case

## Recommended Solutions (In Order of Preference)

### Solution 1: Tailscale (Easiest & Most Secure) ⭐ RECOMMENDED

Tailscale creates a secure peer-to-peer VPN between your devices with zero configuration.

#### Setup Steps

**On Mac:**
```bash
# Install Tailscale
brew install tailscale

# Start Tailscale
sudo tailscale up

# Note your Tailscale IP
tailscale ip -4
# Example output: 100.x.x.x
```

**On Ubuntu Server:**
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale
sudo tailscale up

# Verify connection to Mac
tailscale status
```

**Test Connection:**
```bash
# From Ubuntu, test Mac's Ollama
curl http://100.x.x.x:11434/api/tags
# (Use the Tailscale IP from your Mac)
```

**Add to Admin Panel:**
```
Name: Mac Studio
Hostname: 100.x.x.x (your Mac's Tailscale IP)
Port: 11434
API Key: (leave blank)
```

#### Advantages
- ✅ Zero-trust security (WireGuard encryption)
- ✅ Works across any network (NAT, firewalls, etc.)
- ✅ No port forwarding needed
- ✅ Free for personal use (up to 100 devices)
- ✅ Automatic reconnection
- ✅ Works even when Mac or Ubuntu change networks

#### Disadvantages
- Requires installing client on both machines
- Requires Tailscale account

---

### Solution 2: Cloudflare Tunnel with HTTP

Try using HTTP instead of HTTPS for the Cloudflare tunnel connection.

#### Update Tunnel Config

Edit `~/.cloudflared/config.yml` on Mac:

```yaml
tunnel: eec05142-8d35-4927-9926-6dc520afaa11
credentials-file: /Users/scawful/.cloudflared/eec05142-8d35-4927-9926-6dc520afaa11.json

ingress:
  - hostname: ollama.halext.org
    service: http://127.0.0.1:11434
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      http2Origin: false       # Add this
      disableChunkedEncoding: false  # Add this
  - service: http_status:404
```

**Restart tunnel:**
```bash
pkill cloudflared
cloudflared tunnel run mac-ollama
```

**Test from Ubuntu:**
```bash
curl http://ollama.halext.org/api/tags
```

**Add to Admin Panel:**
```
Name: Mac Studio
Hostname: ollama.halext.org
Port: 80
API Key: (leave blank)
```

#### Advantages
- ✅ No additional software
- ✅ Already have tunnel set up
- ✅ Free

#### Disadvantages
- ❌ May still have issues with Ollama API
- ❌ Less reliable for streaming responses
- ❌ Cloudflare bandwidth limits may apply

---

### Solution 3: ngrok (Quick Testing)

Good for temporary testing or development.

#### Setup Steps

**On Mac:**
```bash
# Install ngrok
brew install ngrok

# Sign up and get auth token from https://ngrok.com
ngrok config add-authtoken YOUR_TOKEN

# Start tunnel
ngrok http 11434
```

This will give you a URL like: `https://abc123.ngrok-free.app`

**Add to Admin Panel:**
```
Name: Mac Studio (ngrok)
Hostname: abc123.ngrok-free.app
Port: 443
API Key: (leave blank)
```

#### Advantages
- ✅ Very quick to set up
- ✅ Works immediately
- ✅ Free tier available

#### Disadvantages
- ❌ URL changes each time you restart (unless paid plan)
- ❌ Free tier has connection limits
- ❌ Not suitable for production/permanent use
- ❌ Slower than direct connection

---

### Solution 4: Port Forwarding (If on Same Home Network)

Only works if Ubuntu and Mac are on the same home network. Since yours aren't, skip this option.

---

## Testing Checklist

After setting up any solution:

1. **Test from Mac locally:**
   ```bash
   curl http://127.0.0.1:11434/api/tags
   ```
   Should return JSON with your models.

2. **Test from Ubuntu:**
   ```bash
   ssh halext@144.202.52.126
   curl http://YOUR_CONNECTION_URL:PORT/api/tags
   ```
   Should return the same JSON.

3. **Add in Admin Panel:**
   - Go to https://org.halext.org
   - Click Admin Panel icon
   - Click "Add Client"
   - Fill in connection details
   - Click "Test Connection"
   - Should show green checkmark

4. **Verify models appear:**
   - Admin panel should show available models
   - Models should be selectable in AI Chat

---

## Current Mac Ollama Status

Your Mac currently has these models:
- qwen2.5-coder:14b
- qwen3:8b
- qwen3-vl:8b (vision model)
- llama3:latest
- mistral:latest
- gemma3:12b-it-qat
- deepseek-r1:8b
- gemma3:4b
- qwen2.5-coder:7b

All models are ready to use once connection is established.

---

## Troubleshooting

### Cloudflare Tunnel Returns 500 Error

**Symptom:**
```bash
curl https://ollama.halext.org/api/tags
# Returns: error code: 500
```

**Solution:** Use Tailscale or ngrok instead. Cloudflare doesn't work well with Ollama's streaming API.

### Connection Timeout

**Check 1: Is Ollama running?**
```bash
# On Mac
ps aux | grep ollama | grep -v grep
```

**Check 2: Is Ollama listening on network?**
```bash
# On Mac
lsof -i :11434 -P -n
# Should show: *:11434 (not 127.0.0.1:11434)
```

**Fix if needed:**
```bash
# Stop Ollama
pkill ollama

# Start Ollama to listen on all interfaces
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

### Models Not Showing in Admin Panel

**Cause:** Connection is established but API calls are failing.

**Debug:**
```bash
# From Ubuntu
curl -v http://YOUR_CONNECTION:PORT/api/tags
```

Look for:
- HTTP status code (should be 200)
- Content-Type header (should be application/json)
- Response body (should be JSON with models array)

---

## Recommended Setup for Your Use Case

Based on your setup (Mac at home, Ubuntu remote VPS):

**Best Option: Tailscale**
1. Install Tailscale on both Mac and Ubuntu (5 minutes)
2. Get Mac's Tailscale IP: `tailscale ip -4`
3. Add to Admin Panel using Tailscale IP
4. Done! Secure, permanent, reliable connection

**Alternative: ngrok (for testing)**
1. Install ngrok on Mac
2. Run: `ngrok http 11434`
3. Copy the public URL
4. Add to Admin Panel
5. Good for testing, but not permanent

**Not Recommended:**
- Cloudflare Tunnel (has API compatibility issues)
- Port Forwarding (requires same network)

---

## Next Steps

1. **Choose a solution** (Tailscale recommended)
2. **Follow setup steps** above
3. **Test connection** from Ubuntu to Mac
4. **Add in Admin Panel** with connection details
5. **Test AI chat** using Mac's models

---

## Security Notes

### Tailscale
- Uses WireGuard encryption
- Only your devices can connect
- No public exposure
- ✅ Most secure option

### Cloudflare Tunnel
- Free SSL/TLS
- No public IP exposure
- Cloudflare DDoS protection
- ⚠️ But doesn't work well with Ollama

### ngrok
- HTTPS by default
- Public URL but obscured
- Free tier has connection limits
- ⚠️ Not recommended for production

### Port Forwarding
- Exposes port publicly
- Requires firewall rules
- ⚠️ Only use with IP allowlist
- ❌ Not applicable (different networks)

---

## Reference Documents

- Full remote setup guide: [REMOTE_OLLAMA_SETUP.md](./REMOTE_OLLAMA_SETUP.md)
- Distributed Ollama architecture: [DISTRIBUTED_OLLAMA_SETUP.md](./DISTRIBUTED_OLLAMA_SETUP.md)
- Deployment scripts: [../scripts/README.md](../scripts/README.md)

---

## Quick Command Reference

**Check if Ollama is running:**
```bash
ps aux | grep ollama | grep -v grep
```

**Check what port Ollama is on:**
```bash
lsof -i :11434 -P -n
```

**Get your Mac's Tailscale IP:**
```bash
tailscale ip -4
```

**Test Ollama from Ubuntu:**
```bash
ssh halext@144.202.52.126 "curl http://CONNECTION:PORT/api/tags"
```

**View Cloudflare tunnel logs:**
```bash
tail -f /tmp/cloudflared.log
```

**Restart Cloudflare tunnel:**
```bash
pkill cloudflared
cloudflared tunnel run mac-ollama
```
