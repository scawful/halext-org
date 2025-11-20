# Gemini Development Guidelines for Halext Org

This document outlines the established coding conventions, architectural patterns, and best practices for the Halext Org project. Adhering to these guidelines will ensure consistency and maintainability.

## 1. Project Overview

Halext Org is a hybrid task/todo/calendar workspace with configurable “widget” layouts, AI-assisted chats, and multi-device access (web, Ubuntu server, iOS).

### 1.1. Architecture

- **Backend:** A [FastAPI](https://fastapi.tiangolo.com/) application serves the core API. It handles business logic, database interactions, and AI model integration.
- **Frontend:** A [React](https://react.dev/) single-page application built with [Vite](https://vitejs.dev/) provides the user interface.
- **iOS:** A native [SwiftUI](https://developer.apple.com/xcode/swiftui/) application provides a mobile interface to the Halext Org API.
- **Database:** The application uses [SQLAlchemy](https://www.sqlalchemy.org/) to interact with a [SQLite](https://www.sqlite.org/index.html) database in development and is configured to use [PostgreSQL](https://www.postgresql.org/) in production.
- **AI Integration:** The backend can connect to AI models through [OpenWebUI](https://openwebui.com/) or directly to [Ollama](https://ollama.ai/) instances.

### 1.2. Key Directories

- `backend/`: The FastAPI application.
- `frontend/`: The React/Vite web application.
- `ios/`: The SwiftUI mobile application.
- `docs/`: Project documentation.
- `scripts/`: Deployment and utility scripts.
- `infra/`: Infrastructure configuration (Nginx, systemd).

## 2. Development Workflow

### 2.1. Initial Setup

1.  **Backend:**
    ```bash
    cd backend
    python3 -m venv env
    source env/bin/activate
    pip install -r requirements.txt
    ```

2.  **Frontend:**
    ```bash
    cd frontend
    npm install
    ```

### 2.2. Running the Development Environment

The easiest way to run the full development environment is to use the provided scripts from the project root:

-   **Start/Reload:**
    ```bash
    ./dev-reload.sh
    ```
    This script starts both the backend and frontend with hot-reloading enabled.

-   **Check Status:**
    ```bash
    ./dev-status.sh
    ```

-   **Stop Servers:**
    ```bash
    ./dev-stop.sh
    ```

### 2.3. Access Points

-   **Frontend:** `http://localhost:5173`
-   **Backend API:** `http://127.0.0.1:8000`
-   **API Docs (Swagger):** `http://127.0.0.1:8000/docs`

## 3. Coding Conventions

### 3.1. Git Workflow

-   **Branching:** Use feature branches for all new work (e.g., `feat/add-new-widget`, `fix/login-bug`).
-   **Commit Messages:** Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification.
    -   `feat:` for new features.
    -   `fix:` for bug fixes.
    -   `docs:` for documentation changes.
    -   `refactor:` for code changes that neither fix a bug nor add a feature.
    -   `chore:` for build process or auxiliary tool changes.

### 3.2. Pre-Commit Checks

Before committing, ensure the applications build successfully:

-   **Frontend:**
    ```bash
    cd frontend
    npm run build
    ```
-   **Backend (if tests are present):**
    ```bash
    cd backend
    source env/bin/activate
    python -m pytest
    ```

### 3.3. Style and Formatting

-   **Python (Backend):** Adhere to [PEP 8](https://www.python.org/dev/peps/pep-0008/). Use an autoformatter like [Black](https://github.com/psf/black).
-   **TypeScript/React (Frontend):** Follow the conventions defined in the project's ESLint configuration (`frontend/eslint.config.js`). Use a formatter like [Prettier](https://prettier.io/).

## 4. Configuration

### 4.1. Backend

-   **Database:** Configured via the `DATABASE_URL` environment variable. Defaults to a local SQLite file (`backend/halext_dev.db`).
-   **AI Provider:** Set the `AI_PROVIDER`, `OPENWEBUI_URL` or `OLLAMA_URL`, and `AI_MODEL` environment variables to connect to a live AI backend. See `docs/OPENWEBUI_SETUP.md` for details.

### 4.2. Frontend

-   **API URL:** The backend API URL can be overridden by setting the `VITE_API_BASE_URL` in a `.env` file in the `frontend` directory.

## 5. Troubleshooting

Common issues and their resolutions are documented in the `README-DEV.md` file, including:
-   "Port already in use" errors.
-   Virtual environment issues.
-   Database reset procedures.
-   Frontend build failures.
