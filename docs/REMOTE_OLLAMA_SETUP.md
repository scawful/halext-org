# Remote Ollama Setup - Exposing Home Machines to Cloud Server

Guide for exposing your home Mac (and Windows PC) Ollama servers to your remote Ubuntu cloud server.

## Architecture Overview

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
│                  Verizon 5G Router                          │
│                  Public IP: YOUR_PUBLIC_IP                  │
│                  Port Forward: 11434 → YOUR_MAC_LOCAL_IP:11434 │
│                                                              │
│     ┌──────────────────────────┬──────────────────────┐    │
│     │                          │                       │    │
│  ┌──▼───────────────┐   ┌──────▼──────────┐          │    │
│  │  Mac Studio       │   │  Windows PC     │          │    │
│  │  YOUR_MAC_LOCAL_IP    │   │  YOUR_WINDOWS_LOCAL_IP  │          │    │
│  │  Ollama Server    │   │  Ollama Server  │          │    │
│  │  llama3.1, etc.   │   │  deepseek, etc. │          │    │
│  └──────────────────┘   └─────────────────┘          │    │
│                                                              │
│                    Home Network                             │
└─────────────────────────────────────────────────────────────┘
```

## Quick Facts

- **Your Public IPv4:** `YOUR_PUBLIC_IP`
- **Your Public IPv6:** `YOUR_PUBLIC_IPV6`
- **Router:** Verizon 5G Home Internet
- **Mac Local IP:** `YOUR_MAC_LOCAL_IP`
- **Ubuntu Server:** Remote VPS (different network)
- **Required Port:** `11434` (Ollama default)

## Setup Steps

### Part 1: Configure Verizon 5G Router Port Forwarding

#### Access Router Admin

1. **Find your router's admin page:**
   - Usually: `http://192.168.1.1` or `http://192.168.0.1`
   - Or check the label on your Verizon router
   - Default login is usually printed on router

2. **Login to router:**
   - Username: (check router label or manual)
   - Password: (check router label or manual)

#### Set Up Port Forwarding

1. **Navigate to Port Forwarding:**
   - Look for: "Port Forwarding", "Virtual Server", "NAT", or "Advanced" section
   - Different Verizon models have different menu layouts

2. **Create Port Forward Rule for Mac:**
   ```
   Service Name: Ollama Mac
   External Port: 11434
   Internal IP: YOUR_MAC_LOCAL_IP (your Mac's local IP)
   Internal Port: 11434
   Protocol: TCP
   Enabled: Yes
   ```

3. **Save the configuration**

4. **Optional: Create rule for Windows PC (when ready):**
   ```
   Service Name: Ollama Windows
   External Port: 11435 (use different port!)
   Internal IP: YOUR_WINDOWS_LOCAL_IP (your Windows PC local IP)
   Internal Port: 11434
   Protocol: TCP
   Enabled: Yes
   ```

   **Note:** Since you can't forward the same external port to two devices, use 11435 for Windows.

#### Common Verizon Router Interfaces

**LTE Home Router (ASK-NCQ1338):**
- Go to: Advanced → Port Forwarding
- Click "Add Rule"

**5G Home Router (LVSKIHP):**
- Go to: Advanced Settings → Port Management → Port Forwarding
- Click "+" to add rule

**If you can't find it:**
- Check: `http://192.168.1.1/login.html`
- Or consult: https://www.verizon.com/support/residential/internet/home-network/advanced-features

### Part 2: Test Port Forwarding

#### From Your Mac (Test Locally)

```bash
# Verify Ollama is listening on all interfaces
lsof -i :11434 -P -n | grep LISTEN
# Should show: *:11434 (not 127.0.0.1:11434)

# Test local access
curl http://localhost:11434/api/tags
```

#### From Another Device on Different Network

Use your phone's cellular data (not home WiFi) to test:

```bash
# From phone browser or another device NOT on your home network
curl http://YOUR_PUBLIC_IP:11434/api/tags
```

Or use an online port checker:
- https://www.yougetsignal.com/tools/open-ports/
- Enter IP: `YOUR_PUBLIC_IP`
- Enter Port: `11434`
- Should show: "Port is open"

#### From Your Ubuntu Server

```bash
# SSH into org.halext.org
ssh user@org.halext.org

# Test connectivity
curl http://YOUR_PUBLIC_IP:11434/api/tags

# Should return JSON with your models
```

### Part 3: Handle Dynamic IP (Optional but Recommended)

Verizon 5G Home Internet may change your public IP periodically.

#### Option 1: Dynamic DNS (DDNS) - Recommended

Use a free DDNS service to get a stable hostname:

**DuckDNS (Free, Recommended):**

1. Go to https://www.duckdns.org/
2. Sign in with GitHub/Google
3. Create a domain: `yourname.duckdns.org`
4. Install updater on your Mac:

```bash
# Create update script
mkdir -p ~/duckdns
cd ~/duckdns

# Get your DuckDNS token from the website
TOKEN="your-duckdns-token-here"
DOMAIN="yourname"

# Create update script
cat > duck.sh << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=" | curl -k -o ~/duckdns/duck.log -K -
EOF

chmod +x duck.sh

# Test it
./duck.sh
cat duck.log  # Should show "OK"

# Add to crontab (updates every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1") | crontab -
```

Now use `yourname.duckdns.org` instead of IP address!

**No-IP (Free tier available):**
- https://www.noip.com/
- Similar setup process

#### Option 2: Check IP Periodically

Create a script to monitor your public IP:

```bash
#!/bin/bash
# save as ~/check-ip.sh

CURRENT_IP=$(curl -4 -s ifconfig.me)
LAST_IP_FILE="$HOME/.last_public_ip"

if [ -f "$LAST_IP_FILE" ]; then
    LAST_IP=$(cat "$LAST_IP_FILE")
else
    LAST_IP=""
fi

if [ "$CURRENT_IP" != "$LAST_IP" ]; then
    echo "IP changed from $LAST_IP to $CURRENT_IP"
    echo "$CURRENT_IP" > "$LAST_IP_FILE"

    # Optional: Send notification
    # curl -X POST your-webhook-url -d "IP changed to $CURRENT_IP"
else
    echo "IP unchanged: $CURRENT_IP"
fi
```

Run daily:
```bash
chmod +x ~/check-ip.sh
(crontab -l 2>/dev/null; echo "0 */6 * * * ~/check-ip.sh") | crontab -
```

### Part 4: Security Considerations

Since you're exposing Ollama to the internet, consider these security measures:

#### 1. Firewall Rules (macOS)

Enable macOS firewall and allow only Ollama:

```bash
# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Allow Ollama
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add $(which ollama)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp $(which ollama)
```

#### 2. Rate Limiting (Optional)

Add nginx reverse proxy on Mac to rate limit:

```bash
# Install nginx
brew install nginx

# Configure reverse proxy with rate limiting
# /usr/local/etc/nginx/nginx.conf
```

Example nginx config:
```nginx
http {
    limit_req_zone $binary_remote_addr zone=ollama:10m rate=10r/s;

    server {
        listen 11434;

        location / {
            limit_req zone=ollama burst=20;
            proxy_pass http://127.0.0.1:11435;  # Ollama on different port
        }
    }
}
```

#### 3. IP Allowlist (Recommended)

**On Router (if supported):**
- Some routers allow source IP filtering
- Whitelist only your Ubuntu server's IP

**On macOS (using pf firewall):**

```bash
# Create pf rules file
sudo nano /etc/pf.conf

# Add at the end:
# Allow Ubuntu server IP only
pass in proto tcp from <UBUNTU_SERVER_IP> to any port 11434
block in proto tcp to any port 11434
```

Replace `<UBUNTU_SERVER_IP>` with your Ubuntu server's public IP.

```bash
# Enable pf
sudo pfctl -e -f /etc/pf.conf
```

#### 4. Use Cloudflare Tunnel (Most Secure - Recommended)

Instead of port forwarding, use Cloudflare Tunnel for secure access:

**Advantages:**
- No port forwarding needed
- No exposed public IP
- Free SSL/TLS encryption
- DDoS protection
- Access control

**Setup:**
```bash
# Install cloudflared on Mac
brew install cloudflare/cloudflare/cloudflared

# Login
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create ollama-mac

# Configure tunnel
cat > ~/.cloudflared/config.yml << EOF
tunnel: <tunnel-id>
credentials-file: /Users/$USER/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: ollama-mac.yourdomain.com
    service: http://localhost:11434
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run ollama-mac
```

Then use `https://ollama-mac.yourdomain.com` instead of public IP!

#### 5. Monitor Access (Optional)

Create a simple access log:

```bash
# Monitor connections to port 11434
sudo tcpdump -i any port 11434 -nn | tee ~/ollama-access.log
```

Or use Ollama's built-in logging.

### Part 5: Update Admin Panel Configuration

#### When Adding Mac to Admin Panel

Use your **public IP or DDNS hostname**:

**Using Public IP:**
```
Name: Mac Studio (Home)
Type: ollama
Hostname: YOUR_PUBLIC_IP  ← Your public IP
Port: 11434
Public: ✓
```

**Using DDNS (Recommended):**
```
Name: Mac Studio (Home)
Type: ollama
Hostname: yourname.duckdns.org  ← Your DDNS hostname
Port: 11434
Public: ✓
```

**Using Cloudflare Tunnel (Most Secure):**
```
Name: Mac Studio (Home)
Type: ollama
Hostname: ollama-mac.yourdomain.com  ← Your tunnel hostname
Port: 443  ← HTTPS port
Public: ✓
```

### Part 6: Windows PC Setup

When you're ready to add your Windows gaming PC:

#### Port Forwarding Option
```
External Port: 11435  ← Different port!
Internal IP: YOUR_WINDOWS_LOCAL_IP  ← Windows PC local IP
Internal Port: 11434  ← Ollama's default port
```

Then in admin panel:
```
Hostname: YOUR_PUBLIC_IP (or yourname.duckdns.org)
Port: 11435  ← External port
```

#### DDNS Subdomain Option
```
mac.yourname.duckdns.org → YOUR_PUBLIC_IP:11434
windows.yourname.duckdns.org → YOUR_PUBLIC_IP:11435
```

#### Cloudflare Tunnel Option (Best)
```
ollama-mac.yourdomain.com → Mac on port 11434
ollama-windows.yourdomain.com → Windows on port 11434
```

No port conflicts, no port forwarding needed!

## Testing Checklist

- [ ] Ollama running on Mac and listening on `0.0.0.0:11434`
- [ ] Port forwarding configured on router
- [ ] Port 11434 open on public IP (test with port checker)
- [ ] Can access from Ubuntu: `curl http://YOUR_PUBLIC_IP:11434/api/tags`
- [ ] DDNS configured (optional but recommended)
- [ ] Security measures in place (firewall, IP allowlist, or Cloudflare)
- [ ] Mac added to admin panel with public IP/hostname
- [ ] Admin panel shows Mac as "online"
- [ ] Can send chat messages using Mac's models

## Troubleshooting

### Can't Access from Ubuntu

**Check 1: Is Ollama listening correctly?**
```bash
# On Mac
lsof -i :11434 -P -n | grep LISTEN
# Should show: *:11434
```

**Check 2: Is port forwarding working?**
```bash
# From your phone (cellular data, not WiFi)
curl http://YOUR_PUBLIC_IP:11434/api/tags
```

**Check 3: Is router port forward rule enabled?**
- Login to router admin
- Verify rule is active
- Some routers require reboot

**Check 4: Is ISP blocking port?**
- Verizon may block some ports
- Try different port (e.g., 8080 external → 11434 internal)
- Or use Cloudflare Tunnel

### Connection Works Sometimes, Fails Other Times

**Likely Cause:** Dynamic IP changed

**Solution:**
- Set up DDNS (DuckDNS recommended)
- Use Cloudflare Tunnel
- Or check IP and update admin panel when it changes

### Security Concerns

**Question:** Is it safe to expose Ollama to internet?

**Answer:** With proper security:
1. Use Cloudflare Tunnel (best option)
2. Or use IP allowlist + firewall
3. Keep Ollama updated
4. Monitor access logs
5. Disable if not actively using

**Ollama has no built-in authentication**, so it's important to use one of the security measures above.

## Recommended Setup

For best security and reliability:

1. ✅ **Use Cloudflare Tunnel** (no port forwarding needed)
2. ✅ **Set up DDNS** as backup
3. ✅ **Enable macOS Firewall**
4. ✅ **Monitor access logs**
5. ✅ **Keep Ollama updated**

## Cost Considerations

- **Port Forwarding:** Free
- **DDNS (DuckDNS):** Free
- **Cloudflare Tunnel:** Free
- **Verizon 5G Home Internet:** Your existing plan (no extra cost)

## Future: Windows PC Setup

Same process:
1. Install Ollama on Windows
2. Configure to listen on `0.0.0.0:11434`
3. Add port forward: `11435 → YOUR_WINDOWS_LOCAL_IP:11434`
4. Add to admin panel with port `11435`
5. Or use separate Cloudflare Tunnel

## Next Steps

1. Set up port forwarding on Verizon router
2. Test from Ubuntu server
3. (Recommended) Set up DuckDNS
4. (Optional) Set up Cloudflare Tunnel for better security
5. Add Mac to admin panel with public IP/hostname
6. Test AI chat
7. Repeat for Windows PC when ready
