# iOS Backend API Support

This note documents the server endpoints that the current iOS app expects and how they behave on the backend after the latest changes.

## Collaboration + Presence
- `POST /users/me/presence` — Upsert your presence (`is_online`, `current_activity`, `status_message`); stores `last_seen`. Response returns the stored presence.
- `GET /users/{username}/presence` — Fetch stored presence for a user; falls back to `is_online=true` with a current timestamp if no record exists.
- `GET /events/shared` — List events shared with the current user. Returns `shared_with` usernames.
- `POST /events/` — Create an event; accepts `shared_with: [username]` to invite/share.
- `PUT /events/{id}/share` — Owner updates `shared_with` list. 400 if any usernames are unknown.
- `POST /messages/quick` — Body `{username, content, model?}`. Reuses or creates a 1:1 conversation, adds the message, and returns the created message.

## Memories + Goals
- `GET /memories?shared_with=username` — Memories owned by or shared with the caller (optional filter for a specific share target).
- `POST /memories` — Create memory with `shared_with`.
- `PUT /memories/{id}` — Update fields and optionally `shared_with`. Owner-only.
- `DELETE /memories/{id}` — Remove memory. Owner-only.
- `GET /goals?shared_with=username` — Goals owned by or shared with the caller (milestones included).
- `POST /goals` — Create goal with `shared_with`.
- `PUT /goals/{id}/progress` — Update progress (0–1). Owner-only.
- `POST /goals/{id}/milestones` — Add milestone to a goal. Owner-only.

## Admin aliases (for iOS Admin views)
- `GET /admin/stats` — Alias of `/admin/server/stats` (CPU/mem/disk/db/AI availability).
- `GET /admin/health` — Simple health summary (status + db + system stats).
- `POST /admin/rebuild-frontend` — Alias to existing frontend rebuild stub.
- `POST /admin/rebuild-indexes` — Placeholder; returns accepted message.

## Finance (Plaid placeholders)
- `POST /finance/plaid/link-token` — Returns a mock `link_token` and `expiration` so Link flows don’t 404.
- `POST /finance/plaid/exchange-token` — Accepts `public_token`, returns `"linked"` status (no real Plaid exchange).

## Data model updates
- New tables: `event_shares`, `user_presences`, `memories`, `memory_shares`, `goals`, `goal_shares`, `milestones`.
- Existing models updated to expose `shared_with` for events and to persist presence. FastAPI autoload creates these tables on service restart (already restarted).
