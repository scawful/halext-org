#!/bin/bash
set -euo pipefail

# macOS development sync helper.
# - Ensures backend virtualenv + frontend node_modules exist
# - Reinstalls deps when requirements/package-lock change
# - Restarts local services via launchd or dev scripts
# - Runs quick health checks against backend/frontend ports

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[macos-sync] This script is intended for macOS only." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAC_CONFIG_FILE="${HALX_MAC_SYNC_CONFIG:-$ROOT_DIR/scripts/macos-sync.env}"
if [[ -f "$MAC_CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$MAC_CONFIG_FILE"
fi

BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
BACKEND_REQ_FILE="$BACKEND_DIR/requirements.txt"
BACKEND_REQ_CACHE="$BACKEND_DIR/.requirements.local.sha256"
FRONTEND_LOCK_FILE="$FRONTEND_DIR/package-lock.json"
FRONTEND_LOCK_CACHE="$FRONTEND_DIR/.package-lock.macos.sha256"
BACKEND_PORT=8000
FRONTEND_PORT_DEV=5173
FRONTEND_PORT_LAUNCHD=4173
MODE="${HALX_MAC_MODE:-auto}"
SERVER_SYNC=0
REMOTE_SERVER="${HALX_REMOTE_SERVER:-}"
REMOTE_SERVER_DIR="${HALX_REMOTE_SERVER_DIR:-/srv/halext/halext-org}"
REMOTE_SERVER_SCRIPT="${HALX_REMOTE_SERVER_SCRIPT:-./scripts/server-sync.sh}"
REMOTE_SERVER_ENV="${HALX_REMOTE_SERVER_ENV:-}"
REMOTE_SERVER_SSH_OPTS="${HALX_REMOTE_SSH_OPTS:-}"

usage() {
  cat <<'EOF'
Usage: ./scripts/macos-sync.sh [--mode auto|dev|launchd] [--server-sync]

Ensures local dependencies are installed, then restarts the Halext
development stack using either launchd agents or the dev scripts.

Options:
  --mode auto      Detect launchd vs dev scripts automatically (default)
  --mode dev       Force dev-stop.sh/dev-reload.sh workflow
  --mode launchd   Force launchctl/LaunchAgents workflow
  --server-sync    After local restart, SSH into the Ubuntu host and run server-sync.sh
  --remote-server  Override remote SSH target (user@host)
  --remote-dir     Remote repository path (default /srv/halext/halext-org)
  --remote-script  Remote script to execute (default ./scripts/server-sync.sh)
  --ssh-opts       Extra ssh options (quoted string)
  -h, --help       Show this message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --mode=*)
      MODE="${1#*=}"
      shift 1
      ;;
    --server-sync)
      SERVER_SYNC=1
      shift 1
      ;;
    --remote-server)
      REMOTE_SERVER="$2"
      shift 2
      ;;
    --remote-dir)
      REMOTE_SERVER_DIR="$2"
      shift 2
      ;;
    --remote-script)
      REMOTE_SERVER_SCRIPT="$2"
      shift 2
      ;;
    --ssh-opts)
      REMOTE_SERVER_SSH_OPTS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[macos-sync] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

log() {
  printf '[macos-sync] %s\n' "$*"
}

ensure_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Installing missing command: $1"
    if [[ "$1" == "node" || "$1" == "npm" ]]; then
      echo "Please install Node.js 20+ (e.g., via nvm or Homebrew) before running this script." >&2
    else
      echo "Install $1 and rerun." >&2
    fi
    exit 1
  fi
}

hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

ensure_backend_env() {
  if [[ ! -d "$BACKEND_DIR/env" ]]; then
    log "Creating Python virtualenv in backend/env..."
    python3 -m venv "$BACKEND_DIR/env"
  fi

  if [[ ! -f "$BACKEND_REQ_FILE" ]]; then
    log "requirements.txt missing; skipping backend dependency check."
    return
  fi

  local new_hash
  new_hash="$(hash_file "$BACKEND_REQ_FILE")"
  local needs_install=0
  if [[ ! -f "$BACKEND_REQ_CACHE" ]]; then
    needs_install=1
  else
    local old_hash
    old_hash="$(cat "$BACKEND_REQ_CACHE")"
    [[ "$old_hash" != "$new_hash" ]] && needs_install=1
  fi

  if [[ $needs_install -eq 1 ]]; then
    log "Installing backend dependencies..."
    "$BACKEND_DIR/env/bin/pip" install --upgrade pip >/dev/null
    "$BACKEND_DIR/env/bin/pip" install -r "$BACKEND_REQ_FILE"
    echo "$new_hash" > "$BACKEND_REQ_CACHE"
  else
    log "Backend dependencies already up to date."
  fi
}

ensure_frontend_deps() {
  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    log "node_modules missing; installing frontend dependencies..."
    (cd "$FRONTEND_DIR" && npm install)
    echo "$(hash_file "$FRONTEND_LOCK_FILE")" > "$FRONTEND_LOCK_CACHE"
    return
  fi

  if [[ ! -f "$FRONTEND_LOCK_FILE" ]]; then
    log "package-lock.json missing; reinstalling dependencies..."
    rm -rf "$FRONTEND_DIR/node_modules"
    (cd "$FRONTEND_DIR" && npm install)
    echo "$(hash_file "$FRONTEND_LOCK_FILE")" > "$FRONTEND_LOCK_CACHE"
    return
  fi

  if [[ ! -f "$FRONTEND_LOCK_CACHE" ]]; then
    log "No lockfile hash cache found; refreshing dependencies..."
    (cd "$FRONTEND_DIR" && npm install)
    echo "$(hash_file "$FRONTEND_LOCK_FILE")" > "$FRONTEND_LOCK_CACHE"
    return
  fi

  local new_hash
  new_hash="$(hash_file "$FRONTEND_LOCK_FILE")"
  local old_hash
  old_hash="$(cat "$FRONTEND_LOCK_CACHE")"

  if [[ "$new_hash" != "$old_hash" ]]; then
    log "package-lock.json changed; reinstalling dependencies..."
    (cd "$FRONTEND_DIR" && npm install)
    echo "$new_hash" > "$FRONTEND_LOCK_CACHE"
  else
    log "Frontend dependencies already up to date."
  fi
}

detect_mode() {
  if [[ "$MODE" != "auto" ]]; then
    echo "$MODE"
    return
  fi

  if launchctl list | grep -q "org.halext.api"; then
    echo "launchd"
  else
    echo "dev"
  fi
}

restart_launchd() {
  log "Reloading launchd agents..."
  bash "$ROOT_DIR/scripts/refresh-halext.sh"
}

restart_dev_scripts() {
  if [[ -x "$ROOT_DIR/dev-stop.sh" ]]; then
    bash "$ROOT_DIR/dev-stop.sh"
  fi
  bash "$ROOT_DIR/dev-reload.sh"
}

run_remote_server_sync() {
  if [[ -z "$REMOTE_SERVER" ]]; then
    echo "[macos-sync] --server-sync requested but HALX_REMOTE_SERVER is not set." >&2
    exit 1
  fi

  log "Running server-sync.sh on $REMOTE_SERVER..."
  local remote_cmd
  printf -v remote_cmd "cd %q && " "$REMOTE_SERVER_DIR"
  if [[ -n "$REMOTE_SERVER_ENV" ]]; then
    remote_cmd+="${REMOTE_SERVER_ENV} "
  fi
  printf -v remote_cmd "%s%q" "$remote_cmd" "$REMOTE_SERVER_SCRIPT"

  local SSH_OPTS_ARRAY=()
  if [[ -n "$REMOTE_SERVER_SSH_OPTS" ]]; then
    read -r -a SSH_OPTS_ARRAY <<< "$REMOTE_SERVER_SSH_OPTS"
  fi
  if ssh "${SSH_OPTS_ARRAY[@]}" "$REMOTE_SERVER" "$remote_cmd"; then
    log "Remote server sync completed."
  else
    echo "[macos-sync] Remote server sync failed." >&2
    exit 1
  fi
}

health_check() {
  local name="$1"
  local url="$2"
  if curl -fsS -o /dev/null "$url"; then
    log "✓ ${name} responding at $url"
  else
    log "⚠ ${name} not responding at $url"
  fi
}

ensure_command python3
ensure_command npm
ensure_command node
ensure_command curl

ensure_backend_env
ensure_frontend_deps

SELECTED_MODE="$(detect_mode)"
log "Restart mode: $SELECTED_MODE"

case "$SELECTED_MODE" in
  launchd)
    restart_launchd
    FRONTEND_PORT="$FRONTEND_PORT_LAUNCHD"
    ;;
  dev)
    restart_dev_scripts
    FRONTEND_PORT="$FRONTEND_PORT_DEV"
    ;;
  *)
    log "Unknown restart mode: $SELECTED_MODE"
    exit 1
    ;;
esac

sleep 2

health_check "Backend API" "http://127.0.0.1:${BACKEND_PORT}/docs"
health_check "Frontend dev server" "http://127.0.0.1:${FRONTEND_PORT}/"

log "macOS development environment refreshed."

if [[ $SERVER_SYNC -eq 1 ]]; then
  run_remote_server_sync
fi
