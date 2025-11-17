#!/bin/bash
set -euo pipefail

# Quickly resync launchd plists and restart the Halext backend/frontend services.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_DIR="$HOME/Library/LaunchAgents"
USER_ID="$(id -u)"

run_launchctl() {
  if [[ $EUID -eq 0 ]]; then
    launchctl asuser "$USER_ID" launchctl "$@"
  else
    launchctl "$@"
  fi
}

ensure_plist() {
  local plist_name="$1"
  local src="$ROOT_DIR/$plist_name"
  local dest="$AGENT_DIR/$plist_name"

  if [[ ! -f "$src" ]]; then
    echo "Missing plist: $src" >&2
    exit 1
  fi

  mkdir -p "$AGENT_DIR"
  cp "$src" "$dest"
  echo "Synced $plist_name to $dest"
}

restart_agent() {
  local label="$1"
  local plist_name="$2"
  local dest="$AGENT_DIR/$plist_name"

  run_launchctl unload -w "$dest" >/dev/null 2>&1 || true
  run_launchctl load -w "$dest"
  echo "Restarted $label via launchctl load/unload"
}

ensure_plist "org.halext.api.plist"
ensure_plist "org.halext.frontend.plist"

restart_agent "org.halext.api" "org.halext.api.plist"
restart_agent "org.halext.frontend" "org.halext.frontend.plist"

echo "Halext services refreshed. Backend: http://127.0.0.1:8000  Frontend: http://127.0.0.1:4173"
