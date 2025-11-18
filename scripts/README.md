# Deployment Scripts

This directory contains deployment and setup scripts for the Halext Org production environment.

## OpenWebUI Setup Script

The `setup-openwebui.sh` script automates the deployment of OpenWebUI with Ollama on an Ubuntu server.

### Features

- **Automated Installation**: Installs Docker, Ollama, and OpenWebUI
- **Model Management**: Downloads default AI models (llama3.1, mistral)
- **Nginx Integration**: Configures reverse proxy for `/webui/` path
- **Systemd Service**: Sets up automatic startup and management
- **Firewall Configuration**: Configures UFW rules for Ollama
- **Production Ready**: Includes WebSocket support, timeouts, and buffering

### Prerequisites

- Ubuntu 20.04 LTS or newer
- Root or sudo access
- Domain name configured (default: org.halext.org)
- Nginx installed (or script will install it)

### Usage

1. **Copy script to server**:
   ```bash
   scp scripts/setup-openwebui.sh user@org.halext.org:~
   ```

2. **Run on server**:
   ```bash
   ssh user@org.halext.org
   sudo bash setup-openwebui.sh
   ```

3. **Optional: Custom domain**:
   ```bash
   sudo DOMAIN=yourdomain.com bash setup-openwebui.sh
   ```

### Post-Installation Steps

After the script completes, you need to:

1. **Configure Nginx**:
   ```bash
   sudo nano /etc/nginx/sites-available/org.halext.org
   ```

   Add inside the `server { }` block:
   ```nginx
   include /etc/nginx/sites-available/openwebui.conf;
   ```

2. **Reload Nginx**:
   ```bash
   sudo systemctl reload nginx
   ```

3. **Update Backend Configuration**:

   Edit `/path/to/halext-org/backend/.env`:
   ```bash
   AI_PROVIDER=openwebui
   OPENWEBUI_URL=http://localhost:3000
   ```

   Or for Ollama direct:
   ```bash
   AI_PROVIDER=ollama
   OLLAMA_URL=http://localhost:11434
   ```

4. **Restart Backend**:
   ```bash
   sudo systemctl restart halext-backend
   ```

5. **Create Admin Account**:
   - Visit https://org.halext.org/webui/
   - Create the first user account (will be admin)

### What Gets Installed

- **Docker & Docker Compose**: Container runtime
- **Ollama**: Local AI model runtime
- **OpenWebUI**: Web interface for AI chat
- **AI Models**: llama3.1, mistral
- **Systemd Service**: Auto-start on boot
- **Nginx Config**: Reverse proxy at `/webui/`

### Directory Structure

```
/opt/openwebui/
  ├── docker-compose.yml      # Docker Compose configuration

/var/lib/openwebui/           # OpenWebUI data directory
  ├── data/                   # User data, conversations, settings

/etc/nginx/sites-available/
  └── openwebui.conf          # Nginx reverse proxy config

/etc/systemd/system/
  └── openwebui.service       # Systemd service unit
```

### Management Commands

```bash
# Start OpenWebUI
sudo systemctl start openwebui

# Stop OpenWebUI
sudo systemctl stop openwebui

# Restart OpenWebUI
sudo systemctl restart openwebui

# Check status
sudo systemctl status openwebui

# View logs
sudo docker logs -f openwebui

# View Ollama logs
sudo journalctl -u ollama -f
```

### Managing AI Models

```bash
# List installed models
ollama list

# Pull a new model
ollama pull <model-name>

# Examples:
ollama pull codellama
ollama pull deepseek-coder
ollama pull llama2

# Remove a model
ollama rm <model-name>
```

### Troubleshooting

#### OpenWebUI not accessible

Check container status:
```bash
sudo docker ps | grep openwebui
sudo docker logs openwebui
```

#### Ollama connection errors

Check Ollama service:
```bash
sudo systemctl status ollama
curl http://localhost:11434/api/tags
```

#### Nginx 502 Bad Gateway

Verify OpenWebUI is running on port 3000:
```bash
curl http://localhost:3000
sudo netstat -tlnp | grep 3000
```

#### Model download fails

Check disk space and network:
```bash
df -h
ping ollama.com
sudo journalctl -u ollama -f
```

### Security Considerations

1. **Firewall**: Only Ollama port (11434) is exposed
2. **Authentication**: OpenWebUI requires user accounts
3. **Reverse Proxy**: OpenWebUI only accessible via Nginx
4. **Data Isolation**: User data stored in `/var/lib/openwebui`
5. **HTTPS**: Use Certbot/Let's Encrypt for SSL certificates

### Backup and Restore

**Backup OpenWebUI data**:
```bash
sudo tar -czf openwebui-backup-$(date +%Y%m%d).tar.gz /var/lib/openwebui
```

**Restore data**:
```bash
sudo systemctl stop openwebui
sudo tar -xzf openwebui-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start openwebui
```

### Uninstallation

```bash
# Stop and remove OpenWebUI
sudo systemctl stop openwebui
sudo systemctl disable openwebui
cd /opt/openwebui && sudo docker compose down -v

# Remove files
sudo rm -rf /opt/openwebui
sudo rm -rf /var/lib/openwebui
sudo rm /etc/systemd/system/openwebui.service
sudo rm /etc/nginx/sites-available/openwebui.conf

# Remove Ollama (optional)
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm /usr/local/bin/ollama
sudo rm -rf /usr/share/ollama
```

### Resources

- OpenWebUI Documentation: https://docs.openwebui.com
- Ollama Models: https://ollama.com/library
- Ollama Documentation: https://github.com/ollama/ollama

---

## macOS Ollama Server Setup

### macOS Ollama Server Setup Script

**File:** `macos-ollama-server-setup.sh`

**Purpose:** Configure your macOS to serve Ollama models to your Ubuntu org.halext.org server

**Run on:** Your Mac (the machine with Ollama installed)

**Usage:**
```bash
./scripts/macos-ollama-server-setup.sh
```

**What it does:**
- Detects existing Ollama processes and configuration
- Shows current network binding status
- Offers two setup options:
  1. Configure Ollama.app for network access (recommended)
  2. Set up Launch Agent for background service
- Verifies firewall settings
- Tests local API connectivity
- Displays next steps for Ubuntu server

**When to use:**
- First time setup of Mac as Ollama server
- When you need to reconfigure network settings
- To verify current configuration status (Option 3)
- After macOS updates or Ollama updates

### Ubuntu Connectivity Test Script

**File:** `ubuntu-test-mac-ollama.sh`

**Purpose:** Test connectivity from Ubuntu server to macOS Ollama instance

**Run on:** Your Ubuntu server (org.halext.org)

**Usage:**
```bash
./scripts/ubuntu-test-mac-ollama.sh <mac-ip-address>
```

**Example:**
```bash
./scripts/ubuntu-test-mac-ollama.sh 192.168.1.204
```

**What it does:**
- Tests network connectivity (ping)
- Checks port 11434 accessibility
- Queries Ollama API for available models
- Optionally tests model generation
- Provides curl commands to add Mac as client

**When to use:**
- After running macOS setup script
- Before adding Mac to admin panel
- When troubleshooting connectivity issues
- To verify network configuration changes

### Quick Start: Distributed Ollama Setup

1. **On your Mac:**
   ```bash
   cd ~/Code/halext-org
   ./scripts/macos-ollama-server-setup.sh
   ```
   - Choose Option 1 (Ollama.app) or Option 2 (Launch Agent)
   - Note your Mac's IP address (e.g., 192.168.1.204)
   - Restart Ollama.app if using Option 1

2. **On your Ubuntu server:**
   ```bash
   # SSH into server
   ssh user@org.halext.org

   # Test connectivity
   ./scripts/ubuntu-test-mac-ollama.sh 192.168.1.204
   ```

3. **Via Web Admin Panel:**
   - Go to https://org.halext.org
   - Login and click Admin Panel icon
   - Click "Add Client"
   - Fill in Mac's details (hostname: 192.168.1.204, port: 11434)
   - Click "Add Client"

### Comprehensive Documentation

See **[docs/DISTRIBUTED_OLLAMA_SETUP.md](../docs/DISTRIBUTED_OLLAMA_SETUP.md)** for:
- Complete architecture overview
- Detailed setup instructions
- Network configuration
- Security considerations
- Advanced configuration options
- Comprehensive troubleshooting guide

### Common Issues with macOS Ollama Server

**Issue: "Ollama is only listening on localhost"**

Solution:
```bash
# Run setup script and choose Option 1
./scripts/macos-ollama-server-setup.sh

# Quit Ollama.app
# Restart Ollama.app
# Run script again to verify (Option 3)
```

**Issue: "Port 11434 is not accessible from Ubuntu"**

Check:
1. Mac firewall settings
2. Router firewall
3. Network connectivity

Solution:
```bash
# On Mac - check what's listening
lsof -i :11434 -P -n

# Should show *:11434 not 127.0.0.1:11434
```

**Issue: "Multiple Ollama processes running"**

Solution:
```bash
# Check what's running
ps aux | grep ollama
lsof -i :11434 -P -n

# Kill all Ollama processes
pkill -f ollama

# Restart using your preferred method
```
