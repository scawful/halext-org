#!/bin/bash
set -euo pipefail

# Build the frontend locally and rsync the dist/ output to a remote server.
#
# Usage: ./scripts/deploy-frontend-local.sh [--dry-run] [--skip-post]
#
# Configuration is read from scripts/frontend-deploy.env if it exists,
# or from environment variables:
#   HALX_REMOTE       SSH destination (e.g., ubuntu@123.45.67.89)
#   HALX_REMOTE_DIR   Path on the server where static files live (e.g., /var/www/halext)
#   HALX_POST_DEPLOY  Optional command to run after rsync

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"
ENV_FILE="$ROOT_DIR/scripts/frontend-deploy.env"

# Load defaults from env file
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

REMOTE="${HALX_REMOTE:-}"
REMOTE_DIR="${HALX_REMOTE_DIR:-}"
POST_CMD="${HALX_POST_DEPLOY:-}"
DRY_RUN=0
SKIP_POST=0

# Parse args
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=1 ;;
    --skip-post) SKIP_POST=1 ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

if [[ -z "$REMOTE" || -z "$REMOTE_DIR" ]]; then
  echo "Usage: $0 [--dry-run] [--skip-post]"
  echo
  echo "Error: HALX_REMOTE and HALX_REMOTE_DIR must be set."
  echo "Define them in $ENV_FILE or export them."
  exit 1
fi

echo "=== Frontend Deploy: $REMOTE:$REMOTE_DIR ==="

cd "$FRONTEND_DIR"

# Smart install - check if package-lock changed
LOCK_HASH_FILE="$FRONTEND_DIR/node_modules/.package-lock.sha256"
CURRENT_HASH=""
if [[ -f "package-lock.json" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    CURRENT_HASH=$(shasum -a 256 package-lock.json | cut -d' ' -f1)
  else
    CURRENT_HASH=$(sha256sum package-lock.json | cut -d' ' -f1)
  fi
fi

NEEDS_INSTALL=1
if [[ -f "$LOCK_HASH_FILE" && -n "$CURRENT_HASH" ]]; then
  STORED_HASH=$(cat "$LOCK_HASH_FILE")
  if [[ "$CURRENT_HASH" == "$STORED_HASH" ]]; then
    NEEDS_INSTALL=0
  fi
fi

if [[ $NEEDS_INSTALL -eq 1 ]]; then
  echo "Dependencies changed or not installed. Running npm ci..."
  npm ci
  if [[ -n "$CURRENT_HASH" ]]; then
    echo "$CURRENT_HASH" > "$LOCK_HASH_FILE"
  fi
else
  echo "Dependencies up to date (cached)."
fi

echo "Building frontend..."
npm run build

if [[ ! -d "$FRONTEND_DIR/dist" ]]; then
  echo "Error: dist/ directory missing after build." >&2
  exit 1
fi

RSYNC_OPTS="-az --delete"
if [[ $DRY_RUN -eq 1 ]]; then
  RSYNC_OPTS="$RSYNC_OPTS --dry-run -v"
  echo "[DRY RUN] Would sync to $REMOTE:$REMOTE_DIR"
else
  echo "Syncing dist/ to $REMOTE:$REMOTE_DIR ..."
fi

rsync $RSYNC_OPTS "$FRONTEND_DIR/dist/" "$REMOTE:$REMOTE_DIR/"

echo "Sync complete."

if [[ -n "$POST_CMD" && $SKIP_POST -eq 0 ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY RUN] Would run post-deploy command: $POST_CMD"
  else
    echo "Running post-deploy command..."
    ssh "$REMOTE" "$POST_CMD"
  fi
fi
