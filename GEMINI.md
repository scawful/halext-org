# Gemini Context: Halext Org

This `GEMINI.md` file provides essential context for the Halext Org project, a hybrid task/calendar workspace with AI integration.

## Project Overview

**Halext Org** is a full-stack application designed for personal organization and team collaboration.
*   **Core:** Hybrid task/todo/calendar workspace with configurable widgets.
*   **AI:** Deep integration with OpenWebUI and Ollama for AI-assisted chats and features.
*   **Platform:**
    *   **Backend:** Python (FastAPI, SQLAlchemy, Postgres/SQLite).
    *   **Frontend:** React (Vite, TypeScript, Tailwind).
    *   **Mobile:** iOS (SwiftUI) native app.
    *   **Infrastructure:** Ubuntu VPS (Nginx, systemd) + macOS Dev Environment.

## Quick Start (Development)

The project includes convenience scripts for rapid local development.

```bash
# Start Backend & Frontend with Hot-Reload
./dev-reload.sh

# Check Service Status
./dev-status.sh

# Stop All Services
./dev-stop.sh
```

**Access Points:**
*   **Frontend:** `http://localhost:5173`
*   **Backend API:** `http://127.0.0.1:8000`
*   **API Docs:** `http://127.0.0.1:8000/docs`

## Project Structure

*   **`backend/`**: FastAPI application.
    *   `app/`: Core logic (routes, models, CRUD).
    *   `migrations/`: Alembic database migrations.
    *   `tests/`: Pytest suite (`pytest`).
    *   `main.py`: App entry point.
*   **`frontend/`**: React SPA.
    *   `src/`: Components, hooks, and views.
    *   `vite.config.ts`: Build configuration.
*   **`ios/`**: Native iOS companion app (`Cafe.xcodeproj`).
    *   Built with SwiftUI.
    *   Connects to the same backend API.
*   **`scripts/`**: Extensive automation library.
    *   **Deploy:** `server-deploy.sh`, `deploy-frontend-fast.sh`.
    *   **Setup:** `setup-ubuntu.sh`, `setup-openwebui.sh`.
    *   **Ops:** `site-health-check.sh`, `emergency-kill-ollama.sh`.
*   **`docs/`**: Comprehensive documentation.
    *   **Start Here:** `docs/README.md` (Master Index).
    *   **Dev Guidelines:** `docs/dev/GEMINI.md`.

## Key Commands & Workflows

### Backend
*   **Install Deps:** `pip install -r backend/requirements.txt`
*   **Run Tests:** `cd backend && pytest`
*   **Run Server (Manual):** `uvicorn backend.main:app --reload`

### Frontend
*   **Install Deps:** `cd frontend && npm install`
*   **Dev Server:** `npm run dev`
*   **Build:** `npm run build`

### iOS
*   **Open Project:** `open ios/Cafe.xcodeproj`
*   **See Guide:** `ios/README.md` for setup and deployment details.

### Deployment (Ubuntu)
*   **Full Sync:** `ssh user@server 'bash -s' < scripts/server-sync.sh`
*   **OpenWebUI Setup:** See `scripts/setup-openwebui.sh`.

## Coding Conventions
*   **Python:** PEP 8, formatted with Black.
*   **TypeScript:** ESLint + Prettier.
*   **Commits:** Conventional Commits (`feat:`, `fix:`, `chore:`).
*   **Branching:** Feature branches preferred.

## Related Documentation
*   **AI Architecture:** `docs/ai/AI_ARCHITECTURE.md`
*   **Deployment Guide:** `docs/ops/DEPLOYMENT.md`
*   **Troubleshooting:** `README-DEV.md`
