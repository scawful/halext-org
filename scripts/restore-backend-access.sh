#!/bin/bash
set -euo pipefail

# Restores production backend settings:
#  - Forces DEV_MODE=false inside backend/.env
#  - Sets/rotates ACCESS_CODE
#  - Optionally seeds a user via create_dev_user.py
#  - Optionally restarts the halext-api systemd service

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
ENV_FILE="$BACKEND_DIR/.env"
VENV_PY="$BACKEND_DIR/env/bin/python"
SERVICE_NAME="${HALX_SERVICE_NAME:-halext-api}"
DOMAIN="${HALX_DOMAIN:-org.halext.org}"

ACCESS_CODE="${HALX_ACCESS_CODE:-}"
SHOULD_CREATE_USER=0
USERNAME=""
PASSWORD=""
EMAIL=""
FULL_NAME=""
RESTART_SERVICE=1

usage() {
  cat <<'USAGE'
Usage: scripts/restore-backend-access.sh [options]

Options:
  --access-code CODE     Set/rotate ACCESS_CODE (or set HALX_ACCESS_CODE env var)
  --username NAME        Seed a user (requires --password and --email)
  --password PASS        Password for the seeded user
  --email ADDRESS        Email for the seeded user
  --full-name NAME       Optional full name for the seeded user
  --skip-restart         Do not restart the backend service automatically
  --service-name NAME    Override systemd unit name (default: halext-api)
  --help                 Show this message

The script must be run on the Ubuntu server from the repo root. It updates
backend/.env (forcing DEV_MODE=false and writing ACCESS_CODE), optionally
creates a user via create_dev_user.py, and restarts the backend so changes
take effect.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --access-code)
      ACCESS_CODE="$2"
      shift 2
      ;;
    --username)
      USERNAME="$2"
      SHOULD_CREATE_USER=1
      shift 2
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    --email)
      EMAIL="$2"
      shift 2
      ;;
    --full-name)
      FULL_NAME="$2"
      shift 2
      ;;
    --skip-restart)
      RESTART_SERVICE=0
      shift
      ;;
    --service-name)
      SERVICE_NAME="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "backend/.env not found at $ENV_FILE. Copy infra/ubuntu/.env.example first." >&2
  exit 1
fi

if [[ -z "$ACCESS_CODE" ]]; then
  read -r -p "Enter new ACCESS_CODE (leave blank to generate): " ACCESS_CODE
  if [[ -z "$ACCESS_CODE" ]]; then
    ACCESS_CODE="$(python3 -c 'import secrets; print(secrets.token_hex(8))')"
    echo "Generated ACCESS_CODE: $ACCESS_CODE"
  fi
fi

if [[ $SHOULD_CREATE_USER -eq 1 ]]; then
  if [[ -z "$USERNAME" || -z "$PASSWORD" || -z "$EMAIL" ]]; then
    echo "Seeding a user requires --username, --password, and --email." >&2
    exit 1
  fi
fi

python3 <<'PY' "$ENV_FILE" "$ACCESS_CODE"
import sys
from pathlib import Path

env_path = Path(sys.argv[1])
access_code = sys.argv[2]
updates = {
    "DEV_MODE": "false",
    "ACCESS_CODE": access_code,
}

lines = env_path.read_text().splitlines()
seen = set()
new_lines = []

for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith("#") or "=" not in line:
        new_lines.append(line)
        continue
    key, _, value = line.partition("=")
    key = key.strip()
    if key in updates:
        new_lines.append(f"{key}={updates[key]}")
        seen.add(key)
    else:
        new_lines.append(line)

for key, value in updates.items():
    if key not in seen:
        new_lines.append(f"{key}={value}")

env_path.write_text("\n".join(new_lines) + "\n")
PY

echo "Updated backend/.env (DEV_MODE=false, ACCESS_CODE set)."

DB_URL="$(grep -E '^DATABASE_URL=' "$ENV_FILE" | tail -n1 | cut -d= -f2- || true)"
if [[ -z "$DB_URL" ]]; then
  echo "WARNING: DATABASE_URL missing in backend/.env. Update it before restarting." >&2
elif [[ "$DB_URL" != postgresql://* ]]; then
  echo "WARNING: DATABASE_URL does not point to PostgreSQL (${DB_URL})." >&2
else
  echo "DATABASE_URL points to PostgreSQL."
fi

if [[ $SHOULD_CREATE_USER -eq 1 ]]; then
  if [[ ! -x "$VENV_PY" ]]; then
    echo "Python virtualenv not found at $VENV_PY. Run scripts/server-deploy.sh first." >&2
    exit 1
  fi
  pushd "$BACKEND_DIR" >/dev/null
  CMD=("$VENV_PY" create_dev_user.py --username "$USERNAME" --password "$PASSWORD" --email "$EMAIL")
  if [[ -n "$FULL_NAME" ]]; then
    CMD+=("--full-name" "$FULL_NAME")
  fi
  if "${CMD[@]}"; then
    echo "Seeded user '$USERNAME'."
  else
    echo "Failed to seed user '$USERNAME'." >&2
    exit 1
  fi
  popd >/dev/null
fi

if [[ $RESTART_SERVICE -eq 1 ]]; then
  if command -v systemctl >/dev/null 2>&1; then
    if sudo systemctl restart "$SERVICE_NAME" 2>/dev/null || systemctl restart "$SERVICE_NAME"; then
      echo "Restarted $SERVICE_NAME."
    else
      echo "WARNING: Unable to restart $SERVICE_NAME automatically. Restart it manually." >&2
    fi
  else
    echo "systemctl not available; restart the backend manually." >&2
  fi
else
  echo "Skipping service restart (requested). Remember to run: sudo systemctl restart $SERVICE_NAME"
fi

if command -v curl >/dev/null 2>&1; then
  if curl -fsS -H "Host: $DOMAIN" http://127.0.0.1/api/health >/dev/null; then
    echo "Backend health check passed."
  else
    echo "WARNING: Health check failed. Inspect journalctl -u $SERVICE_NAME." >&2
  fi
fi

cat <<SUMMARY

Next steps:
  1. Share the new ACCESS_CODE with invitees: $ACCESS_CODE
  2. If you seeded users, have them log in normally.
  3. Verify the SPA at https://$DOMAIN loads and registration enforces the access code.
SUMMARY
