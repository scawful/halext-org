# Deployment & Operations Scripts

This directory collects every helper shell script used across Halext Org. The files now live in one place, so use the quick index below to find the tool you need before SSHing into a box or running automation locally.

## Quick Category Index

| Category | Key Scripts | Notes |
| --- | --- | --- |
| **Deploy & Sync** | `server-deploy.sh`, `server-deploy-bg.sh`, `server-sync.sh`, `server-init.sh`, `setup-org.sh`, `deploy-to-ubuntu.sh` (`.example`), `deploy-frontend-fast.sh`, `deploy-frontend-local.sh`, `update-halext.sh` | Fast-forward the repo, rebuild assets, and restart services both locally and on Ubuntu.
| **Server Setup & Access** | `setup-ubuntu.sh`, `setup-openwebui.sh`, `setup-ssh-key.sh`, `copy-ssh-key-to-halext.sh`, `promote-halext-user.sh`, `migrate-presets-schema.sh`, `cloudflare-certbot.sh`, `site-health-check.sh` | Bootstrap infrastructure, manage credentials, and patch servers in place.
| **macOS Automation** | `macos-sync.sh` (`macos-sync.env.example`), `macos-ollama-setup.sh`, `macos-ollama-server-setup.sh`, `refresh-halext.sh`, `dev-backend.sh` | Keep the local launchd/dev environments aligned with production expectations.
| **Emergency & Diagnostics** | `emergency-ubuntu-cleanup.sh` (`.example`), `emergency-kill-ollama.sh`, `full-reset.sh`, `ubuntu-diagnose-performance.sh`, `ubuntu-test-mac-ollama.sh`, `sync-halext-perms.sh`, `fix-403.sh` | Recover from out-of-memory incidents, nginx breakage, or stubborn file-permission problems.
| **Utilities & Misc** | `rename-project.sh`, `import_pico_blog.py`, `promote-halext-user.sh`, `site-health-check.sh`, `cloudflare-certbot.sh` | One-off helpers for renames, content imports, certificate refresh, or smoke tests.

## Deploy & Sync
- `server-deploy.sh` – single-command backend/frontend rebuild + service restart; used by `server-sync.sh`.
- `server-deploy-bg.sh` – runs `server-deploy.sh` in the background with logging so you can detach.
- `server-sync.sh` – fast-forwards the repo, rebuilds assets, restarts `halext-api`/OpenWebUI/nginx, and performs HTTP health checks.
- `server-init.sh` / `setup-org.sh` – first-time bootstrap scripts that wire up systemd services, nginx, and the Postgres database.
- `deploy-to-ubuntu.sh` (`deploy-to-ubuntu.sh.example`) – fully automated mac → Ubuntu deployment with prompts (copy `.example` and customize for your host).
- `deploy-frontend-fast.sh` / `deploy-frontend-local.sh` – build the SPA locally then rsync to `/var/www/halext` when the server is underpowered.
- `update-halext.sh` – convenience wrapper for pulling latest code, restarting the API, and checking health endpoints.

## Server Setup & Access
- `setup-ubuntu.sh` – installs base packages, systemd units, nginx vhosts, and the Python virtualenv for a fresh VM.
- `setup-openwebui.sh` – full OpenWebUI + Ollama provisioning script (see detailed guide below).
- `setup-ssh-key.sh` / `copy-ssh-key-to-halext.sh` – add local SSH keys to the `halext` user (automated and manual workflows).
- `promote-halext-user.sh` – ensures the `halext` unix account has sudo + group memberships.
- `migrate-presets-schema.sh` – runs the Alembic migration for layout presets on production.
- `cloudflare-certbot.sh` – issues/renews TLS certificates using the Cloudflare DNS plugin.
- `site-health-check.sh` – curl/HTTP health probe bundle for the SPA and API endpoints.

## macOS Automation
- `macos-sync.sh` (+ `macos-sync.env.example`) – verifies Python/Node deps, restarts launchd services or dev scripts, and optionally SSHs into production to run `server-sync.sh`.
- `macos-ollama-setup.sh` & `macos-ollama-server-setup.sh` – configure LaunchAgents that keep Ollama listening on `0.0.0.0:11434` for remote routing.
- `refresh-halext.sh` – reloads the macOS launch agents (`org.halext.api`/`org.halext.frontend`).
- `dev-backend.sh` – helper for running just the FastAPI backend with the right environment variables.

## Emergency & Diagnostics
- `emergency-ubuntu-cleanup.sh` (+ `.example`) – aggressive clean-up (kill Ollama, restart Docker, drop caches) for when the VPS is unresponsive.
- `emergency-kill-ollama.sh` – force-stop Ollama when it consumes too many resources.
- `full-reset.sh` – nukes launch agents, rebuilds node_modules/venv, and restarts everything.
- `ubuntu-diagnose-performance.sh` – captures CPU, memory, and IO stats to `/tmp` for later review.
- `ubuntu-test-mac-ollama.sh` – probes remote Ollama endpoints from Ubuntu to ensure port-forwarding/tunnels still work.
- `sync-halext-perms.sh` – resets file ownership on known paths (fixes npm build permission errors).
- `fix-403.sh` – removes stray certbot/nginx blocks that cause permission errors.

## Utilities & Miscellaneous
- `rename-project.sh` – batch-renames Halext → new branding across files.
- `import_pico_blog.py` – imports Pico blog entries into the CMS.
- `cloudflare-certbot.sh` – Cloudflare DNS automation for certbot (if not run via `setup-openwebui.sh`).
- `site-health-check.sh` – HTTP smoke tests for SPA/API (handy for CI or cron).

## Detailed guide: `setup-openwebui.sh`

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
   OPENWEBUI_PUBLIC_URL=https://org.halext.org/webui/
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

Follow your existing VM snapshot or rsync procedures to back up `/opt/openwebui` and `/var/lib/openwebui` before major upgrades.
