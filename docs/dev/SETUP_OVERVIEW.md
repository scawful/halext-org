# Halext Overview & Sync Workflow

This is the high-level guide you can share with anyone helping run Halext (including CLI/AI agents). It explains the moving parts, how dev on macOS stays in sync with the Ubuntu host, and which scripts/config files to run.

---

## 1. Architecture In Plain Terms

- **Backend (FastAPI + Uvicorn)**: Handles all data, auth, tasks, events, AI chats. Runs on `127.0.0.1:8000` and is protected by a shared `ACCESS_CODE`. Tokens are standard OAuth2 password grants.
- **Frontend (React SPA)**: Lives in `frontend/`, built with Vite. In development it runs via `npm run dev` on macOS; in production it’s a static bundle that Nginx serves.
- **Database**: Postgres in production (`DATABASE_URL` env var). For local testing the `scripts/dev-backend.sh` script falls back to SQLite automatically if Postgres isn’t reachable.
- **Access Code**: Every registration/login request must send `X-Halext-Code`. The code is configurable via the `ACCESS_CODE` environment variable and typed into the login UI. No code = no auth.
- **AI Gateway**: Stub layer that can talk to OpenWebUI/Ollama or reply with mock text; it doesn’t affect deployment if those services aren’t present.

---

## 2. Local macOS Workflow (launchd / dev)

1. Backend: `./scripts/dev-backend.sh` (auto checks Postgres, falls back to SQLite, runs Uvicorn on 127.0.0.1:8000).
2. Frontend: `launchctl` agent already configured, or run `npm run dev -- --host 127.0.0.1 --port 4173`.
3. Access code is stored in `localStorage`; set `ACCESS_CODE` in your shell before launching the backend.
4. Iterate on code, commit, and push to GitHub.

---

## 3. Ubuntu Workflow (Nginx + systemd)

### First-Time Setup

```bash
sudo mkdir -p /srv/halext
cd /srv/halext
sudo chown "$USER" /srv/halext
git clone https://github.com/<you>/halext-org.git
cd halext-org
sudo ./scripts/server-init.sh
```

Then:

1. Copy `infra/ubuntu/.env.example` → `backend/.env` and fill in `DATABASE_URL`, `ACCESS_CODE`, `SECRET_KEY`.
2. `sudo cp infra/ubuntu/halext-api.service /etc/systemd/system/halext-api.service`
3. `sudo systemctl daemon-reload && sudo systemctl enable --now halext-api`
4. Copy `infra/ubuntu/halext.nginx.conf` into your existing Nginx layout (adjust `root` paths to fit your structure). Set the `server_name` to the subdomain you want (e.g., `org.halext.org`) and reload Nginx.
5. Optional: run `sudo certbot --nginx -d org.halext.org` for HTTPS.

### Daily Updates

```bash
ssh user@server
cd /srv/halext/halext-org
git pull
./scripts/server-deploy.sh           # or --backend-only / --frontend-only
```

That script reinstalls Python deps, builds the SPA, rsyncs it to `/var/www/halext` (edit within the script to match your custom path), restarts `halext-api`, and reloads Nginx.

### Monitoring

- Backend logs: `journalctl -u halext-api -f`
- Nginx errors: `/var/log/nginx/error.log`

---

## 4. Keeping Config Safe

- `.env` stays only on the server (contains DB credentials + access code). Never commit it.
- When rotating the access code, update the env var and restart `halext-api`. Users must type the new code on the login screen.
- If you need per-environment differences (dev vs prod), rely on env vars, not hard-coded values.

---

## 5. Subdomain Strategy

- Use a dedicated server block for the app subdomain (`org.halext.org`, `app.halext.org`, etc.) so it doesn’t disturb your main `halext.org` site.
- The SPA `root` path can live anywhere (e.g., `/www/halext.org/org`). Update both `scripts/server-deploy.sh` (the `WWW_DIR` value) and the Nginx config to match.
- API traffic is proxied via `/api/` to `http://127.0.0.1:8000/`.

---

## 6. Handing Off to Agents or Teammates

If someone else needs to help (human or AI agent), point them to:

- `docs/SETUP_OVERVIEW.md` (this file)
- `DEPLOYMENT.md` for more detail on infrastructure choices
- `scripts/server-init.sh` and `scripts/server-deploy.sh` for automation
- `infra/ubuntu/` for template configs

Everything else (local dev scripts, launchd plist, etc.) already lives in the repo. No secrets are stored in git.
