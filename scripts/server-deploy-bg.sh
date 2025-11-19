#!/bin/bash
set -euo pipefail

# Run server-deploy.sh in the background (nice + nohup style) so long deploys
# don't lock up interactive shells. The script logs to /tmp by default and
# restarts halext-api again once the deploy completes.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${HALX_BG_LOG_DIR:-/tmp}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/halext-deploy-${TIMESTAMP}.log"
DEPLOY_SCRIPT="$ROOT_DIR/scripts/server-deploy.sh"
declare -a DEPLOY_CMD=("bash" "$DEPLOY_SCRIPT")

if [[ ! -x "$DEPLOY_SCRIPT" ]]; then
  echo "Cannot find executable server-deploy.sh at $DEPLOY_SCRIPT" >&2
  exit 1
fi

mkdir -p "$LOG_DIR"

if [[ $# -gt 0 ]]; then
  DEPLOY_CMD+=("$@")
fi

maybe_cache_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    if ! sudo -n true >/dev/null 2>&1; then
      echo "Caching sudo credentials (enter password if prompted)..."
      sudo -v
    fi
  fi
}

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

maybe_cache_sudo

touch "$LOG_FILE"
(
  echo "[ $(timestamp) ] Starting server-deploy in background: ${DEPLOY_CMD[*]}"
  if ! nice -n 10 "${DEPLOY_CMD[@]}"; then
    echo "[ $(timestamp) ] server-deploy exited with errors."
    exit 1
  fi
  echo "[ $(timestamp) ] server-deploy finished. Restarting halext-api..."
  if command -v systemctl >/dev/null 2>&1; then
    if sudo systemctl restart halext-api; then
      echo "[ $(timestamp) ] halext-api restart complete."
    else
      echo "[ $(timestamp) ] WARNING: Failed to restart halext-api. Check sudo privileges."
    fi
  else
    echo "[ $(timestamp) ] systemctl not found; skipping halext-api restart."
  fi
) >>"$LOG_FILE" 2>&1 &
BG_PID=$!

echo "Background deploy started (PID $BG_PID). Logs: $LOG_FILE"
echo "Tail logs with: tail -f $LOG_FILE"
