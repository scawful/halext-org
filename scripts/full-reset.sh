#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
AGENT_DIR="$HOME/Library/LaunchAgents"
USER_ID="$(id -u)"
NODE_BIN_DIR="${NODE_BIN_DIR:-/usr/local/opt/node@20/bin}"
WIPE_SQLITE="${WIPE_SQLITE:-0}"

run_launchctl() {
  if [[ $EUID -eq 0 ]]; then
    launchctl asuser "$USER_ID" launchctl "$@"
  else
    launchctl "$@"
  fi
}

stop_agent() {
  local label="$1"
  run_launchctl bootout "gui/$USER_ID/$label" >/dev/null 2>&1 || true
  echo "Stopped $label (if it was running)"
}

echo "==> Halext full reset starting"

stop_agent "org.halext.frontend"
stop_agent "org.halext.api"

if [[ ! -x "$BACKEND_DIR/env/bin/python" ]]; then
  echo "Backend venv missing. Run 'cd backend && python3 -m venv env && source env/bin/activate' first." >&2
  exit 1
fi

echo "==> Reinstalling backend dependencies"
(cd "$BACKEND_DIR" && env/bin/pip install -r requirements.txt)

if [[ "$WIPE_SQLITE" == "1" ]]; then
  rm -f "$ROOT_DIR/halext_dev.db"
  echo "Removed local SQLite database at $ROOT_DIR/halext_dev.db"
fi

echo "==> Reinstalling frontend dependencies with Node bin dir $NODE_BIN_DIR"
(cd "$FRONTEND_DIR" && PATH="$NODE_BIN_DIR:$PATH" npm install)

echo "==> Syncing launch agents"
cp "$ROOT_DIR/org.halext.api.plist" "$AGENT_DIR/"
cp "$ROOT_DIR/org.halext.frontend.plist" "$AGENT_DIR/"

echo "==> Restarting services"
"$ROOT_DIR/scripts/refresh-halext.sh"

echo "==> Full reset complete. Backend: http://127.0.0.1:8000  Frontend: http://127.0.0.1:4173"
