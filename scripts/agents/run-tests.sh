#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

pushd "${ROOT_DIR}" >/dev/null

if [ -d "backend/tests" ]; then
  echo "[run-tests] running pytest"
  pushd backend >/dev/null
  export AI_OFFLINE="${AI_OFFLINE:-1}"
  if [ -f "env/bin/activate" ]; then
    source env/bin/activate && python -m pytest -q
    deactivate
  else
    echo "[run-tests] virtualenv not found; skipping backend pytest (set up backend/env to enable)"
  fi
  popd >/dev/null
else
  echo "[run-tests] no backend/tests directory; falling back to py_compile"
  python3 -m compileall backend/main.py backend/app >/dev/null
fi

popd >/dev/null

echo "[run-tests] ok"
