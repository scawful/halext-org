# Halext Org Frontend

This React + TypeScript + Vite application is the primary web interface for the Halext Org suite. It provides:

- OAuth2 token login/registration against the FastAPI backend.
- Task & calendar capture with inline creation forms.
- Configurable pages where you can place task lists, events, notes, private gift lists, and OpenWebUI if it is available.
- Conversation management for solo, partner, or group chats with optional AI participation backed by OpenWebUI/Ollama.

## Prerequisites

- Node.js **20.19+** (Vite 7 enforces this; use `fnm`, `nvm`, or Homebrew).
- npm 10+
- A running backend (default: `http://127.0.0.1:8000`).

## Environment

The frontend reads `VITE_API_BASE_URL`. `launchd` users can rely on `org.halext.frontend.plist`, but for manual dev sessions export it yourself:

```bash
export VITE_API_BASE_URL="http://127.0.0.1:8000"
```

## Local Development

```bash
cd frontend
npm install
npm run dev -- --host 127.0.0.1 --port 4173
```

Open http://127.0.0.1:4173/ in a browser (or via the macOS/iOS wrapper app once implemented).

## Production Build

```bash
npm run build
npm run preview    # optional smoke test of static output
```

Artifacts land in `dist/` and can be served by any static host or proxied through Nginx.
