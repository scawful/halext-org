# Admin UX & Roadmap

## Immediate actions
- **iOS app update:** Add support for the new Admin → AI & Cloud credential flow and the customizable admin menu. Fix the iCloudKit-backed social features that currently crash the dashboard; ship a hotfix release before exposing new admin controls. Ensure the AI model list honors the cloud key state and prefers OpenAI/Gemini when present.
- **OpenWebUI safety:** Keep `OPENWEBUI_SYNC_ENABLED` off unless configured; when enabled, ensure the service is behind the Nginx proxy/TLS and that admin credentials are rotated. SSO endpoints now hard-require sync to be enabled.
- **Backend reload:** Restart `halext-api` after backend changes so OpenWebUI guards and cloud-key loading take effect.

## UX goals (web)
- Keep the admin nav responsive and optional: mobile users toggle modules on/off in the menu editor; themes and density are user-specific.
- AI & Cloud: one panel to store OpenAI/Gemini keys, set default models, and view masked status.
- Post/media management: inline status, quick filters, and batch actions (publish/unpublish, delete).
- Server view: surface service health (halext-api, nginx, postgres, openwebui), git revision, and resource gauges.

## Security hardening
- Prefer cloud providers for AI load; keep `API_KEY_ENCRYPTION_KEY` set in `.env`.
- Lock OpenWebUI behind the reverse proxy and systemd; disable direct port 3000 Internet exposure.
- Enforce admin-only access to `/admin/*` and OpenWebUI sync/SSO routes; rotate invite/access codes when rotating API keys.

## Roadmap
1) **iOS catch-up:** Ship the iCloudKit crash fix and wire the new AI model list + credential state into the app settings. Add a dev toggle to disable cloud providers if needed.
2) **Content tooling:** Batch publish/unpublish for blog/posts, asset tagging, and search. Add “recent errors” for image uploads and markdown parsing.
3) **AI routing telemetry:** Show last 10 AI requests, model, latency, and failure reason. Add a “drain to cloud” switch to temporarily disable local Ollama/OpenWebUI.
4) **OpenWebUI sync audit:** Log who requested SSO links and last sync time; add a force-resync button per user.
5) **Mobile admin polish:** Collapse cards into accordions on small screens; persistent quick actions for “Restart API/Restart OpenWebUI/Flush cache”.
6) **Backups & rollback:** One-click DB snapshot trigger and OpenWebUI data backup/restore helpers in the admin panel.

Document owners: update this file whenever admin UX, AI routing, or iOS capabilities change.***
