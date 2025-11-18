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

SUDO_BIN="$(command -v sudo || true)"
SUDO_READY=0
SUDO_CHECKED=0

ensure_sudo() {
  if [[ -z "$SUDO_BIN" ]]; then
    return 1
  fi

  if [[ $SUDO_READY -eq 1 ]]; then
    return 0
  fi

  if [[ $SUDO_CHECKED -eq 0 ]]; then
    if "$SUDO_BIN" -n true >/dev/null 2>&1; then
      SUDO_READY=1
      SUDO_CHECKED=1
      return 0
    fi
  fi

  SUDO_CHECKED=1
  if [[ -t 0 ]]; then
    echo "sudo privileges are required for some deployment steps."
    if "$SUDO_BIN" -v; then
      SUDO_READY=1
      return 0
    fi
  fi

  return 1
}

run_sudo() {
  if ensure_sudo; then
    "$SUDO_BIN" "$@"
  else
    PENDING_SUDO_TASKS+=("sudo $*")
    return 1
  fi
}

verify_halext_api() {
  echo "Verifying halext-api service..."
  sleep 2
  if ! run_sudo systemctl is-active --quiet halext-api; then
    echo "ERROR: halext-api is not active after restart attempt."
    run_sudo systemctl status halext-api --no-pager || true
    run_sudo journalctl -u halext-api -n 50 --no-pager || true
    exit 1
  fi
  echo "halext-api is running."
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
  if run_sudo systemctl restart halext-api; then
    verify_halext_api
  else
    echo "WARNING: Unable to restart halext-api automatically. Run 'sudo systemctl restart halext-api' when possible."
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
