# Mac Handoff – Search Redeploy & AI Health via `ssh halext-server`

This handoff is for the macOS agent who needs to rebuild/push the SPA (including global search) and run the new AI health checks over the `ssh halext-server` interface. Keep secrets off git; pull access code/token from the server-side notes.

## Quick Path (frontend/search redeploy from mac)
1) Ensure `ssh halext-server` works (see `docs/ops/AGENTS.md` for the alias). Confirm repo synced locally: `git pull origin main`.
2) From your mac repo root, set deploy env (one-time in shell or `scripts/frontend-deploy.env`):
   - `export HALX_REMOTE=halext-server`
   - `export HALX_REMOTE_DIR=/var/www/halext`
   - `export HALX_POST_DEPLOY="sudo systemctl reload nginx"` (optional but recommended)
3) Build and sync SPA (includes search):
   ```bash
   ./scripts/deploy-frontend-local.sh --dry-run   # inspect rsync plan
   ./scripts/deploy-frontend-local.sh             # builds + rsyncs dist/ to server
   ```
   The script handles `npm ci` and caches node_modules via `.package-lock.local.sha256`.
4) Smoke the deployed SPA:
   ```bash
   ssh halext-server "curl -Ik -H 'Host: org.halext.org' https://127.0.0.1"
   # Optionally open in browser and hit / (Cmd+/ focuses search)
   ```

## AI endpoint checks via helper script
- Token/cache lives on the server only: see `/srv/halext.org/agent-notes/ai-health-token.txt` for refresh steps and the bearer token path (`/tmp/test-token.txt`). Do **not** commit the token or access code.
- Run checks over SSH:
  ```bash
  ssh halext-server "cd /srv/halext.org/halext-org && \
    HAL_AI_CODE=<access-code> HAL_AI_BEARER_FILE=/tmp/test-token.txt scripts/agents/ai-health.sh"
  ```
- If 404/500 persists on `/ai/provider-info` or `/ai/models`, ensure the running backend matches current `main` before restarting. If restarting, first verify `backend/env` has deps (`pip install -r requirements.txt` ensures `psutil` is present).

## Refreshing the bearer token (server-local)
- Follow `/srv/halext.org/agent-notes/ai-health-token.txt` for the exact curl/python snippet to recreate the `agentdev` user and write `/tmp/test-token.txt`.
- Access code should be supplied at runtime (do not store in repo); keep using the server note for retrieval.

## What to log on the board
- Append an entry noting the deploy (rsync) run, AI health probe outcome, and any backend restarts performed. Mention `scripts/agents/ai-health.sh` and whether nginx reload ran.
