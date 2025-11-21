# Backend Deploy Strategy (halext-server)

Use these steps to deploy a backend change to the `halext-api` service on the server. Commands assume the checked-out repo lives at `/srv/halext.org/halext-org` and `systemd` unit name is `halext-api.service`.

## Compatibility
- **Python:** use `python3` (server defaults `python` → 2.7). All code is Python 3.8+ compatible; avoid running tooling with the `python` shim.
- **Env:** keep `DEV_MODE=false` in production; leave `AI_OFFLINE` unset so real providers are enabled. Tests/scripts may set `AI_OFFLINE=1` locally only.

## Deploy Steps
```bash
ssh halext-server
cd /srv/halext.org/halext-org

# 1) Sanity: confirm python version
python3 --version

# 2) Update code
git fetch --all
git checkout main
git pull --ff-only

# 3) Virtualenv (recreate if missing/stale)
python3 -m venv backend/env
source backend/env/bin/activate
pip install --upgrade pip
pip install -r backend/requirements.txt

# 4) Migrations (if alembic migrations exist)
cd backend
if [ -d "migrations" ]; then
  python -m alembic upgrade head
fi

# 5) Fast syntax sanity
python3 -m py_compile app/ai.py main.py app/env_validation.py

# 6) Optional: offline pytest (mocks AI)
AI_OFFLINE=1 python -m pytest -q || true
deactivate

# 7) Restart service
sudo systemctl restart halext-api.service
sudo systemctl status halext-api.service --no-pager

# 8) Health checks (requires access code/bearer)
HAL_AI_CODE=<code> HAL_AI_BEARER_FILE=/tmp/test-token.txt ../scripts/agents/ai-health-auth.sh
HAL_API_CODE=<code> HAL_API_BEARER_FILE=/tmp/test-token.txt ../scripts/agents/ios-api-smoke.sh

# 9) Logs if needed
sudo journalctl -u halext-api.service -n 120 -f
```

## Notes
- If `ACCESS_CODE` changes, update `backend/.env` and restart before health checks.
- If dependencies fail on the server, rerun `pip install -r backend/requirements.txt` inside the `backend/env` venv (never system Python).
- The env validator now reports warnings in `/api/health` (e.g., missing provider keys); use it after deploy to confirm configuration.***
