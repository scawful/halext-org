#!/bin/bash
set -euo pipefail

# Usage: ./scripts/server-deploy.sh [--frontend-only|--backend-only]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
WWW_DIR="/var/www/halext"
MODE="${1:-all}"

update_backend() {
  echo "Updating backend dependencies..."
  cd "$BACKEND_DIR"
  ./env/bin/pip install -r requirements.txt
  sudo systemctl restart halext-api
}

update_frontend() {
  echo "Building frontend..."
  cd "$FRONTEND_DIR"
  npm install
  npm run build
  sudo rsync -a "$FRONTEND_DIR/dist/" "$WWW_DIR/"
  sudo systemctl reload nginx
}

case "$MODE" in
  --backend-only)
    update_backend
    ;;
  --frontend-only)
    update_frontend
    ;;
  *)
    update_backend
    update_frontend
    ;;
esac

echo "Deployment refreshed."
