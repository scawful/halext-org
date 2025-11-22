#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
UVICORN_BIN="$BACKEND_DIR/env/bin/uvicorn"
PYTHON_BIN="$BACKEND_DIR/env/bin/python"
DEFAULT_DB_URL="${DATABASE_URL:-sqlite:////Users/scawful/Code/halext-org/halext_dev.db}"
SQLITE_FALLBACK_URL="sqlite:////Users/scawful/Code/halext-org/halext_dev.db"
HOST="${HALTEXT_API_HOST:-127.0.0.1}"
PORT="${HALTEXT_API_PORT:-8000}"

if [[ ! -x "$UVICORN_BIN" ]]; then
  echo "Cannot find $UVICORN_BIN. Activate the backend virtualenv first (cd backend && python3 -m venv env && pip install -r requirements.txt)." >&2
  exit 1
fi

DB_URL_TO_USE="$DEFAULT_DB_URL"
if [[ "$DB_URL_TO_USE" == postgresql://* || "$DB_URL_TO_USE" == postgres://* ]]; then
  echo "Checking Postgres availability at $DB_URL_TO_USE ..."
  if ! DATABASE_URL_CHECK="$DB_URL_TO_USE" "$PYTHON_BIN" - <<'PY' >/dev/null 2>&1
import os
from sqlalchemy import create_engine
from sqlalchemy.exc import OperationalError

url = os.environ["DATABASE_URL_CHECK"]
engine = create_engine(url)
try:
    with engine.connect() as conn:
        conn.execute("SELECT 1")
except OperationalError:
    raise SystemExit(1)
PY
  then
    echo "Postgres connection failed. Falling back to SQLite at $SQLITE_FALLBACK_URL"
    DB_URL_TO_USE="$SQLITE_FALLBACK_URL"
  else
    echo "Postgres is reachable."
  fi
fi

echo "Starting Halext API with DATABASE_URL=$DB_URL_TO_USE (host $HOST port $PORT)"
cd "$BACKEND_DIR"
DATABASE_URL="$DB_URL_TO_USE" "$UVICORN_BIN" main:app --host "$HOST" --port "$PORT"
