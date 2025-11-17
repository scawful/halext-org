# Halext Deployment Guide (Ubuntu + Nginx)

This document walks through running the Halext stack on an Ubuntu 22.04 (or newer) server with Nginx and a subdomain such as `app.halext.org`. The goal is to keep development flowing locally while the shared instance stays online for Chris.

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

3. Run `sudo ./scripts/server-init.sh`. This installs packages, creates the Python venv, builds the frontend, and drops template service/nginx files under `infra/ubuntu`.
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

1. `ssh` into Ubuntu.
2. `cd /srv/halext/halext-org && git pull`.
3. Run `./scripts/server-deploy.sh` (optionally `--backend-only` or `--frontend-only`) to reinstall deps, build the SPA, and restart services.
4. Monitor with `journalctl -u halext-api -f` for backend logs and `/var/log/nginx/error.log` for Nginx.

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
