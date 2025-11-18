#!/bin/bash
set -euo pipefail

# Usage: ./scripts/server-deploy.sh [--frontend-only|--backend-only]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
WWW_DIR="/var/www/halext"
MODE="${1:-all}"

BACKEND_REQ_FILE="$BACKEND_DIR/requirements.txt"
BACKEND_REQ_CACHE="$BACKEND_DIR/.requirements.sha256"
FRONTEND_LOCK_FILE="$FRONTEND_DIR/package-lock.json"
FRONTEND_LOCK_CACHE="$FRONTEND_DIR/.package-lock.sha256"
FRONTEND_NPM_CACHE="$FRONTEND_DIR/.npm-cache"

# Prompt for sudo upfront
if ! sudo -n true 2>/dev/null; then
    echo "This script requires sudo privileges to restart services and copy files."
    sudo -v
fi

verify_halext_api() {
    echo "Verifying halext-api service..."
    sleep 2
    if systemctl is-active --quiet halext-api; then
        echo "Service is active."
    else
        echo "ERROR: halext-api failed to start."
        journalctl -u halext-api -n 20 --no-pager
        return 1
    fi
}

should_update_backend_deps() {
  local new_hash
  new_hash="$(sha256sum "$BACKEND_REQ_FILE" | awk '{print $1}')"
  if [[ -f "$BACKEND_REQ_CACHE" ]]; then
    local old_hash
    old_hash="$(cat "$BACKEND_REQ_CACHE")"
    [[ "$new_hash" != "$old_hash" ]]
  else
    return 0
  fi
}

write_backend_hash() {
  sha256sum "$BACKEND_REQ_FILE" | awk '{print $1}' > "$BACKEND_REQ_CACHE"
}

should_bootstrap_frontend() {
  [[ ! -d "$FRONTEND_DIR/node_modules" ]] && return 0
  [[ ! -f "$FRONTEND_LOCK_FILE" ]] && return 0

  local new_hash
  new_hash="$(sha256sum "$FRONTEND_LOCK_FILE" | awk '{print $1}')"
  if [[ -f "$FRONTEND_LOCK_CACHE" ]]; then
    local old_hash
    old_hash="$(cat "$FRONTEND_LOCK_CACHE")"
    [[ "$new_hash" != "$old_hash" ]]
  else
    return 0
  fi
}

write_frontend_hash() {
  sha256sum "$FRONTEND_LOCK_FILE" | awk '{print $1}' > "$FRONTEND_LOCK_CACHE"
}

update_backend() {
  cd "$BACKEND_DIR"
  if should_update_backend_deps; then
    echo "Detected requirements.txt change or missing cache. Updating backend dependencies..."
    ./env/bin/pip install -r requirements.txt
    write_backend_hash
  else
    echo "requirements.txt unchanged; skipping pip install."
  fi
  
  echo "Restarting halext-api..."
  sudo systemctl restart halext-api
  verify_halext_api
}

update_frontend() {
  cd "$FRONTEND_DIR"
  mkdir -p "$FRONTEND_NPM_CACHE"
  if should_bootstrap_frontend; then
    echo "Installing frontend dependencies (npm ci)..."
    npm ci --prefer-offline --cache "$FRONTEND_NPM_CACHE"
    write_frontend_hash
  else
    echo "package-lock.json unchanged; reusing existing node_modules."
  fi

  echo "Building frontend..."
  npm run build
  
  echo "Deploying to $WWW_DIR..."
  sudo rsync -a --delete "$FRONTEND_DIR/dist/" "$WWW_DIR/"
  sudo chown -R www-data:www-data "$WWW_DIR"
  
  echo "Reloading Nginx..."
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

echo "Deployment refreshed successfully."
