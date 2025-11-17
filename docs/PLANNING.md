# Halext Org Project: Planning & Architecture

This document outlines the vision, architecture, and implementation plan for the Halext Org project, a multi-platform productivity suite with deep AI integration, based on Org Mode principles.

## 1. Core Vision

The goal is to create a powerful, centralized system for managing personal and shared productivity (todos, calendar, notes) that combines the power of Org Mode with modern, accessible interfaces (Web, iOS, macOS) and intelligent AI assistance. The system should be useful for both technical and lifestyle management.

## 2. System Architecture

The project will be built on a client-server architecture, ensuring data is centralized and accessible from any device.

### 2.1. Backend Server

This is the heart of the system. It will be responsible for data storage, business logic, and providing an API for all clients.

- **Technology:** Python with the **FastAPI** framework. It's modern, fast, and excellent for building robust APIs.
- **Database:** **PostgreSQL**. A powerful, open-source relational database that can handle the structured data of tasks, events, and notes effectively.
- **Data Model:** While inspired by Org Mode, data will be stored in structured database tables (e.g., `tasks`, `events`, `notes`, `tags`) rather than raw `.org` files. This is crucial for performance, querying, and multi-user access.
- **Org Parser:** A utility will be built to parse `.org` files, allowing for data import from an existing Emacs setup.
- **Core API:** A comprehensive RESTful API will be designed to allow clients to perform full CRUD (Create, Read, Update, Delete) operations on all data.
- **AI Integration API:** A dedicated API endpoint will expose sanitized and context-rich data to an external AI system like **OpenWebUI**. This allows the AI to help with tasks like "summarize my priorities" or "find a time for a meeting next week."

### 2.2. Web Application

The primary user interface, accessible from any modern browser.

- **Technology:** **React** or **Vue.js**. A modern JavaScript framework will be used to build a dynamic and responsive single-page application (SPA).
- **Key Features:**
    - **Dashboard:** A main view showing an agenda, upcoming events, and high-priority tasks.
    - **Configurable Layout:** A "tiling window" or "child window" interface allowing users to create and arrange different views (e.g., a todo list next to a calendar).
    - **Org-Style Editing:** A rich text editor that mimics Org Mode features like folding, headlines, and easy date manipulation.
    - **Full Interactivity:** Drag-and-drop tasks, resize windows, and create custom views.

### 2.3. Native Applications (iOS & macOS)

Native apps will provide the best user experience and integration on Apple devices.

- **Technology:** **Swift** and **SwiftUI**. This allows for a modern, declarative UI and code sharing between the iOS and macOS apps.
- **Functionality:** The native apps will be full-featured clients, not just simple viewers. They will consume the same backend API as the web application.
- **Offline Support:** A local cache (e.g., using Core Data or SwiftData) will be implemented to allow for offline use, with data syncing when a connection is available.

### 2.4. Cloud Deployment & Infrastructure

To ensure the infrastructure is "top-notch" and ready for production on a domain like `halext.org`, the following approach will be taken for deployment on a standard Ubuntu server:

- **Application Server:** The FastAPI application will be run using **Gunicorn**, a production-ready Python WSGI HTTP server. It's robust, fast, and configurable.
- **Reverse Proxy:** **Nginx** will be used as a reverse proxy. It will sit in front of the Gunicorn server and handle all incoming HTTP/S traffic. Its responsibilities will include:
    - Terminating SSL (HTTPS) connections.
    - Forwarding requests to the Gunicorn server.
    - Serving static files directly for better performance.
- **Process Management:** A **systemd** service file will be created to manage the Gunicorn process. This ensures the backend application automatically starts on boot, restarts if it crashes, and can be managed with standard system commands (e.g., `sudo systemctl start halext-org`).
- **Containerization:** The entire stack (FastAPI, Gunicorn, Nginx) can be containerized using **Docker** and `docker-compose`. This simplifies deployment and ensures a consistent environment. For an initial deployment on your Ubuntu server, a direct installation of Nginx/Gunicorn with systemd is also a very solid and common approach.
- **Database:** The PostgreSQL database can be run on the same server for simplicity or on a separate, managed database service for better scalability and reliability.

### 2.5. Distributed AI Workers

To leverage the power of multiple machines (e.g., a MacBook and a powerful Windows gaming PC), a distributed AI worker system will be implemented.

- **Task Queue:** A robust task queue system like **Celery** with a **Redis** or **RabbitMQ** message broker will be added to the backend.
- **AI Worker Clients:** Separate client applications (or modes within the main clients) will be developed for macOS and Windows. These clients will:
    1.  Register themselves with the backend as available "AI workers".
    2.  Poll the task queue for new AI jobs (e.g., "summarize this text," "categorize these tasks").
    3.  Execute the job using a local LLM instance (like Ollama).
    4.  Post the results back to the backend server.
- **Central Coordination:** The main backend server will be responsible for adding jobs to the queue and receiving the results. It will not perform heavy AI processing itself, allowing it to remain lightweight. This architecture enables massive, scalable, and distributed AI processing.

## 3. Phased Implementation Plan

This is a large project that must be built incrementally.

### Phase 1: Backend Foundation (The Core)

**Goal:** Create a functional, API-driven backend that can serve as the foundation for all clients.

1.  **Setup:** Initialize a new FastAPI project with PostgreSQL.
2.  **Models:** Define the core database models for `Tasks`, `Events`, and `Users`.
3.  **API V1:** Build the initial REST API endpoints for user authentication and basic CRUD operations on tasks.
4.  **Parser:** Develop a basic `.org` file parser to handle importing tasks from an existing file.
5.  **Deployment:** Containerize the backend with Docker and set up a basic deployment.

### Phase 2: Web Application (The First Client)

**Goal:** Build a usable web interface for managing tasks.

1.  **Setup:** Initialize a new React or Vue project.
2.  **Authentication:** Implement user login and registration against the backend API.
3.  **Task View:** Create a component to list, create, edit, and delete tasks.
4.  **Basic Dashboard:** Build a simple dashboard to display today's tasks.

### Phase 3: Expanding Features

**Goal:** Add calendar functionality and enhance the UI.

1.  **Backend:** Add `Event` models and API endpoints to the backend.
2.  **Web App:**
    - Implement a full calendar view.
    - Begin work on the configurable "child window" layout.
3.  **Native Apps:** Begin development of the iOS and macOS apps, starting with authentication and task viewing.

### Phase 4: AI & Advanced Integrations

**Goal:** Integrate intelligent features and external services.

1.  **Backend:** Develop the secure API endpoint to expose data to OpenWebUI.
2.  **AI Workflows:** Create example scripts and prompts for using the AI to analyze and manage the org data.
3.  **Notifications:** Implement email or push notifications for reminders.

---

This phased approach ensures that we build a solid foundation first and deliver value at each stage of development.

## 4. Latest Implementation Notes

- **Dynamic layouts:** Users can now create configurable pages that store column/widget layouts for todos, events, notes, gift lists (kept private unless explicitly shared), and OpenWebUI embeds.
- **Sharing controls:** Each page has a `visibility` flag and a share table so private lists (such as gift planning) remain hidden unless a partner is added with view or edit rights.
- **AI conversations:** The backend exposes `/conversations` APIs that manage solo/group chats with optional AI participation. An extensible `AiGateway` currently supports OpenWebUI, Ollama, or a mock responder.
- **OpenWebUI discovery:** `/integrations/openwebui` advertises whether a local OpenWebUI endpoint is running so the web/iOS apps can embed the interface inline.
- **Task labels & presets:** Tasks support multi-label chips, events can repeat, and layout presets inspired by Apple widgets can be applied from the web UI or mobile clients.

## 5. Local Automation with launchd

Two launch agents make it easy to run the stack on macOS:

1. **Backend:** `org.halext.api.plist` (already configured) runs Uvicorn inside `backend/env`.
2. **Frontend:** `org.halext.frontend.plist` starts `npm run dev -- --host 127.0.0.1 --port 4173` from the `frontend` directory with `VITE_API_BASE_URL` pointing to the FastAPI server.

### Installation

```bash
mkdir -p ~/Library/LaunchAgents
cp /Users/scawful/Code/halext-org/org.halext.api.plist ~/Library/LaunchAgents/
cp /Users/scawful/Code/halext-org/org.halext.frontend.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/org.halext.api.plist
launchctl load -w ~/Library/LaunchAgents/org.halext.frontend.plist
```

The frontend agent logs to `halext-org/frontend.log` and the backend continues to log to `service.log`. Stop services with `launchctl unload -w <plist>`.

> **Heads-up:** Vite 7 requires Node.js 20.19+ (or 22.12+). Upgrade Node on macOS (e.g., via `fnm` or `nvm`) if you plan to run the frontend build locally outside of launchd.
