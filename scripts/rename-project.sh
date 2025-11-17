#!/bin/bash
set -euo pipefail

# Renames the repo directory (default: halext-org) and updates references
# to the old folder name inside launchd plists, docs, and scripts.
#
# Usage:
#   ./scripts/rename-project.sh                # rename to halext-org
#   ./scripts/rename-project.sh new-folder     # custom name

NEW_NAME="${1:-halext-org}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OLD_NAME="$(basename "$REPO_ROOT")"

if [[ -z "$NEW_NAME" ]]; then
  echo "New repo name cannot be empty." >&2
  exit 1
fi

FILES_TO_UPDATE=(
  "org.halext.api.plist"
  "org.halext.frontend.plist"
  "scripts/server-init.sh"
  "scripts/dev-backend.sh"
  "scripts/full-reset.sh"
  "scripts/refresh-halext.sh"
  "docs/SETUP_OVERVIEW.md"
  "DEPLOYMENT.md"
  "PLANNING.md"
  "infra/ubuntu/halext-api.service"
)

replace_string() {
  local file=$1
  local target="$REPO_ROOT/$file"
  if [[ ! -f "$target" ]]; then
    return
  fi
  python3 - "$target" "$OLD_NAME" "$NEW_NAME" <<'PY'
import sys
path, old, new = sys.argv[1:4]
with open(path, "r", encoding="utf-8") as fh:
    data = fh.read()
if old not in data:
    sys.exit(0)
data = data.replace(old, new)
with open(path, "w", encoding="utf-8") as fh:
    fh.write(data)
PY
  echo "Updated $file"
}

if [[ "$OLD_NAME" == "$NEW_NAME" ]]; then
  echo "Repository already named $NEW_NAME. Updating files only."
fi

for file in "${FILES_TO_UPDATE[@]}"; do
  replace_string "$file"
done

if [[ "$OLD_NAME" != "$NEW_NAME" ]]; then
  PARENT_DIR="$(dirname "$REPO_ROOT")"
  echo "Renaming directory $REPO_ROOT -> $PARENT_DIR/$NEW_NAME"
  mv "$REPO_ROOT" "$PARENT_DIR/$NEW_NAME"
  echo "Done. Re-open your shell at $PARENT_DIR/$NEW_NAME"
else
  echo "File updates complete. No directory rename needed."
fi
