from fastapi import FastAPI, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
import platform
from datetime import datetime

from app import models, crud
from app.database import engine, SessionLocal
from app.dependencies import get_db, ai_gateway, ENV_CHECK
from app.websockets import manager

# Import original routers (to be refactored later)
from app.admin_routes import router as admin_router
from app.ai_routes import router as ai_router_legacy  # Image gen
from app.content_routes import router as content_router

# Import new modular routers
from app.routers import (
    users,
    tasks,
    events,
    pages,
    conversations,
    finance,
    social,
    ai,
    integrations
)

models.Base.metadata.create_all(bind=engine)

VERSION = "0.2.0-refactored"

app = FastAPI(
    title="Halext Org API",
    description="The backend API for the Halext Org productivity suite.",
    version=VERSION,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
# Note: admin_router already has /admin prefix defined in the router itself
# We add /api prefix here so it becomes /api/admin/*
for prefix in ("/api", ""):
    app.include_router(admin_router, prefix=prefix)
    app.include_router(content_router, prefix=prefix)
    app.include_router(users.router, prefix=prefix)
    app.include_router(tasks.router, prefix=prefix)
    app.include_router(events.router, prefix=prefix)
    app.include_router(pages.router, prefix=prefix)
    app.include_router(conversations.router, prefix=prefix)
    app.include_router(finance.router, prefix=prefix)
    app.include_router(social.router, prefix=prefix)
    app.include_router(ai.router, prefix=prefix)
    app.include_router(integrations.router, prefix=prefix)

# Legacy AI image routes keep their /v1 prefix plus a root fallback for old nginx setups
app.include_router(ai_router_legacy, prefix="/api/v1", tags=["AI"])
app.include_router(ai_router_legacy, prefix="/v1", tags=["AI"])

if ENV_CHECK["warnings"] or ENV_CHECK["issues"]:
    print("[env] Warnings:", ENV_CHECK["warnings"], "| Issues:", ENV_CHECK["issues"])

@app.on_event("startup")
def startup_seed():
    db = SessionLocal()
    try:
        crud.seed_layout_presets(db)
    finally:
        db.close()

@app.websocket("/ws/{conversation_id}")
async def websocket_endpoint(websocket: WebSocket, conversation_id: str):
    await manager.connect(websocket, conversation_id)
    try:
        while True:
            data = await websocket.receive_text()
            # For now, we just broadcast the message.
            await manager.broadcast(f"Message from client: {data}", conversation_id)
    except WebSocketDisconnect:
        manager.disconnect(websocket, conversation_id)
        await manager.broadcast(f"Client left the chat", conversation_id)

@app.get("/ws/health")
def websocket_health():
    """
    Lightweight websocket health indicator (counts active connections per conversation).
    """
    return {
        "active_conversations": len(manager.active_connections),
        "connections": {cid: len(conns) for cid, conns in manager.active_connections.items()},
    }

# Health and Info Endpoints
@app.get("/api/health")
def health_check(db: Session = Depends(get_db)):
    """Health check endpoint for monitoring"""
    # Test database connection
    try:
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "version": VERSION,
        "timestamp": datetime.utcnow().isoformat(),
        "env": ENV_CHECK,
        "components": {
            "database": db_status,
            "ai_provider": ai_gateway.provider,
            "ai_model": ai_gateway.model,
        },
        "system": {
            "python": platform.python_version(),
            "platform": platform.platform(),
        }
    }

@app.get("/api/version")
def version_info():
    """Get API version information"""
    return {
        "version": VERSION,
        "api_name": "Halext Org API",
        "docs_url": "/docs",
        "features": [
            "tasks",
            "events",
            "labels",
            "pages",
            "conversations",
            "ai_chat",
            "ai_task_suggestions",
            "ai_event_analysis",
            "ai_note_summary",
            "admin_panel",
            "distributed_ai_nodes"
        ]
    }

# Backward-compatible health/version endpoints without /api prefix
@app.get("/health")
def health_check_legacy(db: Session = Depends(get_db)):
    return health_check(db)

@app.get("/version")
def version_info_legacy():
    return version_info()
