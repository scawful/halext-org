# AI Model Routing Rollout Plan

The backend now exposes a unified `/ai/models` catalog plus provider-aware `/ai/chat` and `/ai/stream` routes. OpenAI, Gemini, OpenWebUI, and remote Ollama clients (Mac/Windows) all surface as normalized model identifiers such as `openai:gpt-4o-mini` or `client:3:llama3.1`. The next step is to surface that control in the web UI and iOS app.

## Backend recap
- `GET /ai/models` → returns `{ id, provider, source, node_name, latency_ms, metadata }` for every accessible model.
- `POST /ai/chat` / `/ai/stream` → accept `model` identifiers and return the resolved route so we know which worker replied.
- `AI_DEFAULT_MODEL` env var lets ops pin the default to a remote node (`client:<id>:<model>`).
- `/admin/ai-clients` already manages remote Ollama/OpenWebUI instances; nodes are filtered per owner/public visibility.

## Web UI integration steps
1. **Model Catalog Drawer**
   - Add a React query hook (`useAiModels`) that polls `/ai/models` with caching.
   - Display providers grouped by `source` (OpenAI, Gemini, Remote Clients, etc.) along with node health badges.
2. **User-level selection**
   - Store the selected `modelId` in user preferences (API field or local storage) and pass it to `sendChatMessage`/`streamChatMessage`.
   - Surface the active model in AI Chat, Task Assistant, and Event Assistant headers.
3. **Admin visibility**
   - Extend the existing Admin → AI Clients section to show which models from each node are registered and expose a “copy identifier” action.
4. **Fallback UX**
   - When `/ai/models` returns only mock entries, show a call-to-action guiding the user to add a provider or request access.

## iOS integration steps
1. **API client**
   - Update `AIProviderInfo` and `AIModelsResponse` structs to match the backend schema (`default_model_id`, `models[].id`, etc.).
   - Add a `getAIModels()` call that caches results for quick picker rendering.
2. **Settings screen**
   - Introduce an "AI Sources" view where users can browse available models, see the device (Mac/Windows) behind each one, and mark a default.
   - Persist the chosen `modelId` in the existing settings store and send it with AI requests.
3. **Chat/task surfaces**
   - Show the active model badge in AI Chat threads and Task suggestions; allow quick switching via a sheet that lists `/ai/models` entries.
4. **Streaming**
   - Attach the `X-Halext-AI-Model` header returned by `/ai/stream` to debug overlays so we can confirm which client handled a conversation.

## Operational checklist
- Document how to register new remote nodes (MacBook Pro M1, Windows gaming PC) and map them to friendly names so the UI can display "Mac Studio (llama3.1)" instead of `client:3:llama3.1`.
- Add monitoring for `/ai/models` so we are alerted if cloud providers fail or remote nodes drop offline.
- Once UI clients ship, enforce per-user quotas via the `AIUsageLog`/`UserAIQuota` tables outlined in `docs/AI_ARCHITECTURE.md`.
