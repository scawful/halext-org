#!/bin/bash
set -euo pipefail

# Full server refresh script for Ubuntu hosts.
# - Fast-forwards the current branch
# - Rebuilds backend/frontend assets via server-deploy.sh
# - Restarts halext-api, OpenWebUI, and nginx
# - Runs health checks against the API, SPA, and OpenWebUI endpoints

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
DOMAIN="${HALX_DOMAIN:-org.halext.org}"
WWW_DIR="${HALX_WWW_DIR:-/var/www/halext}"
API_HEALTH_URL="${HALX_API_HEALTH_URL:-http://127.0.0.1:8000/docs}"
SITE_HEALTH_URL="${HALX_SITE_HEALTH_URL:-http://127.0.0.1/}"
OPENWEBUI_INTERNAL_URL="${OPENWEBUI_URL:-}"
OPENWEBUI_PUBLIC_URL="${OPENWEBUI_PUBLIC_URL:-}"
SKIP_GIT_PULL="${HALX_SKIP_GIT_PULL:-0}"
HEALTH_FAILURE=0

log() {
  printf '[server-sync] %s\n' "$*"
}

err() {
  printf '[server-sync][ERROR] %s\n' "$*" >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Missing required command: $1"
    exit 1
  fi
}

extract_env_var() {
  local key="$1"
  if [[ -f "$BACKEND_DIR/.env" ]]; then
    local line
    line="$(grep -E "^${key}=" "$BACKEND_DIR/.env" | tail -n1 || true)"
    if [[ -n "$line" ]]; then
      local value="${line#*=}"
      value="${value%\"}"
      value="${value#\"}"
      echo "$value"
    fi
  fi
}

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
    log "sudo privileges required; prompting..."
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
    err "Unable to run sudo $* (no sudo privileges)"
    return 1
  fi
}

service_exists() {
  local service="$1"
  systemctl list-unit-files | awk '{print $1}' | grep -Fxq "$service"
}

health_check() {
  local name="$1"
  local url="$2"
  local extra_args=("${@:3}")

  if [[ -z "$url" ]]; then
    log "Skipping ${name} health check (URL not set)"
    return
  fi

  if curl -fsS -o /dev/null "${extra_args[@]}" "$url"; then
    log "✓ ${name} healthy ($url)"
  else
    err "✗ ${name} check failed ($url)"
    HEALTH_FAILURE=1
  fi
}

require_command git
require_command python3
require_command npm
require_command node
require_command curl
require_command systemctl

if [[ -z "$OPENWEBUI_INTERNAL_URL" ]]; then
  OPENWEBUI_INTERNAL_URL="$(extract_env_var OPENWEBUI_URL || true)"
fi
if [[ -z "$OPENWEBUI_PUBLIC_URL" ]]; then
  OPENWEBUI_PUBLIC_URL="$(extract_env_var OPENWEBUI_PUBLIC_URL || true)"
fi

if [[ "$SKIP_GIT_PULL" == "1" ]]; then
  log "Skipping git fetch/pull (HALX_SKIP_GIT_PULL=1)."
else
  BRANCH="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)"
  REMOTE="$(git -C "$ROOT_DIR" config --get branch."$BRANCH".remote || echo origin)"

  log "Current branch: $BRANCH (remote: $REMOTE)"
  if git -C "$ROOT_DIR" status --porcelain | grep -q .; then
    log "Working tree has local changes; continuing but git pull may fail."
  fi

  log "Fetching latest commits..."
  git -C "$ROOT_DIR" fetch "$REMOTE" "$BRANCH"

  log "Fast-forwarding $BRANCH..."
  git -C "$ROOT_DIR" pull --ff-only "$REMOTE" "$BRANCH"
fi

log "Refreshing backend/frontend assets via server-deploy.sh..."
bash "$ROOT_DIR/scripts/server-deploy.sh"

if service_exists "halext-api.service"; then
  log "Restarting halext-api service..."
  if run_sudo systemctl restart halext-api; then
    if run_sudo systemctl is-active --quiet halext-api; then
      log "halext-api restarted successfully."
    else
      err "halext-api failed to stay active."
      run_sudo systemctl status halext-api --no-pager || true
      run_sudo journalctl -u halext-api -n 50 --no-pager || true
      exit 1
    fi
  else
    err "Failed to restart halext-api. See logs above."
    exit 1
  fi
else
  log "halext-api.service not found; skipping restart."
fi

if service_exists "openwebui.service"; then
  log "Restarting openwebui service..."
  if ! run_sudo systemctl restart openwebui; then
    err "Unable to restart openwebui service."
  elif run_sudo systemctl is-active --quiet openwebui; then
    log "openwebui service restarted."
  else
    err "openwebui service is not active after restart."
    run_sudo systemctl status openwebui --no-pager || true
  fi
else
  log "openwebui.service not installed; skipping its restart."
fi

log "Reloading nginx..."
if ! run_sudo systemctl reload nginx; then
  err "Failed to reload nginx."
fi

log "Running health checks..."
health_check "Backend API" "$API_HEALTH_URL"
health_check "Public site" "$SITE_HEALTH_URL" -H "Host: ${DOMAIN}"

if [[ -n "$OPENWEBUI_INTERNAL_URL" ]]; then
  local_status_url="${OPENWEBUI_INTERNAL_URL%/}/api/v1/models"
  health_check "OpenWebUI internal API" "$local_status_url"
fi

if [[ -n "$OPENWEBUI_PUBLIC_URL" ]]; then
  public_status_url="${OPENWEBUI_PUBLIC_URL%/}/"
  health_check "OpenWebUI public UI" "$public_status_url"
fi

if [[ $HEALTH_FAILURE -eq 0 ]]; then
  log "All services refreshed successfully."
  log "Backend   : $API_HEALTH_URL"
  log "Frontend  : http://${DOMAIN}/ (proxied to $WWW_DIR)"
  if [[ -n "$OPENWEBUI_PUBLIC_URL" ]]; then
    log "OpenWebUI : $OPENWEBUI_PUBLIC_URL"
  fi
else
  err "One or more health checks failed. Inspect logs above."
  exit 1
fi
