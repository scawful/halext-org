from fastapi import FastAPI, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
import platform
import json
from datetime import datetime
from typing import Optional
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

from app import models, crud
from app.database import engine, SessionLocal
from app.dependencies import get_db, ai_gateway, ENV_CHECK
from app.websockets import manager
from app.presence_websocket import presence_manager
from app import auth
from jose import JWTError, jwt
import os

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
    integrations,
    server_management,
    collaboration,
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
    app.include_router(collaboration.router, prefix=prefix)
    app.include_router(server_management.router, prefix=prefix)

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

async def verify_websocket_token(websocket: WebSocket, db: Session) -> Optional[models.User]:
    """
    Verify JWT token from WebSocket headers and return authenticated user.
    Returns None if token is invalid or missing.
    """
    # Get token from Authorization header
    auth_header = websocket.headers.get("Authorization") or websocket.headers.get("authorization")
    if not auth_header:
        return None
    
    # Extract token from "Bearer <token>" format
    if not auth_header.startswith("Bearer "):
        return None
    
    token = auth_header[7:]  # Remove "Bearer " prefix
    
    try:
        # Verify and decode token
        SECRET_KEY = os.getenv("SECRET_KEY", "a_very_secret_key_that_should_be_in_env")
        ALGORITHM = "HS256"
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            return None
        
        # Get user from database
        user = crud.get_user_by_username(db, username=username)
        return user
    except JWTError:
        return None


@app.websocket("/ws/presence/{user_id}")
async def presence_websocket_endpoint(websocket: WebSocket, user_id: int, db: Session = Depends(get_db)):
    """
    WebSocket endpoint for real-time presence updates.
    Connect: ws://localhost:8000/ws/presence/{user_id}
    
    Requires Authorization header with Bearer token.
    The user_id in the path must match the authenticated user from the token.

    Message format:
    - Client to Server:
      {"type": "update_status", "status": "online|away|busy|offline"}
      {"type": "typing", "conversation_id": 1, "is_typing": true}
      {"type": "heartbeat"}

    - Server to Client:
      {"type": "presence_update", "data": {"user_id": 1, "status": "online", "last_seen": "..."}}
      {"type": "typing_indicator", "data": {"user_id": 1, "conversation_id": 1, "is_typing": true}}
      {"type": "initial_presences", "data": [{"user_id": 1, "status": "online", ...}, ...]}
    """
    # Verify authentication token before accepting connection
    # We can read headers before accepting
    user = await verify_websocket_token(websocket, db)
    if not user:
        # Accept connection first so we can close it properly
        await websocket.accept()
        await websocket.close(code=4001, reason="Unauthorized - Invalid or missing token")
        return
    
    # Verify user_id from path matches authenticated user
    if user.id != user_id:
        # Accept connection first so we can close it properly
        await websocket.accept()
        await websocket.close(code=4003, reason="Forbidden - User ID mismatch")
        return

    # Accept WebSocket connection and register with presence manager
    await presence_manager.connect(websocket, user_id)

    # Update database presence
    from app import schemas
    presence_update = schemas.PresenceUpdate(status="online", is_online=True)
    crud.upsert_user_presence(db, user_id, presence_update)

    try:
        while True:
            data = await websocket.receive_text()
            try:
                message = json.loads(data)
                await presence_manager.handle_presence_message(websocket, message)

                # Update database based on message type
                if message.get("type") == "update_status":
                    status = message.get("status", "online")
                    presence_update = schemas.PresenceUpdate(
                        status=status,
                        is_online=(status != "offline")
                    )
                    crud.upsert_user_presence(db, user_id, presence_update)

            except json.JSONDecodeError:
                await websocket.send_text(json.dumps({
                    "type": "error",
                    "message": "Invalid JSON format"
                }))

    except WebSocketDisconnect:
        presence_manager.disconnect(websocket)

        # Update database presence to offline
        from app import schemas
        presence_update = schemas.PresenceUpdate(status="offline", is_online=False)
        crud.upsert_user_presence(db, user_id, presence_update)


@app.get("/ws/health")
def websocket_health():
    """
    Lightweight websocket health indicator (counts active connections per conversation).
    """
    return {
        "active_conversations": len(manager.active_connections),
        "connections": {cid: len(conns) for cid, conns in manager.active_connections.items()},
        "presence_connections": len(presence_manager.active_connections),
        "online_users": presence_manager.get_online_users(),
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
