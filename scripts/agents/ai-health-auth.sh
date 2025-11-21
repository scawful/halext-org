#!/usr/bin/env bash
# Authenticated AI health probe wrapper.
# Sources access code and bearer token from env or local server notes,
# then calls ai-health.sh with headers in place (without echoing secrets).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"

# Access code: env or server note file
ACCESS_CODE="${HAL_AI_CODE:-${HAL_AI_TOKEN:-}}"
ACCESS_CODE_FILE="${ACCESS_CODE_FILE:-/srv/halext.org/agent-notes/ai-health-token.txt}"

# Bearer token: env or cached file (default aligned with server notes)
BEARER_TOKEN="${HAL_AI_BEARER:-}"
BEARER_FILE="${HAL_AI_BEARER_FILE:-/tmp/test-token.txt}"

if [[ -z "$ACCESS_CODE" && -f "$ACCESS_CODE_FILE" ]]; then
  ACCESS_CODE="$(python3 - "$ACCESS_CODE_FILE" <<'PY' 2>/dev/null
import sys
path = sys.argv[1]
code = ""
lines = []
with open(path) as f:
    lines = [ln.strip() for ln in f if ln.strip() and not ln.strip().startswith("#")]
for ln in lines:
    if ln.startswith("HAL_AI_CODE="):
        code = ln.split("=",1)[1].strip()
        break
for ln in lines:
    if code:
        break
    if "=" in ln:
        code = ln.split("=",1)[1].strip()
        break
if not code and lines:
    code = lines[0]
print(code, end="")
PY
)"
fi

if [[ -z "$BEARER_TOKEN" && -f "$BEARER_FILE" ]]; then
  BEARER_TOKEN="$(<"$BEARER_FILE")"
fi

# Trim whitespace/newlines just in case
ACCESS_CODE="$(echo -n "$ACCESS_CODE" | tr -d '[:space:]')"
BEARER_TOKEN="$(echo -n "$BEARER_TOKEN" | tr -d '[:space:]')"

if [[ -z "$ACCESS_CODE" ]]; then
  echo "WARN: ACCESS_CODE missing. Set HAL_AI_CODE or provide ACCESS_CODE_FILE (default: $ACCESS_CODE_FILE)." >&2
fi

if [[ -z "$BEARER_TOKEN" && ! -f "$BEARER_FILE" ]]; then
  echo "WARN: bearer token missing. Set HAL_AI_BEARER or HAL_AI_BEARER_FILE (default: $BEARER_FILE)." >&2
fi

if [[ -n "$ACCESS_CODE" ]]; then
  echo "Loaded access code (len=${#ACCESS_CODE})"
fi
if [[ -n "$BEARER_TOKEN" ]]; then
  echo "Loaded bearer token (len=${#BEARER_TOKEN})"
fi

echo "Running ai-health.sh with supplied credentials (BASE_URL=${BASE_URL})..."
HAL_AI_CODE="$ACCESS_CODE" \
HAL_AI_BEARER="$BEARER_TOKEN" \
HAL_AI_BEARER_FILE="$BEARER_FILE" \
BASE_URL="$BASE_URL" \
"$SCRIPT_DIR/ai-health.sh"
