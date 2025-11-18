#!/bin/bash
set -euo pipefail

# All-in-one bootstrap for org.halext.org on Ubuntu.
# Usage: sudo ./scripts/setup-org.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
FRONTEND_DIR="$ROOT_DIR/frontend"
WWW_DIR="${HALX_WWW_DIR:-/var/www/halext}"
DOMAIN="${HALX_DOMAIN:-org.halext.org}"
SERVICE_NAME="halext-api"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
NGINX_SITE="/etc/nginx/sites-available/${DOMAIN}"
NGINX_ENABLED="/etc/nginx/sites-enabled/${DOMAIN}"
SSL_SNIPPET="/etc/nginx/ssl/${DOMAIN}.conf"
ENV_FILE="$BACKEND_DIR/.env"
APT_UPDATED=0

PYTHON_BIN=""
DB_USER=""
DB_PASS=""
DB_NAME=""

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Try: sudo ./scripts/setup-org.sh"
    exit 1
  fi
}

check_dependencies() {
  local -a deps=(psql npm node rsync systemctl nginx curl sudo)
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if ! command -v python3.11 >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    missing+=("python3 (or python3.11)")
  fi

  if ! id -u www-data >/dev/null 2>&1; then
    missing+=("www-data user (install nginx)")
  fi

  if ((${#missing[@]})); then
    printf 'Missing dependencies: %s\n' "${missing[*]}"
    exit 1
  fi
}

choose_python() {
  if command -v python3.11 >/dev/null 2>&1; then
    PYTHON_BIN="$(command -v python3.11)"
  else
    PYTHON_BIN="$(command -v python3)"
  fi

  if [[ -z "$PYTHON_BIN" ]]; then
    echo "python3.11 or python3 is required but was not found."
    exit 1
  fi
}

apt_update_once() {
  if [[ "$APT_UPDATED" -eq 0 ]]; then
    apt-get update
    APT_UPDATED=1
  fi
}

install_postgres_service() {
  if ! command -v psql >/dev/null 2>&1; then
    if ! command -v apt-get >/dev/null 2>&1; then
      echo "apt-get not found; install PostgreSQL manually before rerunning."
      exit 1
    fi
    echo "Installing PostgreSQL packages..."
    apt_update_once
    apt-get install -y postgresql postgresql-contrib
  fi

  echo "Ensuring PostgreSQL service is enabled and running..."
  systemctl enable --now postgresql

  local tries=0
  until systemctl is-active --quiet postgresql || ((tries >= 10)); do
    tries=$((tries + 1))
    sleep 1
  done

  if ! systemctl is-active --quiet postgresql; then
    echo "PostgreSQL failed to start; check journalctl -u postgresql."
    exit 1
  fi
}

random_hex() {
  local length="${1:-32}"
  "$PYTHON_BIN" -c "import secrets; print(secrets.token_hex($length//2))"
}

parse_database_url() {
  local url="$1"
  mapfile -t parsed < <("$PYTHON_BIN" -c "import sys, urllib.parse; url=sys.argv[1]; parsed=urllib.parse.urlparse(url); user=parsed.username or 'halext_user'; password=parsed.password or ''; db=(parsed.path or '/')[1:] or 'halext_org'; print(user); print(password); print(db)" "$url")
  DB_USER="${parsed[0]}"
  DB_PASS="${parsed[1]}"
  DB_NAME="${parsed[2]}"
}

write_env_file() {
  local overwrite="y"

  if [[ -f "$ENV_FILE" ]]; then
    read -r -p "backend/.env exists. Keep existing file? [Y/n] " keep
    if [[ "${keep:-Y}" =~ ^[Yy]$ ]]; then
      overwrite="n"
    fi
  fi

  if [[ "$overwrite" == "y" ]]; then
    local db_name db_user db_pass access_code secret_key ai_provider
    read -r -p "Postgres database name [halext_org]: " db_name
    read -r -p "Postgres role/user [halext_user]: " db_user
    read -r -s -p "Postgres password (leave blank to auto-generate): " db_pass
    echo
    read -r -p "AI provider [mock]: " ai_provider
    read -r -p "Access code (invite code, leave blank for random): " access_code

    db_name="${db_name:-halext_org}"
    db_user="${db_user:-halext_user}"
    db_pass="${db_pass:-$(random_hex 24)}"
    ai_provider="${ai_provider:-mock}"
    access_code="${access_code:-$(random_hex 12)}"
    secret_key="$(random_hex 64)"

    cat >"$ENV_FILE" <<EOF
DATABASE_URL=postgresql://${db_user}:${db_pass}@127.0.0.1/${db_name}
ACCESS_CODE=${access_code}
SECRET_KEY=${secret_key}
AI_PROVIDER=${ai_provider}
EOF
    echo "Wrote $ENV_FILE."
  fi

  if [[ -f "$ENV_FILE" ]]; then
    local db_url
    db_url="$(grep -E '^DATABASE_URL=' "$ENV_FILE" | cut -d= -f2- || true)"
    if [[ -z "$db_url" ]]; then
      echo "DATABASE_URL missing in backend/.env. Please edit the file and re-run."
      exit 1
    fi
    parse_database_url "$db_url"
  else
    echo "Failed to create backend/.env."
    exit 1
  fi
}

ensure_postgres() {
  local escaped_pass
  escaped_pass="$(printf "%s" "$DB_PASS" | sed "s/'/''/g")"

  local role_exists
  role_exists="$(runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" || true)"
  if [[ "${role_exists// /}" != "1" ]]; then
    runuser -u postgres -- psql -c "CREATE ROLE ${DB_USER} LOGIN PASSWORD '${escaped_pass}'"
    echo "Created Postgres role ${DB_USER}."
  else
    runuser -u postgres -- psql -c "ALTER ROLE ${DB_USER} LOGIN PASSWORD '${escaped_pass}'"
    echo "Updated Postgres role ${DB_USER}."
  fi

  local db_exists
  db_exists="$(runuser -u postgres -- psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" || true)"
  if [[ "${db_exists// /}" != "1" ]]; then
    runuser -u postgres -- psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}"
    echo "Created database ${DB_NAME}."
  else
    runuser -u postgres -- psql -c "ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER}"
    echo "Ensured database ${DB_NAME} is owned by ${DB_USER}."
  fi
}

setup_backend() {
  echo "Setting up backend virtualenv with ${PYTHON_BIN}..."
  cd "$BACKEND_DIR"
  if [[ ! -d env ]]; then
    "$PYTHON_BIN" -m venv env
  fi
  "$BACKEND_DIR/env/bin/pip" install --upgrade pip
  "$BACKEND_DIR/env/bin/pip" install -r requirements.txt
}

build_frontend() {
  echo "Building frontend..."
  cd "$FRONTEND_DIR"
  npm install
  npm run build
  mkdir -p "$WWW_DIR"
  rsync -a --delete "$FRONTEND_DIR/dist/" "$WWW_DIR/"
  chown -R www-data:www-data "$WWW_DIR"
}

install_service() {
  echo "Installing systemd service (${SERVICE_NAME})..."
  cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=Halext FastAPI service
After=network.target

[Service]
WorkingDirectory=$BACKEND_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$BACKEND_DIR/env/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
User=www-data
Group=www-data

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now "$SERVICE_NAME"
  if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    systemctl status "$SERVICE_NAME" --no-pager || true
    echo "halext-api failed to start. Check journalctl -u halext-api for details."
    exit 1
  fi
}

configure_nginx() {
  echo "Configuring Nginx for ${DOMAIN}..."
  local tmp
  tmp="$(mktemp)"
  sed "s/app\\.halext\\.org/${DOMAIN}/g" "$ROOT_DIR/infra/ubuntu/halext.nginx.conf" >"$tmp"

  if [[ -f "$SSL_SNIPPET" ]]; then
    local tmp_with_ssl
    tmp_with_ssl="$(mktemp)"
    awk -v snippet="    include ${SSL_SNIPPET};" '
      /server_name/ {
        print
        print snippet
        next
      }
      { print }
    ' "$tmp" >"$tmp_with_ssl"
    mv "$tmp_with_ssl" "$tmp"
    echo "Including SSL snippet ${SSL_SNIPPET}."
  else
    echo "SSL snippet ${SSL_SNIPPET} not found. Skipping HTTPS include."
  fi

  cp "$tmp" "$NGINX_SITE"
  rm -f "$tmp"
  ln -sf "$NGINX_SITE" "$NGINX_ENABLED"
  nginx -t
  systemctl reload nginx

  if curl -fsS -H "Host: ${DOMAIN}" http://127.0.0.1 >/dev/null; then
    echo "Nginx host-header test passed for ${DOMAIN}."
  else
    echo "Warning: curl test against Nginx failed. Check /var/log/nginx/error.log."
  fi
}

main() {
  require_root
  install_postgres_service
  check_dependencies
  choose_python
  write_env_file
  ensure_postgres
  setup_backend
  build_frontend
  install_service
  configure_nginx

  cat <<EOF

Halext Org deployment complete!
- Backend env: $ENV_FILE
- Systemd unit: $SERVICE_FILE (running)
- Nginx site: $NGINX_SITE -> $NGINX_ENABLED

Next steps:
  * Verify DNS for ${DOMAIN} points here, then run certbot to create ${SSL_SNIPPET}.
  * Share the ACCESS_CODE from backend/.env with invitees.
  * Monitor tail logs with: journalctl -u ${SERVICE_NAME} -f
EOF
}

main "$@"
