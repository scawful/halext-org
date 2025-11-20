# OpenWebUI Integration Guide

Halext Org can embed and proxy OpenWebUI/Ollama so every client (web, Cafe iOS, desktop helpers) shares the same AI workspace. This document captures the full setup so you can bring the service online quickly on `org.halext.org`.

## 1. Provision OpenWebUI + Ollama

All automation lives in `scripts/setup-openwebui.sh`. It installs Docker, Ollama, and OpenWebUI, configures Nginx, and registers a systemd unit.

```bash
cd /srv/halext.org/halext-org
sudo ./scripts/setup-openwebui.sh
```

What the script does:

1. Installs Docker Engine (if missing) and Ollama, then pulls the `llama3.1` and `mistral` models.
2. Launches the OpenWebUI container on `127.0.0.1:3000`.
3. Creates `/etc/nginx/sites-available/openwebui.conf` with reverse proxy blocks for `/webui/` and `/ollama/`.
4. Drops `openwebui.service` so the container survives reboots.

After the script finishes:

- Include the proxy block inside your main server config, then reload nginx:

  ```nginx
  # inside /etc/nginx/sites-available/org.halext.org
      include /etc/nginx/sites-available/openwebui.conf;
  ```

  ```bash
  sudo systemctl reload nginx
  ```

- Browse to `https://org.halext.org/webui/` and create the initial admin account. Those credentials are needed by Halext for sync/SSO.

## 2. Configure the Halext backend

Edit `backend/.env`:

```env
AI_PROVIDER=openwebui
OPENWEBUI_URL=http://127.0.0.1:3000
OPENWEBUI_PUBLIC_URL=https://org.halext.org/webui/
OPENWEBUI_SYNC_ENABLED=true
OPENWEBUI_ADMIN_EMAIL=admin@example.com
OPENWEBUI_ADMIN_PASSWORD=super-secret
```

`OPENWEBUI_URL` should always point to the internal service that the FastAPI backend can reach (typically `127.0.0.1:3000`). `OPENWEBUI_PUBLIC_URL` is what browsers and SSO redirects will use, so aim it at the public HTTPS path (for example `https://org.halext.org/webui/`). When both values are identical you can omit the public variable.

Then restart the API:

```bash
./scripts/server-deploy.sh --backend-only
# or
sudo systemctl restart halext-api
```

Once the service reloads, `/integrations/openwebui/*` endpoints will return live data and the dashboard widget will flip from “not configured” to the status view.

## 3. How clients access OpenWebUI

**Web dashboard**  
The `OpenWebUI` widget lets you:

- Run the `/integrations/openwebui/sync/user` operation (provisions a matching account inside OpenWebUI).
- Launch a new tab via `/integrations/openwebui/sso`, which returns a signed link that logs you straight into `https://org.halext.org/webui/`.

**Cafe (iOS) + future native clients**  
Use the same SSO endpoint:

```http
POST /integrations/openwebui/sso
Authorization: Bearer <halext-token>
Content-Type: application/json
{
  "redirect_to": "https://org.halext.org/webui/"
}
```

The response payload contains `sso_url`. Open that in a `SFSafariViewController`, WebView, or the platform browser to hand the user into OpenWebUI without another login prompt. If the account has not yet been provisioned, call `/integrations/openwebui/sync/user` once before requesting SSO.

**LLM data from desktops/macOS/Windows**  
Push context into the Halext conversation APIs and let the backend talk to OpenWebUI/Ollama on behalf of every device:

1. `POST /conversations/` – create/find a conversation owned by the current user (optionally add collaborators).
2. `POST /conversations/{conversation_id}/messages` – append chat history. When `AI_PROVIDER=openwebui`, the backend streams replies by hitting OpenWebUI’s `/api/v1/chat/completions`.
3. Read the shared thread via `GET /conversations/{conversation_id}/messages` from web, iOS, or a desktop helper.

This keeps your desktops free from direct model traffic: they only need the Halext token and HTTPS access to the API, while the server-side `AiGateway` handles talking to OpenWebUI/Ollama and can fetch additional context (tasks, events, Zeniea data) before it calls the model.

## 4. Verification checklist

- `curl http://127.0.0.1:3000/api/v1/models` returns a JSON payload.
- `/integrations/openwebui/sync/status` shows `enabled: true` and the correct URL.
- Visiting `https://org.halext.org/webui/` loads the OpenWebUI login page (or auto-logs in via SSO).
- The dashboard widget no longer shows “OpenWebUI is not configured.”
- Posting a Halext conversation message results in an AI reply sourced from OpenWebUI (check backend logs for `OpenWebUI error` to confirm it is quiet).

Once these steps pass, every first-party app—Halext web, Cafe iOS, and future macOS/Windows helpers—can rely on the same OpenWebUI/Ollama stack without duplicating the model install per device.
