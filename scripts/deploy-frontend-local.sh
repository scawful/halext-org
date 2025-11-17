#!/bin/bash
set -euo pipefail

# Build the frontend locally and rsync the dist/ output to a remote server.
#
# Usage:
#   HALX_REMOTE=user@server HALX_REMOTE_DIR=/var/www/halext ./scripts/deploy-frontend-local.sh
#
# Required env vars:
#   HALX_REMOTE       SSH destination (e.g., ubuntu@123.45.67.89)
#   HALX_REMOTE_DIR   Path on the server where static files live (e.g., /var/www/halext)
# Optional:
#   HALX_POST_DEPLOY  Command to run on the server after rsync (e.g., "sudo systemctl reload nginx")

REMOTE="${HALX_REMOTE:-}"
REMOTE_DIR="${HALX_REMOTE_DIR:-}"
POST_CMD="${HALX_POST_DEPLOY:-}"

if [[ -z "$REMOTE" || -z "$REMOTE_DIR" ]]; then
  echo "HALX_REMOTE and HALX_REMOTE_DIR must be set." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/frontend"

cd "$FRONTEND_DIR"
echo "Installing npm dependencies..."
npm install

echo "Building frontend..."
npm run build

if [[ ! -d "$FRONTEND_DIR/dist" ]]; then
  echo "dist/ missing after build" >&2
  exit 1
fi

echo "Syncing dist/ to $REMOTE:$REMOTE_DIR ..."
rsync -az --delete "$FRONTEND_DIR/dist/" "$REMOTE:$REMOTE_DIR/"

echo "Sync complete."

if [[ -n "$POST_CMD" ]]; then
  echo "Running post-deploy command: $POST_CMD"
  ssh "$REMOTE" "$POST_CMD"
fi
