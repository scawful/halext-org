#!/usr/bin/env bash
# Lightweight AI endpoint probe for local/remote teammates.
# Headers:
#   - X-Halext-Code: set via HAL_AI_CODE or first CLI argument (access code)
#   - Authorization: Bearer <token> set via HAL_AI_BEARER or HAL_AI_BEARER_FILE
#
# Usage:
#   scripts/agents/ai-health.sh                          # unauthenticated checks
#   HAL_AI_CODE=accesscode scripts/agents/ai-health.sh   # include X-Halext-Code
#   HAL_AI_BEARER_FILE=/tmp/test-token.txt scripts/agents/ai-health.sh
#   HAL_AI_CODE=code HAL_AI_BEARER=token scripts/agents/ai-health.sh
#   scripts/agents/ai-health.sh accesscode               # legacy arg form

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000}"
ACCESS_CODE="${1:-${HAL_AI_CODE:-${HAL_AI_TOKEN:-}}}"
BEARER_TOKEN="${HAL_AI_BEARER:-}"

if [[ -z "$BEARER_TOKEN" && -n "${HAL_AI_BEARER_FILE:-}" ]]; then
  if [[ -f "$HAL_AI_BEARER_FILE" ]]; then
    BEARER_TOKEN="$(<"$HAL_AI_BEARER_FILE")"
  else
    echo "WARN: HAL_AI_BEARER_FILE set but file not found: $HAL_AI_BEARER_FILE" >&2
  fi
fi

curl_opts=(-sS -w "\nHTTP %{http_code}\n" --max-time 10)

if [[ -n "$ACCESS_CODE" ]]; then
  curl_opts+=( -H "X-Halext-Code: ${ACCESS_CODE}" )
fi

if [[ -n "$BEARER_TOKEN" ]]; then
  curl_opts+=( -H "Authorization: Bearer ${BEARER_TOKEN}" )
fi

echo "🌐 Probing ${BASE_URL}/ai/provider-info"
if ! curl "${curl_opts[@]}" "${BASE_URL}/ai/provider-info"; then
  echo "provider-info probe failed" >&2
fi

echo
echo "🌐 Probing ${BASE_URL}/ai/models"
if ! curl "${curl_opts[@]}" "${BASE_URL}/ai/models"; then
  echo "models probe failed" >&2
fi

echo
if [[ -z "$ACCESS_CODE" ]]; then
  echo "Note: Provide HAL_AI_CODE or first arg to include X-Halext-Code when auth is required."
fi
if [[ -z "$BEARER_TOKEN" ]]; then
  echo "Note: Provide HAL_AI_BEARER or HAL_AI_BEARER_FILE to include Authorization header."
fi
