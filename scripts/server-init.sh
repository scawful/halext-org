#!/bin/bash
set -euo pipefail

# Bootstrap a fresh Ubuntu host after cloning the repo.
# Usage: cd /srv/halext/halext-org-project && ./scripts/server-init.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
WWW_DIR="/var/www/halext"

if [[ $EUID -ne 0 ]]; then
  echo "Run this script with sudo so it can install packages and copy files."
  exit 1
fi

apt update
apt install -y python3.11 python3.11-venv python3-pip nginx git curl

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs
fi

if ! id -u www-data >/dev/null 2>&1; then
  echo "www-data user missing; install nginx first."
  exit 1
fi

su -S /bin/bash www-data -c "mkdir -p /srv/halext"

cd "$BACKEND_DIR"
python3.11 -m venv env
"$BACKEND_DIR/env/bin/pip" install --upgrade pip
"$BACKEND_DIR/env/bin/pip" install -r requirements.txt

cd "$FRONTEND_DIR"
npm install
npm run build

mkdir -p "$WWW_DIR"
rsync -a "$FRONTEND_DIR/dist/" "$WWW_DIR/"

echo "Copying systemd and nginx templates (edit before enabling!)"
cp "$ROOT_DIR/infra/ubuntu/halext-api.service" /etc/systemd/system/halext-api.service
cp "$ROOT_DIR/infra/ubuntu/halext.nginx.conf" /etc/nginx/sites-available/halext

echo "Server bootstrap complete. Next steps:"
echo " 1. Edit /srv/halext/halext-org-project/backend/.env (see infra/ubuntu/.env.example)."
echo " 2. sudo systemctl daemon-reload && sudo systemctl enable --now halext-api"
echo " 3. sudo ln -s /etc/nginx/sites-available/halext /etc/nginx/sites-enabled/"
echo " 4. sudo nginx -t && sudo systemctl reload nginx"
