#!/usr/bin/env bash
# iOS-focused API smoke: checks health, user, AI info/models, conversations, and messages (first conversation if present).
# Headers:
#   - X-Halext-Code from HAL_API_CODE / HAL_AI_CODE / first arg
#   - Authorization: Bearer from HAL_API_BEARER / HAL_AI_BEARER / HAL_API_BEARER_FILE (/tmp/test-token.txt default)

set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8000}"
ACCESS_CODE="${1:-${HAL_API_CODE:-${HAL_AI_CODE:-}}}"
BEARER_TOKEN="${HAL_API_BEARER:-${HAL_AI_BEARER:-}}"
BEARER_FILE="${HAL_API_BEARER_FILE:-${HAL_AI_BEARER_FILE:-/tmp/test-token.txt}}"

if [[ -z "$BEARER_TOKEN" && -f "$BEARER_FILE" ]]; then
  BEARER_TOKEN="$(<"$BEARER_FILE")"
fi

# Trim whitespace/newlines
ACCESS_CODE="$(echo -n "$ACCESS_CODE" | tr -d '[:space:]')"
BEARER_TOKEN="$(echo -n "$BEARER_TOKEN" | tr -d '[:space:]')"

curl_opts=(-sS -w "\nHTTP %{http_code}\n" --max-time 10)
[[ -n "$ACCESS_CODE" ]] && curl_opts+=( -H "X-Halext-Code: ${ACCESS_CODE}" )
[[ -n "$BEARER_TOKEN" ]] && curl_opts+=( -H "Authorization: Bearer ${BEARER_TOKEN}" )

declare -A STATUS

probe() {
  local label="$1"
  local path="$2"
  local method="${3:-GET}"
  if (($# > 3)); then
    shift 3
  else
    shift "$#"
  fi
  local extra=("$@")
  local resp status_line body
  resp=$(curl "${curl_opts[@]}" -X "$method" "${extra[@]}" "${BASE_URL}${path}" || true)
  status_line=$(printf "%s\n" "$resp" | tail -n 1)
  body=$(printf "%s\n" "$resp" | sed '$d')
  printf "== %s %s ==\n" "$method" "$path"
  printf "%s\n" "$body"
  printf "%s\n\n" "$status_line"
  STATUS["$label"]="${status_line#HTTP }"
}

echo "ℹ️  BASE_URL=${BASE_URL}"
[[ -n "$ACCESS_CODE" ]] && echo "✓ using access code"
[[ -n "$BEARER_TOKEN" ]] && echo "✓ using bearer token"

declare -A STATUS
probe health "/api/health"
probe user "/users/me/"
probe ai_info "/ai/provider-info"
probe ai_models "/ai/models"
probe conversations "/conversations/"

# Try to fetch messages for the first conversation if available
FIRST_CONV_ID=""
convo_json=$(curl -sS "${curl_opts[@]}" "${BASE_URL}/conversations/" || true)
if [[ "$convo_json" =~ \"id\"\:([0-9]+) ]]; then
  FIRST_CONV_ID="${BASH_REMATCH[1]}"
fi
if [[ -n "$FIRST_CONV_ID" ]]; then
  probe messages "/conversations/${FIRST_CONV_ID}/messages"
fi

echo "Summary:"
for k in health user ai_info ai_models conversations messages; do
  if [[ -n "${STATUS[$k]:-}" ]]; then
    printf "  %-14s %s\n" "$k" "${STATUS[$k]}"
  fi
done

if [[ -z "$ACCESS_CODE" ]]; then
  echo "Hint: set HAL_API_CODE/HAL_AI_CODE or pass access code as first arg if 401/403 occur." >&2
fi
if [[ -z "$BEARER_TOKEN" ]]; then
  echo "Hint: set HAL_API_BEARER/HAL_AI_BEARER or HAL_API_BEARER_FILE (default /tmp/test-token.txt)." >&2
fi
