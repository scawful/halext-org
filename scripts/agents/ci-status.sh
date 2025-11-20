#!/bin/bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "[ci-status] GitHub CLI (gh) is not installed or not in PATH." >&2
  exit 1
fi

LIMIT=${1:-5}

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "$(basename $(pwd))")"

echo "[ci-status] showing last ${LIMIT} runs for ${REPO}" 

gh run list -L "${LIMIT}"
