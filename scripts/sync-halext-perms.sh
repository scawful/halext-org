#!/bin/bash
set -euo pipefail

# Ensure the halext user (or another low-privileged operator) can modify the repo
# without going through the dubious ownership checks Git enforces.

REPO_ROOT="${1:-/srv/halext.org/halext-org}"
HAL_EXT_USER="${2:-halext}"

if [[ $EUID -ne 0 ]]; then
  echo "Run this script as root (sudo) so it can set ownership/permissions."
  exit 1
fi

if ! id "$HAL_EXT_USER" >/dev/null 2>&1; then
  echo "User '$HAL_EXT_USER' does not exist."
  exit 1
fi

HAL_EXT_GROUP="$(id -gn "$HAL_EXT_USER")"

echo "Applying group ownership ($HAL_EXT_GROUP) to $REPO_ROOT (skipping backend/env)..."
find "$REPO_ROOT" -path "$REPO_ROOT/backend/env" -prune -o -exec chgrp "$HAL_EXT_GROUP" {} +

echo "Making the tree group-writable and setting SGID on directories..."
find "$REPO_ROOT" -path "$REPO_ROOT/backend/env" -prune -o -type d -exec chmod 2775 {} +
find "$REPO_ROOT" -path "$REPO_ROOT/backend/env" -prune -o -type f -exec chmod g+rw {} +

echo "Ensuring shell scripts remain executable by the group..."
find "$REPO_ROOT" -path "$REPO_ROOT/backend/env" -prune -o -name '*.sh' -exec chmod g+x {} +

echo "Marking ${REPO_ROOT} as a safe Git directory for ${HAL_EXT_USER}..."
runuser -u "$HAL_EXT_USER" -- git config --global --add safe.directory "$REPO_ROOT"

echo "Permissions synced. ${HAL_EXT_USER} can now use Git inside the repo."
