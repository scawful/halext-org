#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRANCH="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)"
REMOTE="$(git -C "$ROOT_DIR" config --get branch."$BRANCH".remote || echo origin)"
DOMAIN="${HALX_DOMAIN:-org.halext.org}"
WWW_DIR="${HALX_WWW_DIR:-/var/www/halext}"

log() {
  printf '[halext-update] %s\n' "$*"
}

warn_dirty_tree() {
  if git -C "$ROOT_DIR" status --porcelain | grep -q .; then
    log "Working tree has local changes. Continuing anyway; commit/stash if needed."
  fi
}

warn_dirty_tree

log "Fetching $REMOTE/$BRANCH…"
git -C "$ROOT_DIR" fetch "$REMOTE" "$BRANCH"

log "Fast-forwarding $BRANCH…"
git -C "$ROOT_DIR" pull --ff-only "$REMOTE" "$BRANCH"

log "Running server-deploy refresh…"
"$ROOT_DIR/scripts/server-deploy.sh"

if [[ -d "$WWW_DIR" ]]; then
  log "Ensuring $WWW_DIR is owned by www-data…"
  sudo chown -R www-data:www-data "$WWW_DIR"
fi

log "Verifying nginx for $DOMAIN…"
if command -v curl >/dev/null 2>&1; then
  if curl -fsS -H "Host: $DOMAIN" http://127.0.0.1 >/dev/null; then
    log "HTTP check passed for $DOMAIN"
  else
    log "Warning: curl check failed for $DOMAIN"
  fi
else
  log "curl not installed; skipping http probe"
fi

log "Halext update complete."
