#!/bin/bash
set -euo pipefail

# Manage Cloudflare’s proxy setting for org.halext.org and optionally run certbot.
# Requires CF_API_TOKEN with Zone.Zone and Zone.DNS permissions.

DOMAIN="${CF_FULL_DOMAIN:-org.halext.org}"
ZONE_NAME="${CF_ZONE_NAME:-halext.org}"
CF_API_TOKEN="${CF_API_TOKEN:-}"
CERTBOT_CMD="${CERTBOT_CMD:-sudo certbot --nginx -d $DOMAIN}"
CF_API="https://api.cloudflare.com/client/v4"
PYTHON_BIN="$(command -v python3 || true)"

usage() {
  cat <<EOF
Usage: $0 [status|disable|enable|toggle|certbot]

Commands:
  status   – show whether $DOMAIN is proxied via Cloudflare.
  disable  – switch the DNS record to DNS-only.
  enable   – re-enable Cloudflare proxying.
  toggle   – flip the current proxy state.
  certbot  – disable the proxy, run $CERTBOT_CMD, then re-enable.

Environment variables:
  CF_API_TOKEN   – Cloudflare API token (required).
  CF_ZONE_NAME   – Cloudflare zone name (default: halext.org).
  CF_FULL_DOMAIN – FQDN to manage (default: org.halext.org).
EOF
  exit 1
}

ensure_env() {
  if [[ -z "$CF_API_TOKEN" ]]; then
    echo "CF_API_TOKEN must be set."
    exit 1
  fi

  if [[ -z "$ZONE_NAME" ]]; then
    echo "CF_ZONE_NAME must be set."
    exit 1
  fi
}

ensure_python() {
  if [[ -z "$PYTHON_BIN" ]]; then
    echo "python3 is required but not installed."
    exit 1
  fi
}

get_zone_id() {
  local response
  response=$(curl -sSf -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    "$CF_API/zones?name=${ZONE_NAME}&status=active")
  if [[ -z "$response" ]]; then
    echo "Cloudflare API returned empty response when fetching zone ${ZONE_NAME}."
    cat <<'EOF'
Hint: confirm CF_API_TOKEN has Zone.Zone/Zone.DNS permissions and the VM can reach api.cloudflare.com.
EOF
    exit 1
  fi
  printf '%s' "$response" | "$PYTHON_BIN" - "$ZONE_NAME" <<PY
import json, sys
zone = sys.argv[1]
payload = sys.stdin.read()
try:
    data = json.loads(payload)
except json.JSONDecodeError as exc:
    print(f"Cloudflare zone response for {zone} was not JSON: {exc}")
    print(payload)
    sys.exit(1)
if not data.get("success") or not data.get("result"):
    raise SystemExit("failed to lookup zone: " + str(data.get("errors", data)))
print(data["result"][0]["id"])
PY
}

get_record_json() {
  local zone_id="$1"
  local response
  response=$(curl -sSf -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    "$CF_API/zones/$zone_id/dns_records?type=A&name=${DOMAIN}")
  if [[ -z "$response" ]]; then
    echo "Cloudflare API returned empty response when fetching record ${DOMAIN}."
    exit 1
  fi
  printf '%s' "$response" | "$PYTHON_BIN" - "$DOMAIN" <<PY
import json, sys
domain = sys.argv[1]
payload = sys.stdin.read()
try:
    data = json.loads(payload)
except json.JSONDecodeError as exc:
    print(f"Cloudflare record response for {domain} was not JSON: {exc}")
    print(payload)
    sys.exit(1)
if not data.get("success") or not data.get("result"):
    raise SystemExit("failed to lookup record: " + str(data.get("errors", data)))
print(json.dumps(data["result"][0]))
PY
}

extract_json_field() {
  local json="$1"
  local field="$2"
  "$PYTHON_BIN" - "$json" "$field" <<PY
import json, sys
data = json.loads(sys.argv[1])
paths = sys.argv[2].split(".")
value = data
for part in paths:
    value = value.get(part)
    if value is None:
        break
print(value)
PY
}

update_record() {
  local zone_id="$1"
  local record_id="$2"
  local content="$3"
  local proxied="$4"
  local response
  response=$(curl -sSf -X PUT \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$(printf '{"type":"A","name":"%s","content":"%s","proxied":%s,"ttl":1}' "$DOMAIN" "$content" "$proxied")" \
    "$CF_API/zones/$zone_id/dns_records/$record_id")
  printf '%s' "$response" | "$PYTHON_BIN" - "$DOMAIN" <<PY
import json, sys
domain = sys.argv[1]
payload = sys.stdin.read()
try:
    data = json.loads(payload)
except json.JSONDecodeError as exc:
    print(f"Cloudflare update response for {domain} was not JSON: {exc}")
    print(payload)
    sys.exit(1)
if not data.get("success"):
    raise SystemExit("failed to update record: " + str(data.get("errors", data)))
print("updated record")
PY
}

ensure_env
ensure_python
zone_id=$(get_zone_id)
record_json=$(get_record_json "$zone_id")
record_id=$(extract_json_field "$record_json" "id")
content=$(extract_json_field "$record_json" "content")
proxied=$(extract_json_field "$record_json" "proxied")

cmd="${1:-status}"
case "$cmd" in
  status)
    echo "$DOMAIN proxied=$proxied"
    ;;
  disable)
    if [[ "$proxied" == "False" ]]; then
      echo "Already DNS-only."
    else
      update_record "$zone_id" "$record_id" "$content" false
    fi
    ;;
  enable)
    if [[ "$proxied" == "True" ]]; then
      echo "Already proxied."
    else
      update_record "$zone_id" "$record_id" "$content" true
    fi
    ;;
  toggle)
    local newproxied
    if [[ "$proxied" == "True" ]]; then
      newproxied=false
    else
      newproxied=true
    fi
    update_record "$zone_id" "$record_id" "$content" "$newproxied"
    ;;
  certbot)
    if [[ "$proxied" == "True" ]]; then
      echo "Disabling proxy for $DOMAIN..."
      update_record "$zone_id" "$record_id" "$content" false
    fi
    echo "Running: $CERTBOT_CMD"
    eval "$CERTBOT_CMD"
    echo "Re-enabling proxy..."
    update_record "$zone_id" "$record_id" "$content" true
    ;;
  *)
    usage
    ;;
esac
