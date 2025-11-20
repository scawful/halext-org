# Halext / Zeniea / ALttPhacking Consolidation Plan

This roadmap documents how we bring every property on the server onto a common stack powered by the Halext Org API, including the new OpenWebUI/Ollama services.

## Phase 1 – Inventory & Health (Week 1)
- Catalogue every running component: Halext API/frontend, Zeniea PHP app, Acmlmboard, WordPress, planned OpenWebUI/Ollama, and MySQL/Postgres services. Note ports, config files, data volumes, and systemd units.
- Extend `scripts/setup-ubuntu.sh` with read-only checks so it reports Docker/container status, DB connectivity, nginx errors, and disk usage. Wire it to a cron mail for daily health snapshots.

## Phase 2 – Identity & Access (Weeks 1–2)
- Standardize on Halext accounts: expose OAuth/JWT validation so Zeniea and Acmlmboard can consume Halext tokens.
- Write migration scripts that map legacy `users` tables → Halext accounts, then gate new registrations through Halext only.
- Add `/integrations/openwebui/*` SSO flows to all first-party clients so AI features honor the same login state.

## Phase 3 – Data Hygiene & Backups (Weeks 2–3)
- Automate Postgres (`halext_org`) and MySQL (`social`, `acmlm`, `wordpress`) dumps to `/srv/backups/` plus off-site storage.
- Snapshot `/www/*` trees (rsync or git-archive) weekly so future PHP changes have a rollback path.
- Document restore drills and retention policies inside `docs/DEPLOYMENT.md`.

## Phase 4 – API Alignment & Content Bridges (Weeks 3–5)
- Build lightweight “adapter” modules so Zeniea/Acmlmboard call the Halext API for posts, notifications, and media uploads instead of raw SQL.
- Add read-only bridges (e.g., `GET /ai/context/zeniea`) so OpenWebUI/Halext clients can request curated snippets from other sites when crafting AI prompts.
- Ensure all AI traffic funnels through `AiGateway` so desktop/multi-platform helpers just upload context and receive replies—no per-device model installs.
- Stand up a “lite” admin surface for **alttphacking.net** that reuses Halext auth but only exposes ALTTP-specific controls (news, hacks, resources). Longer-term these admin actions should be POSTs against the Halext API so the same workflows are available from the Halext dashboard.

## Phase 5 – Deployment Modernization (Weeks 5–6)
- Finish the improved `scripts/server-deploy.sh` workflow now that caching is in place; integrate with CI so pushes to `main` trigger backend/frontend deploys automatically.
- Containerize remaining PHP apps or wrap them with supervised systemd/nginx units, ensuring logs land in a centralized location.
- Once containers are stable, define rollout runbooks (deploy order, verification steps, rollback checklists) in `docs/DEPLOYMENT.md`.

Completing these phases will leave us with a predictable stack where Halext serves as the single source of truth for identity, AI, and content. Zeniea, Acmlmboard, Cafe, and future desktop companions can all rely on the same API + OpenWebUI backend, and operations gain clear observability plus recovery stories.
