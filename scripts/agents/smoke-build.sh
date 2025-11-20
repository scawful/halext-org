#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "[smoke-build] repo: ${ROOT_DIR}" | sed 's#'"${HOME}"'#~#'

pushd "${ROOT_DIR}" >/dev/null

echo "[smoke-build] compiling backend python files"
python3 -m compileall backend/main.py backend/app >/dev/null

if [ -d "backend/app" ]; then
  python3 -m py_compile backend/main.py backend/app/*.py >/dev/null 2>&1 || true
fi

pushd frontend >/dev/null
if [ ! -d node_modules ]; then
  echo "[smoke-build] node_modules missing, running npm install"
  npm install >/dev/null
fi

echo "[smoke-build] running npm run build"
npm run build
popd >/dev/null

popd >/dev/null

echo "[smoke-build] complete"
