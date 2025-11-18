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
