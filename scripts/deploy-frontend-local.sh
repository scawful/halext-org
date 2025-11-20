#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: HALX_REMOTE=user@server HALX_REMOTE_DIR=/var/www/halext ./scripts/deploy-frontend-local.sh [options]

Builds the frontend on macOS (or any fast workstation), syncs dist/ to the remote docroot,
and optionally runs a post-deploy SSH command (e.g., reload nginx). Defaults can be stored in
scripts/frontend-deploy.env so you only have to fill in the SSH target once.

Options:
  --dry-run      Show which files would be synced without uploading anything.
  --skip-post    Do not run HALX_POST_DEPLOY even if it is set.
  -h, --help     Show this help text.
EOF
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
LOCK_FILE="$FRONTEND_DIR/package-lock.json"
LOCK_CACHE="$FRONTEND_DIR/.package-lock.local.sha256"
NPM_CACHE="$FRONTEND_DIR/.npm-cache"
DIST_DIR="$FRONTEND_DIR/dist"
CONFIG_FILE="${HALX_FRONTEND_CONFIG:-$ROOT_DIR/scripts/frontend-deploy.env}"

if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

REMOTE="${HALX_REMOTE:-}"
REMOTE_DIR="${HALX_REMOTE_DIR:-}"
POST_CMD="${HALX_POST_DEPLOY:-}"
DRY_RUN=0
SKIP_POST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --skip-post)
      SKIP_POST=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ -z "$REMOTE" || -z "$REMOTE_DIR" ]]; then
  echo "HALX_REMOTE and HALX_REMOTE_DIR must be set. Export them or use $CONFIG_FILE." >&2
  exit 1
fi

lock_hash() {
  sha256sum "$LOCK_FILE" | awk '{print $1}'
}

install_frontend_deps() {
  echo "Installing npm dependencies via npm ci..."
  rm -rf "$FRONTEND_DIR/node_modules"
  npm ci --prefer-offline --cache "$NPM_CACHE"
  lock_hash > "$LOCK_CACHE"
}

maybe_install_deps() {
  mkdir -p "$NPM_CACHE"
  if [[ ! -d "$FRONTEND_DIR/node_modules" ]]; then
    install_frontend_deps
    return
  fi

  if [[ ! -f "$LOCK_FILE" ]]; then
    echo "package-lock.json missing; forcing fresh npm install."
    install_frontend_deps
    return
  fi

  if [[ ! -f "$LOCK_CACHE" ]]; then
    install_frontend_deps
    return
  fi

  if [[ "$(lock_hash)" != "$(cat "$LOCK_CACHE")" ]]; then
    echo "package-lock.json changed; reinstalling deps."
    install_frontend_deps
    return
  fi

  echo "package-lock.json unchanged; reusing existing node_modules."
}

cd "$FRONTEND_DIR"
maybe_install_deps

echo "Building frontend bundle..."
npm run build

if [[ ! -d "$DIST_DIR" ]]; then
  echo "dist/ missing after build" >&2
  exit 1
fi

RSYNC_ARGS=(-az --delete)
if [[ $DRY_RUN -eq 1 ]]; then
  RSYNC_ARGS+=(--dry-run)
fi

echo "Syncing dist/ to $REMOTE:$REMOTE_DIR ..."
rsync "${RSYNC_ARGS[@]}" "$DIST_DIR/" "$REMOTE:$REMOTE_DIR/"
echo "Sync complete."

if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry run requested; skipping remote post-deploy command."
elif [[ $SKIP_POST -eq 1 || -z "$POST_CMD" ]]; then
  :
else
  echo "Running post-deploy command: $POST_CMD"
  ssh "$REMOTE" "$POST_CMD"
fi
