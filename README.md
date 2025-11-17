# Halext Org

Halext Org is a hybrid task/todo/calendar workspace with configurable “widget” layouts, AI-assisted chats, and multi-device access (web, Ubuntu server, iOS). The stack blends FastAPI, React/Vite, SwiftUI, and Nginx/systemd automation so everything from the macOS dev environment to the Ubuntu deployment stays in sync.

## Highlights

- **Configurable layouts** — Apple-style widget presets, drag-and-drop columns, OpenWebUI embeds.
- **Task labels & recurring events** — Color-coded chips and recurrence metadata across the API and UI.
- **AI chats** — Solo/group conversations with optional OpenWebUI/Ollama workers.
- **Shared access** — Invite-only registration guarded by a shared access code; login via OAuth2 tokens.
- **One-command deploys** — Scripts for server bootstrap (`server-init.sh`), updates (`server-deploy.sh`), and launchd helpers on macOS.
- **iOS scaffolding** — SwiftUI app stub with an API client for native dashboards and chats.

For setup guides, deployment recipes, and more details see `docs/SETUP_OVERVIEW.md`, `docs/DEPLOYMENT.md`, and `docs/PLANNING.md`.
