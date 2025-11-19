#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Halext multi-site health check

Usage:
  scripts/site-health-check.sh [--public] [--timeout SECONDS]

Options:
  --public         Hit the public DNS endpoints (Cloudflare, etc.) instead of the
                   origin IP / 127.0.0.1. Useful once the edge is healthy again.
  --timeout N      Override curl timeout in seconds (default: 8).
  -h, --help       Show this message.

By default the script probes the origin (http://127.0.0.1) with Host headers so
Cloudflare outages or DNS issues do not skew the results.
USAGE
}

MODE="origin"
TIMEOUT="8"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --public)
      MODE="public"
      shift
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

BASE_ORIGIN="${HALX_HEALTH_ORIGIN:-http://127.0.0.1}"
CURL_BIN="$(command -v curl)"
if [[ -z "$CURL_BIN" ]]; then
  echo "curl not installed" >&2
  exit 1
fi

printf '\n=== Halext Multi-site Health Check (%s mode) ===\n' "$MODE"
printf 'Timestamp: %s\n\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

HOST_CHECKS=(
  "halext.org|/|200|Labs landing"
  "halext.org|/apply.php|200|Form endpoint"
  "halext.org|/docs/Assignment3.pdf|200|Static docs"
  "api.halext.org|/|200|API / OpenWebUI proxy"
  "zeniea.com|/|200|Zeniea timeline"
  "zeniea.com|/?login|200|Zeniea login"
  "absentstud.io|/|200|Static blog"
  "camora.net|/|200|Camora"
  "blocknote.live|/|200|Blocknote"
  "justinscofield.com|/|200|Portfolio"
  "freeforyallclt.com|/|410|Intentional sunset"
)

printf '%-24s %-7s %-8s %s\n' "Host" "Status" "Time" "Notes"
printf '%-24s %-7s %-8s %s\n' "------------------------" "-------" "--------" "-----"

for entry in "${HOST_CHECKS[@]}"; do
  IFS='|' read -r host path expected label <<< "$entry"
  if [[ "$MODE" == "origin" ]]; then
    url="${BASE_ORIGIN%/}$path"
    status_info="$($CURL_BIN -sS -o /dev/null -m "$TIMEOUT" -H "Host: $host" -w '%{http_code} %{time_total}' "$url" || echo "000 0")"
  else
    url="https://$host$path"
    status_info="$($CURL_BIN -sS -o /dev/null -m "$TIMEOUT" -k -w '%{http_code} %{time_total}' "$url" || echo "000 0")"
  fi
  code="${status_info%% *}"
  rtime="${status_info##* }"
  result="OK"
  [[ "$code" != "$expected" ]] && result="WARN"
  printf '%-24s %-7s %-8s [%s] %s\n' "$host$path" "$code" "$rtime" "$result" "$label"
done

printf '\nService status:\n'
SERVICES=(nginx mysql php7.2-fpm php7.4-fpm)
for svc in "${SERVICES[@]}"; do
  if systemctl list-unit-files "$svc" >/dev/null 2>&1; then
    if systemctl is-active --quiet "$svc"; then
      printf '  %-12s %s\n' "$svc" "active"
    else
      printf '  %-12s %s\n' "$svc" "INACTIVE"
    fi
  else
    printf '  %-12s %s\n' "$svc" "not-installed"
  fi
done

printf '\nTips:\n'
printf '  - Use sudo journalctl -u nginx -n 50 for detailed reverse-proxy errors.\n'
printf '  - Use sudo tail -f /var/log/nginx/error.log while reproducing a failure.\n'
printf '  - php7.2-fpm/php7.4-fpm logs live under /var/log/. Use sudo or add your user to the adm group.\n'
printf '\nDone.\n'
