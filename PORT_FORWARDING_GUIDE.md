# Quick Port Forwarding Guide - Verizon 5G Router

Step-by-step guide to expose your home Ollama servers to your remote Ubuntu cloud server.

## Your Network Details

- **Public IPv4:** `YOUR_PUBLIC_IP` (run `curl -4 ifconfig.me` to find)
- **Public IPv6:** `YOUR_PUBLIC_IPV6` (run `curl -6 ifconfig.me` to find)
- **Router:** Verizon 5G Home Internet
- **Mac Local IP:** `YOUR_MAC_LOCAL_IP` (run `ipconfig getifaddr en0` to find)
- **Ubuntu Server:** Remote VPS (needs to access via public IP)

## Port Forwarding Rules Needed

### For Mac Studio
```
Service Name: Ollama Mac
External Port: 11434
Internal IP: YOUR_MAC_LOCAL_IP
Internal Port: 11434
Protocol: TCP
```

### For Windows PC (later)
```
Service Name: Ollama Windows
External Port: 11435  ← Different external port!
Internal IP: YOUR_WINDOWS_LOCAL_IP
Internal Port: 11434
Protocol: TCP
```

## Step-by-Step Setup

### 1. Access Your Verizon Router

Open browser and go to:
- Try: http://192.168.1.1
- Or try: http://192.168.0.1
- Or check router label for admin URL

Login with credentials (printed on router label)

### 2. Find Port Forwarding Section

Depending on your router model:

**Option A - LTE Home Router:**
- Click: **Advanced** → **Port Forwarding**
- Click: **Add Rule** or **+**

**Option B - 5G Home Router:**
- Click: **Advanced Settings**
- Click: **Port Management** → **Port Forwarding**
- Click: **Add** or **+**

**Option C - Other:**
- Look for: **NAT**, **Virtual Server**, **Applications & Gaming**, or **Forwarding**

### 3. Create Mac Ollama Rule

Fill in the form:
```
Application/Service Name: Ollama Mac
External/Public Port Start: 11434
External/Public Port End: 11434
Internal/Private Port Start: 11434
Internal/Private Port End: 11434
Server/Internal IP Address: YOUR_MAC_LOCAL_IP
Protocol: TCP (or Both/TCP+UDP)
Enabled/Active: ✓ Yes
```

Click **Apply** or **Save**

### 4. Verify & Test

**Test from Mac (local):**
```bash
# Check Ollama is listening
lsof -i :11434 -P -n | grep LISTEN
# Should show: *:11434

# Test locally
curl http://localhost:11434/api/tags
```

**Test from external network:**

Use your phone on **cellular data** (not WiFi):
```bash
curl http://YOUR_PUBLIC_IP:11434/api/tags
```

Or use online port checker:
- Go to: https://www.yougetsignal.com/tools/open-ports/
- IP: `YOUR_PUBLIC_IP`
- Port: `11434`
- Should show: "Port is open"

**Test from Ubuntu server:**
```bash
ssh user@org.halext.org
curl http://YOUR_PUBLIC_IP:11434/api/tags
```

Should return JSON with your models!

## Common Verizon Router Screenshots/Locations

### ASK-NCQ1338 (LTE Home)
1. Login page: `http://192.168.1.1/login.html`
2. Go to: **Advanced** tab
3. Click: **Port Forwarding** (left sidebar)
4. Click: **Add Rule** button

### LVSKIHP (5G Home)
1. Login page: `http://192.168.1.1`
2. Go to: **Advanced Settings**
3. Expand: **Port Management**
4. Click: **Port Forwarding**
5. Click: **+** button

## Troubleshooting

### Can't Find Port Forwarding

Try searching router manual or:
1. Login to router admin
2. Use browser search (Cmd+F) for "forward"
3. Check every Advanced/Settings menu
4. Some routers call it "Virtual Server" or "NAT"

### Port Forward Not Working

**Check 1:** Router needs reboot
```
Unplug router for 30 seconds, plug back in
Wait 2-3 minutes, test again
```

**Check 2:** Mac firewall blocking
```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
# Test, then re-enable:
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
```

**Check 3:** Ollama not listening on all interfaces
```bash
lsof -i :11434 -P -n | grep LISTEN
# Should show *:11434 not 127.0.0.1:11434
# If wrong, re-run: ./scripts/macos-ollama-server-setup.sh
```

**Check 4:** ISP blocking port
- Verizon may block certain ports
- Try different external port (e.g., 8080 → 11434)
- Or use Cloudflare Tunnel instead

### "Port is Closed" on Port Checker

This means:
1. Port forwarding rule not active
2. Mac firewall blocking
3. Ollama not running
4. ISP blocking the port

Go through troubleshooting steps above.

## Alternative: Use Cloudflare Tunnel (Recommended)

Skip port forwarding entirely with Cloudflare Tunnel:

**Advantages:**
- ✅ No router configuration needed
- ✅ Free SSL/TLS encryption
- ✅ No exposed public IP
- ✅ Works even if ISP blocks ports
- ✅ DDoS protection

**Setup (5 minutes):**
```bash
# On your Mac
brew install cloudflare/cloudflare/cloudflared

cloudflared tunnel login
cloudflared tunnel create ollama-mac

# Configure tunnel
cat > ~/.cloudflared/config.yml << EOF
tunnel: YOUR_TUNNEL_ID
credentials-file: /Users/$USER/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: ollama.yourdomain.com
    service: http://localhost:11434
  - service: http_status:404
EOF

# Run tunnel (or set up as service)
cloudflared tunnel run ollama-mac
```

Then in admin panel use:
- Hostname: `ollama.yourdomain.com`
- Port: `443` (HTTPS)

**No port forwarding, no dynamic IP issues, more secure!**

## Quick Commands Reference

```bash
# Check public IP
curl -4 ifconfig.me

# Check Ollama listening
lsof -i :11434 -P -n | grep LISTEN

# Test Ollama locally
curl http://localhost:11434/api/tags

# Test via public IP (from Mac using public IP)
curl http://YOUR_PUBLIC_IP:11434/api/tags

# Check macOS firewall status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# Monitor connections (see who's connecting)
sudo tcpdump -i any port 11434 -nn
```

## Security Reminder

Once you expose Ollama to the internet:

1. ✅ Enable macOS firewall
2. ✅ Monitor access (check who's connecting)
3. ✅ Consider IP allowlist (only Ubuntu server)
4. ✅ Use Cloudflare Tunnel for better security
5. ✅ Keep Ollama updated

**Ollama has no authentication** - anyone with your IP can use it!

## Next: Add to Admin Panel

Once port forwarding works, add to admin panel:

```
Name: Mac Studio (Home)
Type: ollama
Hostname: YOUR_PUBLIC_IP
Port: 11434
Public: ✓
```

Or if using DDNS/Cloudflare:
```
Hostname: yourname.duckdns.org
# or
Hostname: ollama.yourdomain.com
```

## Windows PC Later

When ready to add Windows:
- External port: **11435** (different from Mac!)
- Internal IP: `YOUR_WINDOWS_LOCAL_IP`
- Internal port: `11434`

Then in admin panel use port `11435` for Windows.
