# Halext Org

Halext Org is a hybrid task/todo/calendar workspace with configurable “widget” layouts, AI-assisted chats, and multi-device access (web, Ubuntu server, iOS). The stack blends FastAPI, React/Vite, SwiftUI, and Nginx/systemd automation so everything from the macOS dev environment to the Ubuntu deployment stays in sync.

## Highlights

- **Configurable layouts** — Apple-style widget presets, drag-and-drop columns, OpenWebUI embeds.
- **Task labels & recurring events** — Color-coded chips and recurrence metadata across the API and UI.
- **AI chats** — Solo/group conversations with optional OpenWebUI/Ollama workers.
- **Shared access** — Invite-only registration guarded by a shared access code; login via OAuth2 tokens.
- **One-command deploys** — Scripts for server bootstrap (`server-init.sh`), updates (`server-deploy.sh`), and launchd helpers on macOS.
- **iOS scaffolding** — SwiftUI app stub with an API client for native dashboards and chats.

For setup guides, deployment recipes, and more details see `docs/dev/SETUP_OVERVIEW.md`, `docs/ops/DEPLOYMENT.md`, and `docs/dev/PLANNING.md`.

## Documentation

- [docs/README.md](docs/README.md) – master index linking every guide.
- **Development**: [LOCAL_DEVELOPMENT](docs/dev/LOCAL_DEVELOPMENT.md), [QUICKSTART](docs/dev/QUICKSTART.md), [ARCHITECTURE_OVERVIEW](docs/dev/ARCHITECTURE_OVERVIEW.md).
- **Operations**: [AGENTS runbook](docs/ops/AGENTS.md), [Deployment checklist](docs/ops/DEPLOYMENT_CHECKLIST.md), [Server field guide](docs/ops/SERVER_FIELD_GUIDE.md).
- **AI Infrastructure**: [AI architecture](docs/ai/AI_ARCHITECTURE.md), [Ollama setup](docs/ai/OLLAMA_SETUP.md), [OpenWebUI setup](docs/ai/OPENWEBUI_SETUP.md).
- **iOS**: [iOS README](ios/README.md), [iOS setup guide](ios/SETUP.md), [development plan](docs/ios/IOS_DEVELOPMENT_PLAN.md).
