# Halext.org Quickstart Guide

Get your distributed AI system running in **15 minutes**.

## Prerequisites

- **Cloud Server:** Ubuntu 20.04+ with 2GB RAM minimum
- **Home Computer:** Mac (M1/M2/M3) or Windows PC with 16GB+ RAM
- **Router Access:** Ability to configure port forwarding
- **Domain:** Optional but recommended

---

## Quick Overview

We're building this:
```
Internet → Ubuntu Server → Your Mac/PC (running AI models)
```

---

## Step 1: Clone the Repository (2 minutes)

### On Your Mac/Local Machine:
```bash
git clone https://github.com/scawful/halext-org.git
cd halext-org
```

### On Your Ubuntu Server:
```bash
cd /srv
sudo mkdir -p halext.org
sudo chown $USER:$USER halext.org
cd halext.org
git clone https://github.com/scawful/halext-org.git
cd halext-org
```

---

## Step 2: Setup Ubuntu Server (5 minutes)

### Install Dependencies:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python, PostgreSQL, Nginx
sudo apt install -y python3 python3-pip python3-venv postgresql nginx

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### Setup Database:
```bash
# Create PostgreSQL database
sudo -u postgres psql -c "CREATE DATABASE halext_db;"
sudo -u postgres psql -c "CREATE USER halext WITH PASSWORD 'your_secure_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE halext_db TO halext;"
```

### Setup Backend:
```bash
cd /srv/halext.org/halext-org/backend

# Create virtual environment
python3 -m venv env
source env/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql://halext:your_secure_password@localhost/halext_db
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
EOF

# Run migrations
python migrations/add_api_keys.py

# Create first user
python -c "
from app.database import SessionLocal
from app import crud, schemas
db = SessionLocal()
user = crud.create_user(db, schemas.UserCreate(
    username='admin',
    email='admin@halext.org',
    password='changeme123'
))
print(f'Created user: {user.username}')
"
```

### Setup Frontend:
```bash
cd /srv/halext.org/halext-org/frontend
npm install
npm run build
```

### Configure Nginx:
```bash
sudo nano /etc/nginx/sites-available/halext
```

Paste this configuration:
```nginx
server {
    listen 80;
    server_name org.halext.org;  # Change to your domain

    # Frontend
    location / {
        root /srv/halext.org/halext-org/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/halext /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Create Systemd Service:
```bash
sudo nano /etc/systemd/system/halext-backend.service
```

Paste:
```ini
[Unit]
Description=Halext Backend API
After=network.target postgresql.service

[Service]
Type=simple
User=halext
WorkingDirectory=/srv/halext.org/halext-org/backend
Environment="PATH=/srv/halext.org/halext-org/backend/env/bin"
ExecStart=/srv/halext.org/halext-org/backend/env/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable halext-backend
sudo systemctl start halext-backend
sudo systemctl status halext-backend
```

---

## Step 3: Setup Mac as AI Node (5 minutes)

### Install Ollama:
```bash
# Download from https://ollama.ai or use brew:
brew install ollama

# Pull some models
ollama pull qwen2.5-coder:14b
ollama pull llama3
ollama pull mistral
```

### Configure Ollama for Network Access:
```bash
# Run the setup script
cd ~/Code/halext-org
./scripts/macos-ollama-server-setup.sh
```

Or manually:
```bash
# Set environment variables
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
launchctl setenv OLLAMA_ORIGINS "*"

# Restart Ollama
pkill ollama
# Relaunch Ollama.app from Applications
```

### Verify Ollama is Running:
```bash
lsof -i :11434 -P -n | grep LISTEN
# Should show: ollama ... *:11434 (LISTEN)

curl http://localhost:11434/api/tags
# Should return JSON with your models
```

---

## Step 4: Configure Port Forwarding (2 minutes)

### Find Your Mac's Local IP:
```bash
ipconfig getifaddr en0
# Example: 192.168.1.204
```

### Setup Port Forwarding on Router:

1. Access your router admin panel (usually `192.168.1.1` or `192.168.0.1`)
2. Find "Port Forwarding" or "NAT" settings
3. Add this rule:

| Field | Value |
|-------|-------|
| Application | Mac Ollama |
| Original Port | 11434 |
| Protocol | TCP |
| Fwd to Addr | 192.168.1.204 (your Mac's IP) |
| Fwd to Port | 11434 |
| Schedule | Always |

4. **Save and reboot your router**

### Test Port Forwarding:
```bash
# From your Ubuntu server
curl http://YOUR_PUBLIC_IP:11434/api/tags

# Should return your Mac's models
```

---

## Step 5: Add Mac to Admin Panel (1 minute)

### Access Admin Panel:
1. Go to `https://org.halext.org`
2. Login with: username=`admin`, password=`changeme123`
3. Click the **Admin Panel** icon in the sidebar

### Add AI Client:
1. Click **"Add Client"**
2. Fill in:
   - **Name:** Mac M1 Studio
   - **Type:** ollama
   - **Hostname/IP:** YOUR_PUBLIC_IP (e.g., `75.250.120.205`)
   - **Port:** 11434
   - **Make public:** ✓ (if you want all users to access it)
3. Click **"Add Client"**

### Test Connection:
Click the **"Test"** button next to your Mac node. You should see:
- Status: 🟢 Online
- Models: All your loaded models
- Response time: ~50-200ms

---

## 🎉 Done!

Your distributed AI system is now live!

### What You Can Do Now:

1. **Chat with AI Models**
   - Go to Chat section
   - Select a model from your Mac
   - Start conversing

2. **Manage Tasks**
   - Create tasks
   - Get AI suggestions
   - Track progress

3. **Monitor Nodes**
   - View real-time status in Admin Panel
   - See which models are loaded
   - Check response times

---

## Next Steps

### Security (Important!)

1. **Change default password:**
```bash
# In admin panel, go to Settings → Change Password
```

2. **Add SSL certificate:**
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d org.halext.org
```

3. **Enable firewall:**
```bash
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

4. **Restrict Ollama access:**
Add IP allowlist to your Mac's firewall or use Cloudflare Tunnel (see [REMOTE_OLLAMA_SETUP.md](REMOTE_OLLAMA_SETUP.md))

### Add More Features

- **Add Windows PC:** Repeat Step 3-5 with port 11435
- **Setup Monitoring:** See [docs/operations/monitoring.md](operations/monitoring.md) (TODO)
- **Enable Caching:** Setup Redis for faster responses
- **API Access:** Create API keys in admin panel

---

## Troubleshooting

### Backend Not Starting
```bash
# Check logs
sudo journalctl -u halext-backend -f

# Common issues:
# 1. Database connection failed → Check DATABASE_URL in .env
# 2. Port 8000 in use → Change port in systemd service
# 3. Import errors → Reinstall: pip install -r requirements.txt
```

### Frontend Not Loading
```bash
# Check Nginx
sudo nginx -t
sudo systemctl status nginx

# Rebuild frontend
cd /srv/halext.org/halext-org/frontend
npm run build
```

### Can't Connect to Mac
```bash
# 1. Check Ollama is running on Mac
lsof -i :11434

# 2. Check port forwarding
# Try accessing from mobile data: http://YOUR_PUBLIC_IP:11434/api/tags

# 3. Check Mac firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

### Models Loading Slow
```bash
# On Mac - Ollama uses a lot of memory
# Check memory usage:
ps aux | grep ollama

# Unload unused models:
ollama stop
ollama serve  # Restarts fresh
```

For more issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Getting Help

- **Issues:** https://github.com/scawful/halext-org/issues
- **Discussions:** https://github.com/scawful/halext-org/discussions
- **Email:** scawful@halext.org

---

## What's Next?

Now that your system is running, explore:

- [Architecture Overview](ARCHITECTURE_OVERVIEW.md) - Understand how it all works
- [Distributed Ollama Setup](DISTRIBUTED_OLLAMA_SETUP.md) - Advanced node configuration
- [Port Forwarding Guide](../PORT_FORWARDING_GUIDE.md) - Detailed router setup
- [Emergency Recovery](EMERGENCY_SERVER_RECOVERY.md) - When things break

---

**Estimated Setup Time:** 15 minutes
**Difficulty:** Intermediate
**Last Updated:** 2025-11-18
