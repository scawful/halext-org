# Handoff: iOS Messaging / AI Sync & Testing

**Context:** iOS messaging + AI surfacing landed (ConversationStore, badges, AgentHub provider info). Release + AltStore build now succeeds (`ios/build/Cafe.ipa`). Backend pytest currently fails due to missing auth fixtures and AI gateway timeouts.

## Current State
- iOS build: `./build-for-altstore.sh` succeeds; unsigned IPA at `ios/build/Cafe.ipa` (Release, no codesign).
- Messaging UI: Conversations now show AI/model badges and use shared store/view models.
- Tests: `scripts/agents/run-tests.sh` (pytest) fails — missing fixtures `admin_user_token`/`user_token`; AI gateway timeouts; model discovery tests expect tokens and live/mocked routes.

## What’s Broken
- Backend tests cannot locate auth fixtures for admin/user tokens (see `tests/test_model_discovery.py`).
- AI routing/model discovery tests rely on live AI gateway; time out locally.
- No recorded/mocked responses for `/ai/models` and `/ai/chat` flows.

## Next Actions (Backend/Testing)
1) Add token fixtures in `backend/tests/conftest.py` (or module-level) for `admin_user_token` and `user_token`; reuse `admin_auth_headers`/`auth_headers` to generate tokens or stub JWTs.
2) Mock AI gateway in `tests/test_ai_models_endpoint.py`, `tests/test_ai_chat_routing.py`, `tests/test_ai_routing_integration.py`:
   - Patch `ai_gateway.get_models` and `ai_gateway.generate_reply` to return deterministic data.
   - Avoid network by mocking `httpx.AsyncClient` in model discovery endpoints.
3) Fix `TestBackwardCompatibility::test_existing_conversation_flow`: `crud.create_conversation` currently receives an int; pass `ConversationCreate` payload instead.
4) Add a smoke test runner that skips external AI when `AI_OFFLINE=1`; adapt `scripts/agents/run-tests.sh` to pass `-k "not integration"` when offline.

## Next Actions (iOS)
- Verify messaging against a live backend with valid bearer + access code; ensure AI replies populate `lastMessage` and badges.
- Keep `Conversation` Equatable if needed for `onChange` bindings; adjust if backend payload shape changes.

## How to Reproduce
```bash
# iOS build
cd ios && ./build-for-altstore.sh
# Backend tests (currently failing)
./scripts/agents/run-tests.sh
```

## Artifacts
- Unsigned IPA: `ios/build/Cafe.ipa`
- Build logs: `ios/build/DerivedData/Build/Products/Release-iphoneos/`
