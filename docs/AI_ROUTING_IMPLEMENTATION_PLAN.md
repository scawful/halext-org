# AI Routing Implementation Plan

This document expands on `docs/AI_ROUTING_ROADMAP.md` with concrete next steps for exposing the new model router everywhere (web app, iOS, APIs) while keeping it simple for agents to control. Follow the sections below in order; each task is scoped so another agent can pick up a subsection independently.

## 0. Prerequisites & Quick Commands
- **Verify backend schema**: `GET /ai/models` should list `id`, `provider`, `node_name`, `latency_ms`. If not, restart backend (`ssh -t halext-server 'sudo systemctl restart halext-api'`).
- **Register remote nodes**: Use the Admin → AI Clients panel or `POST /admin/ai-clients` to add the MacBook Pro + Windows GPU boxes. Mark `is_public=true` so everyone sees them.
- **Pin defaults**: Export `AI_DEFAULT_MODEL=client:<node_id>:<model>` in the backend `.env` so the default chat uses remote horsepower.

## 1. Backend polish (before UI)
1. `backend/main.py`
   - Add `model` param passthrough on `/ai/tasks/*`, `/ai/events/*`, and `/ai/notes/*` endpoints so clients can override the model for each request.
   - Ensure `AiTaskHelper`, `AiEventHelper`, etc., accept the model identifier and forward it down to `AiGateway.generate_reply`.
2. Logging
   - Extend `AIUsageLog` (if not yet created) to capture `route.identifier` plus `user_id` and `conversation_id` (if present).
   - Add middleware or helper that calls `log_ai_usage(user.id, route.identifier, prompt_len, response_len)` on every chat/task/event call.
3. Group chat
   - When `conversation.with_ai` is true for a multi-user conversation, store the resolved model on each AI reply so the UI can display "Response via Mac Studio (llama3.1)".

## 2. React Web UI integration
### 2.1 Central AI state
- Create `useAiModels` hook under `frontend/src/hooks`:
  - `const { data, isLoading } = useQuery(['ai-models'], () => aiApi.getModels(token))`.
  - Normalize the data into provider groups (`openai`, `gemini`, `remote`, `local`).
- Add `AiProviderContext` (React context) to store `selectedModelId`, defaulting to `response.default_model_id || current_model`.
- Persist the selection in `localStorage` or a backend preference endpoint.

### 2.2 AI Chat + Messaging
1. `frontend/src/components/sections/ChatSection.tsx`
   - Inject a dropdown (combobox) wired to `AiProviderContext` so users can switch models per chat session.
   - Display the resolved model from server responses (the API now returns `model`/`provider`).
2. `frontend/src/components/sections/AdminSection.tsx`
   - In the AI Clients panel, show models discovered for each node with "Copy Identifier" button (calls `navigator.clipboard.writeText('client:ID:model')`).
3. Conversation UI (`App.tsx` / `ChatSection`)
   - Update message rendering to show a chip like `AI • Mac Studio (llama3.1)` using `message.model_used`.

### 2.3 Task/Event/Note assistants
- For each assistant component (e.g., `AiTaskAssistant.tsx`, event analysis panel, note summary panel):
  - Add a "Model" selector (reuse the dropdown) and pass `modelId` to the corresponding API calls (`getTaskSuggestions`, `getEventAnalysis`, etc.).
  - Show the resolved model in the result card to confirm which provider handled it.

### 2.4 Controls & safety
- Add a global toggle in Settings → AI to disable cloud providers (set `preferredSources=['remote','openwebui']`). Store this preference and filter `/ai/models` data accordingly before presenting options.
- Provide a quick "Reset to Default" button that clears the stored model id and falls back to `default_model_id` from the API.

## 3. Messaging & Group Chat specifics
1. **Backend**: Ensure `/conversations/{id}/messages` includes `model_used` for AI entries (already added).
2. **Frontend**:
   - When composing a message inside a group chat with AI enabled, show which model will respond (same dropdown as AI Chat). Default to the conversation's last used model.
   - Offer per-message overrides (optional advanced control): a small button labeled "Route" that opens the model picker for that single prompt.
3. **Control**: Add a conversation-level setting (stored in DB) called `default_model_id`. Admins can edit it; UI should reflect it in the conversation details drawer.

## 4. iOS App Integration
1. **Models endpoint**
   - Update `AIProviderInfo` and `AIModelsResponse` structs (`ios/Cafe/Core/API/APIClient+AI.swift`) to align with backend schema (fields: `default_model_id`, `models[].id`, etc.).
   - Add a `fetchAiModels()` method using the same endpoint and cache results in `AppState.shared.aiModels`.
2. **Settings UI**
   - Create `AIModelPickerView` that groups models by provider/source and indicates device names (Mac Studio, Windows GPU, etc.).
   - Persist the selection in `UserSettings` (existing SwiftData/Realm store) and include it in AI requests.
3. **Chat & Assistants**
   - In `ChatView`, show the active model chip and allow tap-to-change.
   - For task/event/note suggestion screens, add a segmented control or sheet to choose the model before submitting.
4. **Messaging**
   - Display `message.model_used` inside conversation detail screens so mobile users see which worker produced each response.
5. **Controls**
   - Respect the “cloud disabled” preference by filtering models before presenting options.

## 5. Suggestion endpoints & automation
- Extend `/ai/tasks/suggest`, `/ai/events/analyze`, `/ai/notes/summarize`, `/ai/recipes/*`, `/ai/generate-tasks` to accept `model_id` in the payload. Default to the user’s selection when omitted.
- Update frontend/ios API helpers to send `model_id` when it differs from the default.
- Make sure backend logs record the identifier for every helper invocation for later cost analysis.

## 6. Testing checklist
1. **Unit tests**
   - Add FastAPI tests for `/ai/models` filtering (own node vs. public only).
   - Test chat endpoint with `model=openai:gpt-4o-mini` and `model=client:<id>:llama3.1` to ensure routing works.
2. **Manual QA**
   - Mac/Windows nodes online → verify they appear, select them in UI, send chat, confirm SSE header matches.
   - Toggle “cloud only” vs “remote only” in settings and ensure the picker updates immediately.
3. **Regression**
   - When no providers available, UI should fall back to mock entries with a call-to-action to configure providers.

## 7. Operational notes / "Easy to control"
- Use `docs/AI_ROUTING_ROADMAP.md` + this plan in tandem; update both after each milestone.
- Keep `.env` overrides documented in AGENTS.md (already has routing summary).
- Encourage agents to tag commits with `feat(ai-routing): …` for traceability.
