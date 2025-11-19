# Halext Server Operations Guide

## Key Paths & Services
- **Repo root:** `/srv/halext.org/halext-org` (`backend/`, `frontend/`, `scripts/`, `infra/`).
- **Static SPA:** `/var/www/halext` (synced from `frontend/dist`).
- **Legacy PHP roots:** `/www/<domain>/public`.
- **Nginx config:** `/etc/nginx/nginx.conf`, includes from `/etc/nginx/sites/*.conf`, snippets under `/etc/nginx/{global,ssl,php}`.
- **Systemd units:** `halext-api.service` (Uvicorn on `127.0.0.1:8000`), `openwebui.service`.

## Deploy / Recovery Workflow
1. `cd /srv/halext.org/halext-org && git pull`.
2. Backend deps/migrations:
   ```bash
   cd backend
   source env/bin/activate
   pip install -r requirements.txt
   alembic upgrade head  # when migrations ship
   ```
3. Frontend build + sync:
   ```bash
   cd frontend
   npm install
   npm run build
   sudo rsync -a --delete dist/ /var/www/halext/
   sudo chown -R www-data:www-data /var/www/halext
   ```
4. Reload services:
   ```bash
   sudo systemctl restart halext-api
   sudo nginx -t && sudo systemctl reload nginx
   ```
   `./scripts/server-deploy.sh` and `./scripts/server-sync.sh` automate the same steps with health checks.

## Quick Commands
- `journalctl -u halext-api -f` or `systemctl status halext-api`.
- `sudo tail -f /var/log/nginx/{access,error}.log`.
- `nginxctl test|reload|restart`, `nginxctl host org.halext.org [https]`.
- Verify DB: `sudo -u postgres psql -c '\l'`.

## Common Issues
- **403 on root:** ensure only `sites/org.halext.org.conf` serves the host; remove stray certbot stubs, `sudo nginx -t` then reload.
- **Frontend NetworkError:** confirm SPA fetches `window.location.origin + '/api'`; rebuild + rsync if fallback host sneaks in.
- **Build perms:** if `npm run build` fails with EACCES, repair ownership on `frontend/node_modules`, `.vite-temp`, `dist` (`sudo chown -R justin:halext` ...).
- **Leaked dotfiles:** new nginx vhosts must `include global.conf` to inherit the `deny ~ /\.` rule.

## Verification Checklist
```bash
curl -Ik -H 'Host: org.halext.org' https://127.0.0.1
curl -I -H 'Host: org.halext.org' http://127.0.0.1/api/health
```
For registration probes include `-H 'X-Halext-Code: <code>'` on `/api/users/`.

## Notes for Agents
- Certificates managed via `certbot --nginx`, live under `/etc/letsencrypt/live/<domain>` and referenced by `/etc/nginx/ssl/*.conf`.
- Keep `~/bin/nginx-helper` in sync; `.bashrc` sources it for operational shortcuts.
- Resetting the DB requires restarting `halext-api` afterward so layout presets reseed.
