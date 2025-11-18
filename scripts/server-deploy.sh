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
declare -a PENDING_SUDO_TASKS=()

if sudo -n true >/dev/null 2>&1; then
  HAVE_SUDO=1
else
  HAVE_SUDO=0
fi

run_sudo() {
  if [[ $HAVE_SUDO -eq 1 ]]; then
    sudo "$@"
  else
    PENDING_SUDO_TASKS+=("sudo $*")
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
  if ! run_sudo systemctl restart halext-api; then
    echo "WARNING: Unable to restart halext-api without sudo privileges."
  fi
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
  if ! run_sudo rsync -a "$FRONTEND_DIR/dist/" "$WWW_DIR/"; then
    echo "WARNING: Unable to sync dist/ to $WWW_DIR without sudo."
  fi
  if ! run_sudo systemctl reload nginx; then
    echo "WARNING: Unable to reload nginx without sudo."
  fi
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
if [[ ${#PENDING_SUDO_TASKS[@]} -gt 0 ]]; then
  echo
  echo "Manual steps required (sudo password needed):"
  for task in "${PENDING_SUDO_TASKS[@]}"; do
    echo "  - $task"
  done
fi
