# AI/Chat/Dashboard Regression Retro (2025-11-20)

## What was requested
- Fix AI chat so models load and messages flow; merge AI chat into Messages and replace the AI tab with an Agent management view.
- Make Messages work for real user-to-user communication (e.g., with user `magicalgirl`).
- Keep admin panel controls authoritative for AI models; sync those choices to Messages/AgentHub.
- Keep the dashboard customizable without regressions; original widgets and layout should remain, with presets/editing accessible via the 3-dot menu (no intrusive control strip).
- Maintain themes/background options.
- Ship runnable builds (iOS + backend) and be more comprehensive about backend deployment.

## What changed vs. desired
- **Dashboard regression (needs rollback/fix):** Replaced the classic widget dashboard with `ConfigurableDashboardView` and added a top control strip. Result: layout looks worse and widgets feel missing/empty. Presets/edit controls should live inside the 3-dot menu only, not inline.
- **Messaging/AI still broken:** Live messaging with other users and LLMs still not working end-to-end. Admin defaults not fully reflected in Messages/AgentHub, and the AI/Chat app replacement is incomplete.
- **Agent management:** Agent view exists but isnt fully integrated with chat flows; AI chat replacement inside Messages remains unreliable.

## Items completed (partial)
- Added backend endpoints: `/users/search` for user lookup, `/conversations/{id}` for conversation fetch, admin `/admin/ai/default-model` to set the default model, and persisted conversation `default_model_id`.
- iOS: AgentHub view added; Messages wired to conversation create with model fields; Codable fixes for conversations/messages; Release and AltStore builds pass.

## Items not completed / still failing
- Reliable live messaging between users (including `magicalgirl`) still not verified or functional.
- AI chat does not reliably load models or reply; backend/LLM routing may be misaligned with deployed services.
- Admin AI controls are not consistently synced to Messages/Agent flows in production.
- Dashboard UX regressed: original widget layout replaced and top preset strip is unwanted.

## How to restore the dashboard (plan)
1) Revert Dashboard top control strip and inline edit bar; keep presets/edit/customize in the existing 3-dot menu.
2) Restore the previous widget-based layout (the classic `DashboardView` stack) or limit `ConfigurableDashboardView` to the 3-dot Edit flow only.
3) Ensure layout defaults load with the original cards; remove the forced empty-state UI that hides widgets.

## How to fix messaging/AI (plan)
1) Backend:
   - Verify `/ai/models` and provider credentials on the deployed server; align `default_model_id` with a working model.
   - Ensure `/conversations` responses include participant details/last_message and that message posting routes talk to a live LLM backend.
   - Add/verify `/users/search` and conversation/message endpoints on the deployed instance.
2) iOS:
   - Point Messages/AgentHub to the working base URL with auth; ensure bearer/access-code headers are present.
   - Test DM with `magicalgirl` and AI thread creation from AgentHub; fix any payload/decoding mismatches.
3) Admin panel:
   - Hook the admin default-model setter to the same endpoint (`/admin/ai/default-model`) and feed that into Messages/AgentHub model selection.

## Next actions (must-do)
- Roll back the dashboard to the prior widget UI and confine presets/editing to the 3-dot menu.
- Verify and repair live messaging + AI chat end-to-end with real users and LLMs before next deploy.
- Retest admin model control syncing to Messages/AgentHub; document a deploy checklist and run it.

This regression needs resolution: restore the dashboard experience and make user + LLM messaging actually work as requested.
