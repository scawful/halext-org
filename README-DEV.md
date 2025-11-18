# Halext Org - Development Guide for macOS

## Quick Start

### Start Development Environment
```bash
./dev-reload.sh
```
This will start both the frontend (port 5173) and backend (port 8000) servers with hot-reload enabled.

### Check Server Status
```bash
./dev-status.sh
```
Shows the current status of all development servers, logs, and dependencies.

### Stop All Servers
```bash
./dev-stop.sh
```
Safely stops all running development servers.

---

## Automated Sync (macOS)

Use the bundled helper to refresh dependencies and restart services with one command:

```bash
./scripts/macos-sync.sh            # auto-detects launchd vs dev scripts
./scripts/macos-sync.sh --mode dev # force dev-reload workflow
./scripts/macos-sync.sh --server-sync --remote-server halext@org.halext.org
```

The script:
- verifies Python/Node requirements, reinstalling when hashes change,
- ensures `backend/env` and `frontend/node_modules` exist,
- reloads the launchd agents (`org.halext.api` / `org.halext.frontend`) or runs the dev scripts,
- probes `http://127.0.0.1:8000/docs` and the frontend port (5173 for dev scripts, 4173 for launchd) so you know everything is up.

When `--server-sync` is supplied (or `HALX_REMOTE_SERVER` is set in `scripts/macos-sync.env`), the script will SSH into the Ubuntu host and run `scripts/server-sync.sh`, giving you one command to refresh both sides. Customize SSH options, remote repo path, or env overrides in `scripts/macos-sync.env`.

---

## Access Points

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:5173 | React + Vite development server |
| **Backend API** | http://127.0.0.1:8000 | FastAPI server |
| **API Docs** | http://127.0.0.1:8000/docs | Interactive API documentation |

---

## Development Scripts

### `dev-reload.sh`
**Full development environment startup**

- Checks for and kills existing processes on ports 5173 and 8000
- Verifies virtual environment and node_modules exist
- Starts backend with uvicorn (auto-reload enabled)
- Starts frontend with Vite (auto-reload enabled)
- Displays service URLs and PIDs
- Handles graceful shutdown on Ctrl+C

**Logs:**
- Frontend: `frontend-dev.log`
- Backend: `backend-dev.log`

### `dev-stop.sh`
**Stop all development servers**

- Kills processes on ports 5173 and 8000
- Stops any remaining uvicorn/vite processes
- Safe to run even if servers aren't running

### `dev-status.sh`
**Check development environment status**

- Backend server status and health
- Frontend server status and health
- Log file locations and sizes
- Database status (SQLite)
- Virtual environment info
- Node modules status

---

## Manual Development

If you prefer to run servers manually:

### Backend
```bash
cd backend
source env/bin/activate  # or env/bin/activate on macOS
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

### Frontend
```bash
cd frontend
npm run dev
```

---

## Shipping Frontend Builds from macOS

When the Ubuntu box is low on CPU, build locally and push only the static assets:

```bash
cp scripts/frontend-deploy.env.example scripts/frontend-deploy.env  # first time only
./scripts/deploy-frontend-local.sh
```

The helper caches `node_modules` until `package-lock.json` changes, runs `npm run build`, rsyncs `frontend/dist/` to the configured `/var/www` path, and can reload Nginx or other services via the optional `HALX_POST_DEPLOY` command. Use `--dry-run` to preview the rsync changes.

---

## Environment Setup

### First Time Setup

1. **Backend Dependencies**
   ```bash
   cd backend
   python3 -m venv env
   source env/bin/activate
   pip install -r requirements.txt
   ```

2. **Frontend Dependencies**
   ```bash
   cd frontend
   npm install
   ```

3. **Database**
   - SQLite database will be created automatically at `backend/halext_dev.db`
   - For PostgreSQL in production, set `DATABASE_URL` environment variable

---

## Configuration

### Backend (FastAPI)

**Database:**
- Default: SQLite (`sqlite:///./halext_dev.db`)
- Production: Set `DATABASE_URL` environment variable

**AI Gateway:**
- Default: Mock responses
- OpenWebUI: Set `AI_PROVIDER=openwebui`, `OPENWEBUI_URL` (internal service), and `OPENWEBUI_PUBLIC_URL` (the public `/webui/` path)
- Ollama: Set `AI_PROVIDER=ollama` and `OLLAMA_URL`
- Model: Set `AI_MODEL` (default: `llama3.1`)
- Full OpenWebUI provisioning, env variables, and SSO details live in [`docs/OPENWEBUI_SETUP.md`](docs/OPENWEBUI_SETUP.md)

### Frontend (Vite)

**API Base URL:**
- Default: `http://127.0.0.1:8000`
- Override: Set `VITE_API_BASE_URL` in `.env` file

---

## Deployment

See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for full server setup and deployment instructions.

**Quick Frontend Deploy (macOS → Server):**
1. Configure `scripts/frontend-deploy.env` (copy from `.example`)
2. Run:
   ```bash
   ./scripts/deploy-frontend-local.sh
   ```

---

## Server Alignment Roadmap

Working across Halext, Zeniea, AlttPHacking, and OpenWebUI? The multi-phase consolidation strategy (inventory, identity, backups, adapters, deployments) is tracked in [`docs/SERVER_ALIGNMENT_PLAN.md`](docs/SERVER_ALIGNMENT_PLAN.md).

---

## Troubleshooting

### Port Already in Use
```bash
# Check what's using the port
lsof -i :8000
lsof -i :5173

# Kill the process
./dev-stop.sh
```

### Virtual Environment Issues
```bash
cd backend
rm -rf env
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
```

### Database Issues
```bash
# Reset database
rm backend/halext_dev.db
# Restart backend - it will recreate the database
./dev-reload.sh
```

### Frontend Build Issues
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
npm run build  # Test build
```

---

## Project Structure

```
halext-org/
├── backend/
│   ├── app/
│   │   ├── models.py          # SQLAlchemy models
│   │   ├── schemas.py         # Pydantic schemas
│   │   ├── database.py        # Database config
│   │   ├── crud.py            # Database operations
│   │   ├── auth.py            # Authentication
│   │   └── ai.py              # AI Gateway
│   ├── env/                   # Virtual environment
│   ├── main.py                # FastAPI app
│   ├── requirements.txt       # Python dependencies
│   └── halext_dev.db          # SQLite database
│
├── frontend/
│   ├── src/
│   │   ├── components/        # React components
│   │   │   ├── layout/        # MenuBar, Sidebar, Dashboard
│   │   │   ├── widgets/       # Draggable widgets
│   │   │   └── sections/      # ImageGen, Anime, Calendar, IoT
│   │   ├── types/             # TypeScript types
│   │   ├── utils/             # Helper functions
│   │   ├── App.tsx            # Main app component
│   │   └── App.css            # Global styles
│   ├── node_modules/          # NPM dependencies
│   ├── package.json           # NPM config
│   └── vite.config.ts         # Vite config
│
├── dev-reload.sh              # Start dev environment
├── dev-stop.sh                # Stop all servers
├── dev-status.sh              # Check server status
├── scripts/                   # Deployment & utility scripts
└── README-DEV.md              # This file
```

---

## Git Workflow

### Before Committing
```bash
# Frontend
cd frontend
npm run build  # Ensure it builds

# Backend
cd backend
source env/bin/activate
python -m pytest  # If tests exist
```

### Commit Messages
Use conventional commits format:
```
feat: Add new anime section
fix: Resolve database connection issue
docs: Update development guide
refactor: Modularize App.tsx components
```

---

## Features

### Implemented
- ✅ User authentication (OAuth2)
- ✅ Task management with labels
- ✅ Event management with recurrence
- ✅ Customizable dashboard pages
- ✅ Drag-and-drop widgets
- ✅ AI chat integration (OpenWebUI/Ollama)
- ✅ Layout presets
- ✅ Page sharing

### New Sections
- ✅ Image Generation (UI ready)
- ✅ Anime Girls Collection (UI ready)
- ✅ Calendar View
- ✅ IoT & Devices (UI ready)

### In Progress
- 🔄 Image generation API integration
- 🔄 Anime character upload/management
- 🔄 IoT device monitoring
- 🔄 Real-time updates (WebSocket)

---

## Tech Stack

### Frontend
- **Framework:** React 19.2.0
- **Build Tool:** Vite 7.2.2
- **Language:** TypeScript 5.9.3
- **Drag & Drop:** @dnd-kit
- **Icons:** react-icons
- **Styling:** CSS with custom properties

### Backend
- **Framework:** FastAPI
- **Server:** Uvicorn
- **Database:** SQLAlchemy (SQLite/PostgreSQL)
- **Auth:** OAuth2 with JWT
- **AI:** OpenWebUI/Ollama integration
- **Language:** Python 3.14

---

## Support

For issues or questions:
1. Check `dev-status.sh` output
2. Review log files (`backend-dev.log`, `frontend-dev.log`)
3. Check GitHub issues
4. Contact team

---

**Happy Coding! 🚀**
