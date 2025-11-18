# Halext Deployment Guide (Ubuntu + Nginx)

This document walks through running the Halext stack on an Ubuntu 22.04 (or newer) server with Nginx and a subdomain such as `app.halext.org`. The goal is to keep development flowing locally while the shared instance stays online for Chris.

## 0. Quick Start (org.halext.org)

For the production org.halext.org host there is a single bootstrapper that wires up Postgres, systemd, the FastAPI virtualenv, the SPA build, and Nginx:

```bash
cd /srv/halext/halext-org
sudo ./scripts/setup-org.sh
```

The script will:

- verify required tooling (`psql`, `node`, `npm`, `rsync`, `nginx`, `systemctl`, `curl`, `sudo`).
- install and start PostgreSQL if it does not already exist, then ensure the service is active.
- prompt before overwriting `backend/.env`, generate secrets if needed, and create/alter the Postgres role/database via `runuser -u postgres`.
- create/update the Python 3.11 (or fallback python3) virtualenv and backend dependencies.
- build the frontend, rsync it to `/var/www/halext`, and chown the directory to `www-data`.
- install/enable the `halext-api` systemd unit and stop if it fails to start (check `journalctl -u halext-api`).
- copy/enable the Nginx site for `org.halext.org`, include `/etc/nginx/ssl/org.halext.org.conf` when present, and run a host-header curl test.

After the script finishes, point DNS for `org.halext.org` at the server and run `sudo certbot --nginx -d org.halext.org` so the SSL snippet is created. The rest of this guide covers the manual steps in more detail if you need to debug a specific stage or customize the deployment.

If you create a dedicated `halext` user for Git/SSH access:

- run `sudo ./scripts/sync-halext-perms.sh` so the repo tree is group-writable for that account and Git no longer complains about dubious ownership.
- if the `justin` account already owns the SSH key you want to reuse, copy it with `sudo ./scripts/copy-ssh-key-to-halext.sh /path/to/justin/key` (optionally add a custom username/key name).

For managing Cloudflare’s proxy toggle (use DNS only while running `certbot`, then switch back), run:

```bash
CF_API_TOKEN=… CF_ZONE_NAME=halext.org ./scripts/cloudflare-certbot.sh certbot
```
This disables the proxy for `org.halext.org`, runs the certbot command (`sudo certbot --nginx -d org.halext.org` by default), and then re-enables the proxy.

For ongoing upkeep on the production box, run the bundled updater:

```bash
cd /srv/halext/halext-org
./scripts/update-halext.sh
```

`update-halext.sh` fast-forwards the current Git branch, reuses `server-deploy.sh` to reinstall Python/Node deps, restarts `halext-api`, reloads Nginx, and curls `org.halext.org`. Override the defaults with `HALX_DOMAIN` or `HALX_WWW_DIR` if you host the bundle elsewhere.

## 1. Prerequisites

- Ubuntu server with SSH access and sudo privileges.
- Installed packages: `git`, `python3.11` (or newer), `python3.11-venv`, `nginx`, `nodejs` ≥ 20, `npm`.
- PostgreSQL 14+ (local or hosted). For quick trials you can fall back to SQLite, but PostgreSQL is recommended.
- DNS entry for `app.halext.org` (or another subdomain) pointing to the server’s IP.

### Install core tooling

```bash
sudo apt update
sudo apt install -y git python3.11 python3.11-venv python3-pip nginx
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### Optional: Postgres

```bash
sudo apt install -y postgresql postgresql-contrib
sudo -u postgres createuser halext_user --pwprompt
sudo -u postgres createdb halext_org --owner=halext_user
```

## 2. Source Code & GitOps

1. Push this repo to GitHub (or your preferred Git remote).
2. On the Ubuntu server:

```bash
sudo mkdir -p /srv/halext
cd /srv/halext
sudo chown "$USER" /srv/halext
git clone https://github.com/yourname/halext-org.git
cd halext-org
```

3. Run `sudo ./scripts/setup-org.sh` to let the bootstrapper install packages, create the Python venv, build the frontend, and drop the service/nginx files under `infra/ubuntu`. (The older `server-init.sh` is kept for historical reference, but `setup-org.sh` is the maintained path.)
4. Copy `infra/ubuntu/.env.example` to `backend/.env` and fill in your secrets.
5. Enable the systemd service and Nginx site (see below). Future updates are `git pull && ./scripts/server-deploy.sh`.

## 3. Backend Service (FastAPI + Uvicorn)

### Virtualenv Setup

```bash
cd /srv/halext/halext-org/backend
python3.11 -m venv env
source env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Environment Variables

Create `/srv/halext/halext-org/backend/.env` (or export in systemd):

```
DATABASE_URL=postgresql://halext_user:your_password@127.0.0.1/halext_org
ACCESS_CODE=super-secret-code
SECRET_KEY=change_me
```

### systemd Service

Edit `/srv/halext/halext-org/infra/ubuntu/halext-api.service` if needed, then install it:

```bash
sudo cp infra/ubuntu/halext-api.service /etc/systemd/system/halext-api.service
sudo systemctl daemon-reload
sudo systemctl enable --now halext-api
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now halext-api
```

## 4. Frontend Build

The production frontend is a static bundle served by Nginx.

```bash
cd /srv/halext/halext-org/frontend
npm install
npm run build
sudo mkdir -p /var/www/halext
sudo rsync -a dist/ /var/www/halext/
```

Re-run `npm run build` + `rsync` whenever you deploy updates.

## 5. Nginx Configuration

Copy the provided config and enable it:

```bash
sudo cp infra/ubuntu/halext.nginx.conf /etc/nginx/sites-available/halext
sudo ln -s /etc/nginx/sites-available/halext /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### HTTPS

Use Let’s Encrypt via certbot:

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d app.halext.org
```

## 6. Access Code Protection

- Set `ACCESS_CODE` on the server (as shown above). Every request to `/token` or `/users/` must include `X-Halext-Code`.
- In the frontend login/registration form there is an “Access code” field. Share this code privately with Chris. Without it, no one can register or log in even if the site is exposed publicly.
- You can rotate the code by changing the env var and restarting the backend; users will be prompted for the new code.

## 7. Updating the Server

The recommended flow is a single command:

```bash
cd /srv/halext/halext-org
./scripts/update-halext.sh
```

This helper fetches/pulls the current branch, reuses `server-deploy.sh` to reinstall Python/Node deps, restarts `halext-api`, reloads Nginx, ensures `/var/www/halext` ownership, and curls `org.halext.org` for a quick smoke test. For partial deployments (e.g., only backend wheels) call `./scripts/server-deploy.sh --backend-only` or `--frontend-only`. Watch `journalctl -u halext-api -f` and `/var/log/nginx/error.log` if you need deeper troubleshooting.

## 8. Building the Frontend Locally

If your Ubuntu VM is resource-constrained, build the SPA on macOS and push just the static files:

```bash
cd /Users/scawful/Code/halext-org
HALX_REMOTE="user@server" \
HALX_REMOTE_DIR="/var/www/halext" \
HALX_POST_DEPLOY="sudo systemctl reload nginx" \
./scripts/deploy-frontend-local.sh
```

This runs `npm install && npm run build` locally, rsyncs `frontend/dist/` to the server’s docroot, and optionally executes a post-deploy SSH command (e.g., reloading Nginx). Update `HALX_REMOTE_DIR` to match your actual root (such as `/www/halext.org/app`).

## 9. Local Development vs. Production

- Continue developing on macOS (launchd workflows). Once happy, `git commit/push`.
- On Ubuntu, pull and run the build/deploy steps. Systemd + Nginx keep the app online for Chris.
- The `ACCESS_CODE` gate lets you share the subdomain safely while the full auth stack evolves.

## 10. Script Reference

| Script | When to use | Notes |
| --- | --- | --- |
| `scripts/setup-org.sh` | First-time bootstrap on Ubuntu | Creates Postgres role/DB, virtualenv, builds frontend, installs `halext-api` + nginx vhost. Supersedes the older `server-init.sh`. |
| `scripts/update-halext.sh` | Day-to-day production updates | Runs `git pull`, reuses `server-deploy.sh`, restarts services, and curls `org.halext.org`. Honors `HALX_DOMAIN`/`HALX_WWW_DIR`. |
| `scripts/server-deploy.sh` | Targeted backend/frontend refresh | Pass `--backend-only` or `--frontend-only` when you don’t want the full update helper. |
| `scripts/cloudflare-certbot.sh` | Temporarily disable Cloudflare proxy for certbot | Wraps `certbot` so DNS-only mode is toggled automatically. |
| `scripts/sync-halext-perms.sh` | Fix repo permissions for the `halext` user | Keeps `/srv/halext/halext-org` group-writeable to avoid Git ownership warnings. |
| `scripts/copy-ssh-key-to-halext.sh` | Reuse an existing SSH key for the `halext` account | Copies keys from `justin` (or another user) into `/home/halext/.ssh`. |
