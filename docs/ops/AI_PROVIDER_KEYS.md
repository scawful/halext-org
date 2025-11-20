# Cloud AI Keys & Routing

Use this checklist to offload Halext AI traffic to OpenAI or Gemini (instead of the VM’s vCPUs) and keep credentials out of `.env`.

## Where to set keys
- **UI:** Admin → **AI Clients** → *Cloud API Credentials* (OpenAI or Gemini). Paste the key, pick a default model, and save.
- **API:** `POST /admin/ai/credentials` with `{"provider":"openai","api_key":"sk-...","model":"gpt-4o-mini"}` (or `provider:"gemini"`).
- Stored keys are **encrypted** with `API_KEY_ENCRYPTION_KEY` (falls back to `SECRET_KEY` if unset). Only masked tails are returned to the UI.

## How routing works after saving
- Providers are loaded from the database on every AI call; no backend restart is required.
- When a cloud key exists, the backend prefers it as the default model (`openai:<model>` or `gemini:<model>`), so chats, task suggestions, and embeddings avoid the local Ollama/OpenWebUI path unless explicitly selected.
- `/ai/models` now surfaces OpenAI and Gemini models when keys are present, and the web/iOS clients can pick them as defaults.

## Operational notes
- Keep `API_KEY_ENCRYPTION_KEY` in the backend `.env` for stable Fernet encryption across deploys.
- You can rotate the key by re-saving a new value in the Admin UI; the stored ciphertext updates immediately.
- OpenWebUI can stay online for embedding/SSO (`http://127.0.0.1:3000` / `/webui/`), but cloud providers will carry the heavy AI load.
