from fastapi import FastAPI, Depends, HTTPException, status, Header, WebSocket, WebSocketDisconnect
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from datetime import datetime, timedelta
from typing import Optional, List
import os

from app import crud, models, schemas, auth
from app.database import SessionLocal, engine
from app.ai import AiGateway
from app.ai_features import AiTaskHelper, AiEventHelper, AiNoteHelper, AiHiveMindHelper
from app.smart_generation import AiSmartGenerator
from app.recipe_ai import AiRecipeGenerator
from app.openwebui_sync import OpenWebUISync
from app.admin_routes import router as admin_router
from app.ai_routes import router as ai_router
from app.content_routes import router as content_router
from app.ai_usage_logger import log_ai_usage, estimate_token_count
from app.admin_utils import get_current_admin_user
from app.websockets import manager
from app.env_validation import validate_runtime_env

models.Base.metadata.create_all(bind=engine)

VERSION = "0.1.0"

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

# Include admin routes
app.include_router(admin_router)
app.include_router(ai_router, prefix="/api/v1", tags=["AI"])
app.include_router(content_router, prefix="/api")

ACCESS_CODE = os.getenv("ACCESS_CODE", "").strip()
# For development, disable access code requirement
DEV_MODE = os.getenv("DEV_MODE", "false").lower() == "true"
ENV_CHECK = validate_runtime_env(DEV_MODE)
if ENV_CHECK["warnings"] or ENV_CHECK["issues"]:
    print("[env] Warnings:", ENV_CHECK["warnings"], "| Issues:", ENV_CHECK["issues"])

def verify_access_code(x_halext_code: Optional[str] = Header(default=None)):
    # Skip access code check in development mode
    if DEV_MODE:
        return
    if ACCESS_CODE and x_halext_code != ACCESS_CODE:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Access code required")

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

ai_gateway = AiGateway()
openwebui_sync = OpenWebUISync()

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
            # We can add more logic here later, like saving the message to the database.
            await manager.broadcast(f"Message from client: {data}", conversation_id)
    except WebSocketDisconnect:
        manager.disconnect(websocket, conversation_id)
        await manager.broadcast(f"Client left the chat", conversation_id)

# Health and Info Endpoints
@app.get("/api/health")
def health_check(db: Session = Depends(get_db)):
    """Health check endpoint for monitoring"""
    import platform
    from datetime import datetime
    from sqlalchemy import text

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

def _serialize_page(db: Session, page: models.Page):
    share_entries = crud.get_page_shares(db, page.id)
    share_payload = []
    for share in share_entries:
        username = share.user.username if share.user else "unknown"
        share_payload.append(
            schemas.PageShareInfo(
                user_id=share.user_id,
                username=username,
                can_edit=share.can_edit,
            )
        )
    base = schemas.Page.from_orm(page).dict()
    return schemas.PageDetail(**base, shared_with=share_payload)

def _serialize_conversation(conversation: models.Conversation):
    base = schemas.Conversation.from_orm(conversation).dict()
    participants = []
    participant_details: list[schemas.UserSummary] = []
    for participant in conversation.participants:
        if participant.user is None:
            continue
        participants.append(participant.user.username)
        participant_details.append(
            schemas.UserSummary.from_orm(participant.user)
        )

    last_message = None
    if conversation.messages:
        last_message_obj = sorted(conversation.messages, key=lambda m: m.created_at)[-1]
        last_message = schemas.ChatMessage.from_orm(last_message_obj)

    return schemas.ConversationSummary(
        **base,
        participants=participants,
        participant_details=participant_details,
        last_message=last_message,
        unread_count=0,
    )

def _ensure_page_edit_permission(db: Session, page: models.Page, user_id: int):
    if page.owner_id == user_id:
        return
    share = (
        db.query(models.PageShare)
        .filter(
            models.PageShare.page_id == page.id,
            models.PageShare.user_id == user_id,
        )
        .first()
    )
    if not share or not share.can_edit:
        raise HTTPException(status_code=403, detail="Not allowed to modify this page")

@app.post("/token", response_model=schemas.Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = auth.authenticate_user(db, username=form_data.username, password=form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/users/", response_model=schemas.User)
def create_user(
    user: schemas.UserCreate,
    create_demo_data: bool = True,
    db: Session = Depends(get_db),
    _: str = Depends(verify_access_code)
):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")

    new_user = crud.create_user(db=db, user=user)

    # Create demo content for new users to showcase the UI
    if create_demo_data:
        try:
            from app.seed_data import create_demo_content
            create_demo_content(new_user.id, db)
        except Exception as e:
            print(f"Warning: Failed to create demo content: {e}")
            # Don't fail registration if demo content creation fails

    return new_user


@app.get("/users/me/", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(auth.get_current_active_user)):
    return current_user


@app.get("/users/search", response_model=List[schemas.UserSummary])
def search_users(
    q: str = "",
    limit: int = 20,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Lightweight user search for messaging (matches username/full_name, excludes the requester).
    """
    query = db.query(models.User).filter(models.User.id != current_user.id)
    if q:
        like = f"%{q.lower()}%"
        query = query.filter(
            or_(
                func.lower(models.User.username).like(like),
                func.lower(models.User.full_name).like(like),
            )
        )
    results = query.order_by(models.User.username.asc()).limit(limit).all()
    return [schemas.UserSummary.from_orm(user) for user in results]


@app.post("/tasks/", response_model=schemas.Task)
def create_task(
    task: schemas.TaskCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    return crud.create_user_task(db=db, task=task, user_id=current_user.id)


@app.get("/tasks/", response_model=List[schemas.Task])
def read_tasks(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    tasks = crud.get_tasks_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return tasks


@app.put("/tasks/{task_id}", response_model=schemas.Task)
def update_task(
    task_id: int,
    task: schemas.TaskUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_task = crud.get_task(db, task_id=task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    if db_task.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed to modify this task")
    return crud.update_task(db=db, db_task=db_task, task=task)


@app.delete("/tasks/{task_id}", status_code=204)
def delete_task(
    task_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_task = crud.get_task(db, task_id=task_id)
    if not db_task:
        raise HTTPException(status_code=404, detail="Task not found")
    if db_task.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed to delete this task")
    crud.delete_task(db, task_id=task_id)
    return


@app.post("/events/", response_model=schemas.Event)
def create_event(
    event: schemas.EventCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    return crud.create_user_event(db=db, event=event, user_id=current_user.id)


@app.get("/events/", response_model=List[schemas.Event])
def read_events(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    events = crud.get_events_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return events

@app.get("/labels/", response_model=List[schemas.Label])
def read_labels(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    return crud.get_labels_for_user(db, user_id=current_user.id)

@app.post("/labels/", response_model=schemas.Label)
def create_label(
    label: schemas.LabelCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    return crud.create_label(db, owner_id=current_user.id, payload=label)

@app.get("/pages/", response_model=List[schemas.PageDetail])
def read_pages(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    pages = crud.get_pages_for_user(db, user_id=current_user.id)
    return [_serialize_page(db, page) for page in pages]

@app.post("/pages/", response_model=schemas.PageDetail)
def create_page(
    page: schemas.PageCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.create_page(db=db, user_id=current_user.id, page=page)
    return _serialize_page(db, db_page)

@app.put("/pages/{page_id}", response_model=schemas.PageDetail)
def update_page(
    page_id: int,
    page: schemas.PageBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    _ensure_page_edit_permission(db, db_page, current_user.id)
    updated_page = crud.update_page(db=db, db_page=db_page, page=page)
    return _serialize_page(db, updated_page)

@app.get("/layout-presets/", response_model=List[schemas.LayoutPresetInfo])
def list_layout_presets(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    presets = crud.get_layout_presets(db)
    return [schemas.LayoutPresetInfo.from_orm(preset) for preset in presets]

@app.post("/layout-presets/", response_model=schemas.LayoutPresetInfo)
def create_layout_preset(
    preset: schemas.LayoutPresetCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_preset = crud.create_layout_preset(db=db, preset=preset, owner_id=current_user.id)
    return schemas.LayoutPresetInfo.from_orm(db_preset)

@app.post("/layout-presets/from-page/{page_id}", response_model=schemas.LayoutPresetInfo)
def create_preset_from_page(
    page_id: int,
    name: str,
    description: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can create presets from this page")

    preset_data = schemas.LayoutPresetCreate(
        name=name,
        description=description,
        layout=[schemas.LayoutColumn(**col) for col in db_page.layout]
    )
    db_preset = crud.create_layout_preset(db=db, preset=preset_data, owner_id=current_user.id)
    return schemas.LayoutPresetInfo.from_orm(db_preset)

@app.put("/layout-presets/{preset_id}", response_model=schemas.LayoutPresetInfo)
def update_layout_preset(
    preset_id: int,
    preset: schemas.LayoutPresetBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_preset = crud.get_layout_preset(db, preset_id=preset_id)
    if not db_preset:
        raise HTTPException(status_code=404, detail="Preset not found")
    if db_preset.is_system:
        raise HTTPException(status_code=403, detail="Cannot modify system presets")
    if db_preset.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can modify this preset")

    updated_preset = crud.update_layout_preset(db=db, db_preset=db_preset, preset=preset)
    return schemas.LayoutPresetInfo.from_orm(updated_preset)

@app.delete("/layout-presets/{preset_id}", status_code=204)
def delete_layout_preset(
    preset_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_preset = crud.get_layout_preset(db, preset_id=preset_id)
    if not db_preset:
        raise HTTPException(status_code=404, detail="Preset not found")
    if db_preset.is_system:
        raise HTTPException(status_code=403, detail="Cannot delete system presets")
    if db_preset.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can delete this preset")

    crud.delete_layout_preset(db, preset_id=preset_id)
    return

@app.post("/pages/{page_id}/apply-preset/{preset_id}", response_model=schemas.PageDetail)
def apply_layout_preset_to_page(
    page_id: int,
    preset_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can apply presets")
    preset = crud.get_layout_preset(db, preset_id=preset_id)
    if not preset:
        raise HTTPException(status_code=404, detail="Preset not found")
    updated_page = crud.apply_layout_preset(db, db_page, preset)
    return _serialize_page(db, updated_page)

@app.post("/pages/{page_id}/share", response_model=List[schemas.PageShareInfo])
def share_page(
    page_id: int,
    share: schemas.PageShareUpdate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can manage sharing")
    target_user = crud.get_user_by_username(db, username=share.username)
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")
    crud.share_page_with_user(db=db, page_id=page_id, user_id=target_user.id, can_edit=share.can_edit)
    shares = crud.get_page_shares(db, page_id=page_id)
    return [
        schemas.PageShareInfo(
            user_id=s.user_id,
            username=s.user.username if s.user else "unknown",
            can_edit=s.can_edit,
        )
        for s in shares
    ]

@app.delete("/pages/{page_id}/share/{username}", status_code=204)
def revoke_share(
    page_id: int,
    username: str,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    db_page = crud.get_page(db, page_id=page_id)
    if not db_page:
        raise HTTPException(status_code=404, detail="Page not found")
    if db_page.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can modify sharing")
    target_user = crud.get_user_by_username(db, username=username)
    if not target_user:
        raise HTTPException(status_code=404, detail="Target user not found")
    crud.remove_page_share(db, page_id=page_id, user_id=target_user.id)
    return

@app.get("/conversations/", response_model=List[schemas.ConversationSummary])
def list_conversations(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversations = crud.get_conversations_for_user(db=db, user_id=current_user.id)
    return [_serialize_conversation(conversation) for conversation in conversations]

@app.get("/conversations/{conversation_id}", response_model=schemas.ConversationSummary)
def get_conversation(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return _serialize_conversation(conversation)

@app.post("/conversations/", response_model=schemas.ConversationSummary)
def create_conversation(
    conversation: schemas.ConversationCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    participant_ids: List[int] = []
    for username in conversation.participant_usernames:
        target = crud.get_user_by_username(db, username=username)
        if not target:
            raise HTTPException(status_code=404, detail=f"User {username} not found")
        participant_ids.append(target.id)
    db_conversation = crud.create_conversation(
        db=db,
        owner_id=current_user.id,
        payload=conversation,
        participant_ids=participant_ids,
    )
    return _serialize_conversation(db_conversation)

@app.put("/conversations/{conversation_id}", response_model=schemas.ConversationSummary)
def update_conversation(
    conversation_id: int,
    update: schemas.ConversationBase,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if conversation.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can modify conversation settings")

    # Update fields
    conversation.title = update.title
    conversation.mode = update.mode
    conversation.with_ai = update.with_ai
    conversation.default_model_id = update.default_model_id

    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return _serialize_conversation(conversation)

@app.get("/conversations/{conversation_id}/messages", response_model=List[schemas.ChatMessage])
def get_conversation_messages(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=200)
    # Convert ORM models to Pydantic schemas using from_orm (Pydantic v1)
    return [schemas.ChatMessage.from_orm(msg) for msg in messages]

@app.post("/conversations/{conversation_id}/messages", response_model=List[schemas.ChatMessage])
async def send_conversation_message(
    conversation_id: int,
    message: schemas.ChatMessageCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    """Send a message to a conversation and get AI response if enabled"""
    try:
        conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
        if not conversation:
            raise HTTPException(status_code=404, detail="Conversation not found")
        
        user_message = crud.add_message_to_conversation(
            db=db,
            conversation_id=conversation_id,
            content=message.content,
            author_id=current_user.id,
            author_type="user",
        )
        import json
        # Convert ORM model to Pydantic schema for JSON serialization (Pydantic v1)
        user_message_schema = schemas.ChatMessage.from_orm(user_message)
        
        try:
            await manager.broadcast(json.dumps(user_message_schema.dict()), str(conversation_id))
        except Exception as e:
            print(f"⚠️ Warning: Failed to broadcast user message: {e}")
            # Continue - broadcasting is not critical
        
        responses = [user_message_schema]
        if conversation.with_ai:
            if conversation.hive_mind_goal:
                print(f"Hive Mind logic would be triggered for conversation {conversation_id}")

            history_messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=50)
            history_payload = [
                {"role": "assistant" if msg.author_type == "ai" else "user", "content": msg.content}
                for msg in history_messages
            ]
            
            # Enhanced Context Awareness
            context_str = ""
            try:
                embedding_model = "all-minilm-l6-v2" # or some other default
                embedding = await ai_gateway.generate_embeddings(message.content, embedding_model, user_id=current_user.id, db=db)
                if embedding:
                    similar_items = crud.get_similar_embeddings(db, owner_id=current_user.id, query_embedding=embedding)
                    if similar_items:
                        context_str = "\n\nHere is some additional context that might be relevant:\n"
                        for item in similar_items:
                            # TODO: Fetch the actual content from the source
                            context_str += f"- From {item.source} (ID: {item.source_id})\n"
            except Exception as e:
                print(f"⚠️ Warning: Failed to get context embeddings: {e}")
                # Continue without context - not critical

            # Use model from: 1) message override, 2) conversation default, 3) system default
            model_to_use = message.model or conversation.default_model_id
            import time
            start_time = time.time()
            
            try:
                ai_reply, route = await ai_gateway.generate_reply(
                    message.content + context_str,
                    history_payload,
                    model_identifier=model_to_use,
                    user_id=current_user.id,
                    db=db,
                    include_context=True,
                )
            except Exception as e:
                print(f"❌ Error generating AI reply: {e}")
                import traceback
                traceback.print_exc()
                # Return user message only if AI generation fails
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to generate AI response: {str(e)}"
                )
            
            # Log AI usage
            latency_ms = int((time.time() - start_time) * 1000)
            try:
                log_ai_usage(
                    db=db,
                    user_id=current_user.id,
                    model_identifier=route.identifier,
                    endpoint="/conversations/{id}/messages",
                    prompt_tokens=estimate_token_count(message.content),
                    response_tokens=estimate_token_count(ai_reply),
                    conversation_id=conversation_id,
                    latency_ms=latency_ms,
                )
            except Exception as e:
                print(f"⚠️ Warning: Failed to log AI usage: {e}")
            
            ai_message = crud.add_message_to_conversation(
                db=db,
                conversation_id=conversation_id,
                content=ai_reply,
                author_id=None,
                author_type="ai",
                model_used=route.identifier,
            )
            # Convert ORM model to Pydantic schema for JSON serialization (Pydantic v1)
            ai_message_schema = schemas.ChatMessage.from_orm(ai_message)
            
            try:
                await manager.broadcast(json.dumps(ai_message_schema.dict()), str(conversation_id))
            except Exception as e:
                print(f"⚠️ Warning: Failed to broadcast AI message: {e}")
                # Continue - broadcasting is not critical
            
            responses.append(ai_message_schema)
        return responses
    except HTTPException:
        # Re-raise HTTP exceptions (like 404) as-is
        raise
    except Exception as e:
        print(f"❌ Unexpected error in send_conversation_message: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


@app.post("/conversations/{conversation_id}/hive-mind/goal", response_model=schemas.ConversationSummary)
async def set_hive_mind_goal(
    conversation_id: int,
    goal: str,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if conversation.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the owner can set the hive mind goal")

    conversation.hive_mind_goal = goal
    db.add(conversation)
    db.commit()
    db.refresh(conversation)
    return _serialize_conversation(conversation)


@app.get("/conversations/{conversation_id}/hive-mind/summary", response_model=str)
async def get_hive_mind_summary(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if not conversation.hive_mind_goal:
        raise HTTPException(status_code=400, detail="This conversation does not have a hive mind goal.")

    history_messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=50)
    history_payload = [
        {"role": "assistant" if msg.author_type == "ai" else "user", "content": msg.content}
        for msg in history_messages
    ]

    helper = AiHiveMindHelper(ai_gateway, user_id=current_user.id, db=db)
    summary = await helper.summarize_conversation(history_payload, conversation.hive_mind_goal)
    return summary


@app.get("/conversations/{conversation_id}/hive-mind/next-steps", response_model=List[str])
async def get_hive_mind_next_steps(
    conversation_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    conversation = crud.get_conversation_for_user(db=db, conversation_id=conversation_id, user_id=current_user.id)
    if not conversation:
        raise HTTPException(status_code=404, detail="Conversation not found")
    if not conversation.hive_mind_goal:
        raise HTTPException(status_code=400, detail="This conversation does not have a hive mind goal.")

    history_messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=50)
    history_payload = [
        {"role": "assistant" if msg.author_type == "ai" else "user", "content": msg.content}
        for msg in history_messages
    ]

    helper = AiHiveMindHelper(ai_gateway, user_id=current_user.id, db=db)
    next_steps = await helper.suggest_next_steps(history_payload, conversation.hive_mind_goal)
    return next_steps


@app.get("/integrations/openwebui", response_model=schemas.OpenWebUiStatus)
def openwebui_status():
    status_payload = ai_gateway.openwebui_status()
    return schemas.OpenWebUiStatus(**status_payload)

# AI Endpoints
def _build_provider_info(db: Session, current_user: models.User) -> schemas.AiProviderInfo:
    # Load any user-scoped credentials before returning provider info
    try:
        ai_gateway._ensure_cloud_providers(db, user_id=current_user.id)  # type: ignore[attr-defined]
    except Exception as exc:
        print(f"Warning: could not refresh provider credentials: {exc}")

    base = ai_gateway.get_provider_info()
    creds = crud.list_provider_credentials(db, owner_id=current_user.id)
    base["credentials"] = [schemas.ProviderCredentialStatus(**c) for c in creds]
    return schemas.AiProviderInfo(**base)


@app.get("/ai/info", response_model=schemas.AiProviderInfo)
def get_ai_provider_info(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Get current AI provider configuration"""
    return _build_provider_info(db, current_user)


@app.get("/ai/provider-info", response_model=schemas.AiProviderInfo)
def get_ai_provider_info_alias(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Alias for provider info to support older clients/tests."""
    return _build_provider_info(db, current_user)

@app.get("/ai/models", response_model=schemas.AiModelsResponse)
async def list_ai_models(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """List available AI models - always returns a valid response."""
    fallback_identifier = "mock:llama3.1"

    def _fallback_response(default_id: str = fallback_identifier) -> schemas.AiModelsResponse:
        provider_key, model_name, _ = ai_gateway._parse_identifier(default_id)  # type: ignore[attr-defined]
        return schemas.AiModelsResponse(
            models=[
                schemas.AiModelInfo(
                    id=default_id,
                    name=model_name,
                    provider=provider_key,
                    source=provider_key,
                )
            ],
            provider=provider_key,
            current_model=model_name,
            default_model_id=default_id,
            credentials=[],
        )

    try:
        try:
            models_list = await ai_gateway.get_models(db=db, user_id=current_user.id)
        except Exception as exc:
            print(f"Error listing AI models: {exc}")
            import traceback
            traceback.print_exc()
            models_list = [
                ai_gateway._format_model_entry(  # type: ignore[attr-defined]
                    ai_gateway.provider or "mock",
                    ai_gateway.model or "llama3.1",
                    source=ai_gateway.provider or "mock",
                )
            ]

        if not models_list:
            models_list = [
                ai_gateway._format_model_entry(  # type: ignore[attr-defined]
                    "mock",
                    "llama3.1",
                    source="mock",
                )
            ]

        try:
            credential_status = crud.list_provider_credentials(db, owner_id=current_user.id)
        except Exception as exc:
            print(f"Error getting credential status: {exc}")
            import traceback
            traceback.print_exc()
            credential_status = []

        # Treat env-provided provider clients as having keys even if DB secrets are absent
        for provider_key in ("openai", "gemini"):
            if ai_gateway.providers.get(provider_key):
                existing = None
                for entry in credential_status:
                    if isinstance(entry, dict) and entry.get("provider") == provider_key:
                        existing = entry
                        break
                if existing is None:
                    credential_status.append(
                        {
                            "provider": provider_key,
                            "has_key": True,
                            "masked_key": None,
                            "key_name": "env",
                            "model": None,
                        }
                    )
                else:
                    existing["has_key"] = existing.get("has_key") or True
                    existing.setdefault("key_name", "env")

        credential_has_key = {
            c.get("provider"): bool(c.get("has_key")) for c in credential_status if isinstance(c, dict)
        }

        available_ids: List[str] = []
        provider_first: dict = {}
        for entry in models_list:
            if not isinstance(entry, dict):
                print(f"⚠️ Warning: Model entry is not a dict: {type(entry)}")
                continue
            model_id = entry.get("id")
            provider_key = entry.get("provider") or "mock"
            name = None
            if isinstance(model_id, str) and ":" in model_id:
                name = model_id.split(":", 1)[1]
            name = entry.get("name") or name or model_id
            if not model_id:
                model_id = f"{provider_key}:{name or ai_gateway.model}"
            if model_id:
                available_ids.append(model_id)
                provider_first.setdefault(provider_key, model_id)

        default_model_id = ai_gateway.default_model_identifier or None

        def _provider_from_identifier(identifier: Optional[str]) -> str:
            try:
                provider_key, _, _ = (
                    ai_gateway._parse_identifier(identifier)  # type: ignore[attr-defined]
                    if identifier
                    else ("mock", "llama3.1", None)
                )
            except Exception:
                provider_key = "mock"
            return "ollama" if provider_key == "ollama-local" else provider_key

        def _has_credentials(provider_key: str) -> bool:
            provider_key = "ollama" if provider_key == "ollama-local" else provider_key
            if provider_key in ("openai", "gemini"):
                return credential_has_key.get(provider_key, False) or ai_gateway.providers.get(provider_key) is not None
            return True

        if not default_model_id or default_model_id not in available_ids or not _has_credentials(_provider_from_identifier(default_model_id)):
            priorities = ["openai", "gemini", "openwebui", "ollama", "client"]
            preferred = None
            for provider_key in priorities:
                if not _has_credentials(provider_key):
                    continue
                preferred = next(
                    (
                        mid
                        for mid in available_ids
                        if isinstance(mid, str) and mid.startswith(f"{provider_key}:")
                    ),
                    None,
                )
                if preferred:
                    break
            if not preferred:
                # fallback to any provider that has credentials
                for pk, ident in provider_first.items():
                    if ident and _has_credentials(pk):
                        preferred = ident
                        break
            default_model_id = preferred or (available_ids[0] if available_ids else fallback_identifier)

        try:
            provider, model_name, _ = ai_gateway._parse_identifier(default_model_id)  # type: ignore[attr-defined]
        except Exception as exc:
            print(f"❌ Error parsing model identifier '{default_model_id}': {exc}")
            import traceback
            traceback.print_exc()
            provider, model_name, default_model_id = "mock", "llama3.1", fallback_identifier

        ai_gateway.default_model_identifier = default_model_id
        ai_gateway.provider = provider
        ai_gateway.model = model_name

        model_schemas: List[schemas.AiModelInfo] = []
        for entry in models_list:
            if not isinstance(entry, dict):
                continue
            provider_key = entry.get("provider") or "mock"
            name = entry.get("name") or entry.get("id") or model_name
            model_id = entry.get("id") or f"{provider_key}:{name}"
            model_dict = {
                "id": model_id,
                "name": name or model_name,
                "provider": provider_key,
                "size": entry.get("size"),
                "source": entry.get("source") or provider_key,
                "node_id": entry.get("node_id"),
                "node_name": entry.get("node_name"),
                "endpoint": entry.get("endpoint"),
                "latency_ms": entry.get("latency_ms"),
                "metadata": entry.get("metadata") or {},
                "modified_at": entry.get("modified_at"),
                "description": entry.get("description"),
                "context_window": entry.get("context_window"),
                "max_output_tokens": entry.get("max_output_tokens"),
                "input_cost_per_1m": entry.get("input_cost_per_1m"),
                "output_cost_per_1m": entry.get("output_cost_per_1m"),
                "supports_vision": entry.get("supports_vision"),
                "supports_function_calling": entry.get("supports_function_calling"),
            }
            try:
                model_schemas.append(schemas.AiModelInfo(**model_dict))
            except Exception as exc:
                print(f"❌ Error creating AiModelInfo for model {model_id}: {exc}")
                import traceback
                traceback.print_exc()

        if not model_schemas:
            model_schemas = [
                schemas.AiModelInfo(
                    id=default_model_id,
                    name=model_name,
                    provider=provider,
                    source=provider,
                )
            ]

        try:
            credential_schemas = [schemas.ProviderCredentialStatus(**c) for c in credential_status]
        except Exception as exc:
            print(f"Error creating credential schemas: {exc}")
            import traceback
            traceback.print_exc()
            credential_schemas = []

        return schemas.AiModelsResponse(
            models=model_schemas,
            provider=provider,
            current_model=model_name,
            default_model_id=default_model_id,
            credentials=credential_schemas,
        )
    except Exception as exc:
        print(f"❌ CRITICAL: Unexpected error in list_ai_models: {exc}")
        import traceback
        traceback.print_exc()
        return _fallback_response()

@app.post("/admin/ai/default-model", response_model=schemas.AiModelsResponse)
async def set_default_ai_model(
    payload: schemas.AiDefaultModelRequest,
    admin_user: models.User = Depends(get_current_admin_user),
    db: Session = Depends(get_db),
):
    """
    Admin-only: set the backend default model so Messages/AgentHub pick the same route.
    """
    models_list = await ai_gateway.get_models(db=db, user_id=admin_user.id)
    available_ids = [m["id"] for m in models_list]
    if payload.default_model_id not in available_ids:
        raise HTTPException(status_code=400, detail="Model is not available on this backend")

    provider, model_name, _ = ai_gateway._parse_identifier(payload.default_model_id)  # type: ignore[attr-defined]
    ai_gateway.default_model_identifier = payload.default_model_id
    ai_gateway.provider = provider
    ai_gateway.model = model_name

    credential_status = crud.list_provider_credentials(db, owner_id=admin_user.id)
    return schemas.AiModelsResponse(
        models=[schemas.AiModelInfo(**m) for m in models_list],
        provider=provider,
        current_model=model_name,
        default_model_id=payload.default_model_id,
        credentials=[schemas.ProviderCredentialStatus(**c) for c in credential_status],
    )

@app.post("/ai/chat", response_model=schemas.AiChatResponse)
async def ai_chat(
    request: schemas.AiChatRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate AI chat response"""
    import time
    start_time = time.time()
    
    response, route = await ai_gateway.generate_reply(
        request.prompt,
        request.history,
        model_identifier=request.model,
        user_id=current_user.id,
        db=db,
        include_context=True,
    )
    
    # Log AI usage
    latency_ms = int((time.time() - start_time) * 1000)
    try:
        log_ai_usage(
            db=db,
            user_id=current_user.id,
            model_identifier=route.identifier,
            endpoint="/ai/chat",
            prompt_tokens=estimate_token_count(request.prompt),
            response_tokens=estimate_token_count(response),
            latency_ms=latency_ms,
        )
    except Exception as e:
        print(f"Warning: Failed to log AI usage: {e}")
    
    return schemas.AiChatResponse(
        response=response,
        model=route.identifier,
        provider=route.key,
    )

@app.post("/ai/stream")
async def ai_chat_stream(
    request: schemas.AiChatRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Stream AI chat response (Server-Sent Events)"""
    from fastapi.responses import StreamingResponse

    stream, route = await ai_gateway.generate_stream(
        request.prompt,
        request.history,
        model_identifier=request.model,
        user_id=current_user.id,
        db=db,
    )

    async def generate():
        async for chunk in stream:
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    headers = {"X-Halext-AI-Model": route.identifier}
    return StreamingResponse(generate(), media_type="text/event-stream", headers=headers)

@app.post("/ai/embeddings", response_model=schemas.AiEmbeddingsResponse)
async def generate_embeddings(
    request: schemas.AiEmbeddingsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate embeddings for text"""
    embeddings = await ai_gateway.generate_embeddings(
        request.text,
        request.model,
        user_id=current_user.id,
        db=db,
    )
    return schemas.AiEmbeddingsResponse(
        embeddings=embeddings,
        model=request.model or ai_gateway.default_model_identifier,
        dimension=len(embeddings)
    )

# AI Task Features
@app.post("/ai/tasks/suggest-stream")
async def suggest_task_enhancements_stream(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI suggestions for task breakdown, labels, time estimate, and priority"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    
    from fastapi.responses import StreamingResponse

    async def generate():
        stream = await helper.suggest_subtasks_stream(request.title, request.description)
        async for chunk in stream:
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")


@app.post("/ai/tasks/suggest", response_model=schemas.AiTaskSuggestionsResponse)
async def suggest_task_enhancements(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI suggestions for task breakdown, labels, time estimate, and priority"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)

    # Run all suggestions in parallel
    import asyncio
    subtasks, labels, time_est, priority = await asyncio.gather(
        helper.suggest_subtasks(request.title, request.description),
        helper.suggest_labels(request.title, request.description),
        helper.estimate_time(request.title, request.description),
        helper.suggest_priority(request.title, request.description, model_identifier=request.model)
    )

    return schemas.AiTaskSuggestionsResponse(
        subtasks=subtasks,
        labels=labels,
        estimated_hours=time_est["estimated_hours"],
        priority=priority["priority"],
        priority_reasoning=priority["reasoning"]
    )

@app.post("/ai/tasks/estimate-time", response_model=schemas.AiTimeEstimateResponse)
async def estimate_task_time(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Estimate time required for a task"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    result = await helper.estimate_time(request.title, request.description, request.model)
    return schemas.AiTimeEstimateResponse(**result)

@app.post("/ai/tasks/suggest-priority", response_model=schemas.AiPriorityResponse)
async def suggest_task_priority(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Suggest priority for a task"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    result = await helper.suggest_priority(request.title, request.description, model_identifier=request.model)
    return schemas.AiPriorityResponse(**result)

@app.post("/ai/tasks/suggest-labels", response_model=List[str])
async def suggest_task_labels(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Suggest labels for a task"""
    helper = AiTaskHelper(ai_gateway, user_id=current_user.id, db=db)
    return await helper.suggest_labels(request.title, request.description, request.model)

# AI Event Features
@app.post("/ai/events/analyze", response_model=schemas.AiEventAnalysisResponse)
async def analyze_event(
    request: schemas.AiEventAnalysisRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Analyze event and provide AI suggestions"""
    helper = AiEventHelper(ai_gateway, user_id=current_user.id, db=db)

    # Get existing events for conflict detection
    existing_events = crud.get_user_events(db, current_user.id)
    events_data = [
        {
            "id": e.id,
            "title": e.title,
            "start_time": e.start_time,
            "end_time": e.end_time
        }
        for e in existing_events
    ]

    # Run analysis
    import asyncio
    duration_minutes = int((request.end_time - request.start_time).total_seconds() / 60)

    summary, prep_steps, optimal_times = await asyncio.gather(
        helper.summarize_event(request.title, request.description, duration_minutes, request.model),
        helper.suggest_preparation(request.title, request.description, request.event_type, request.model),
        helper.suggest_optimal_time(request.title, duration_minutes, request.start_time, events_data)
    )

    conflicts = await helper.detect_conflicts(
        request.title,
        request.start_time,
        request.end_time,
        events_data
    )

    return schemas.AiEventAnalysisResponse(
        summary=summary,
        preparation_steps=prep_steps,
        optimal_times=optimal_times,
        conflicts=conflicts
    )

# AI Note Features
@app.post("/ai/notes/summarize", response_model=schemas.AiNoteSummaryResponse)
async def summarize_note(
    request: schemas.AiNoteSummaryRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Summarize note and extract information"""
    helper = AiNoteHelper(ai_gateway, user_id=current_user.id, db=db)

    import asyncio
    summary, tags, tasks = await asyncio.gather(
        helper.summarize_note(request.content, request.max_length, request.model),
        helper.generate_tags(request.content, request.model),
        helper.extract_tasks(request.content, request.model)
    )

    return schemas.AiNoteSummaryResponse(
        summary=summary,
        tags=tags,
        extracted_tasks=tasks
    )

# OpenWebUI Sync Endpoints
@app.get("/integrations/openwebui/sync/status", response_model=schemas.OpenWebUISyncStatus)
def get_openwebui_sync_status(current_user: models.User = Depends(auth.get_current_user)):
    """Get OpenWebUI sync configuration status"""
    if not openwebui_sync.is_enabled():
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="OpenWebUI sync is disabled")
    status = openwebui_sync.get_sync_status()
    return schemas.OpenWebUISyncStatus(**status)

@app.post("/integrations/openwebui/sync/user", response_model=schemas.OpenWebUISyncResponse)
async def sync_user_to_openwebui(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Sync current user to OpenWebUI"""
    if not openwebui_sync.is_enabled():
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="OpenWebUI sync is disabled")

    result = await openwebui_sync.sync_user_from_halext(
        current_user.id,
        current_user.username,
        current_user.email,
        current_user.full_name
    )

    return schemas.OpenWebUISyncResponse(
        success=result.get("success", False),
        action=result.get("action"),
        user_id=result.get("user_id"),
        message=result.get("message", ""),
        error=result.get("error")
    )

@app.post("/integrations/openwebui/sso", response_model=schemas.OpenWebUISSOResponse)
async def get_openwebui_sso_link(
    request: schemas.OpenWebUISSORequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate SSO link for OpenWebUI"""
    from datetime import timedelta

    if not openwebui_sync.is_enabled():
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="OpenWebUI sync is disabled")

    # Generate SSO token
    token = await openwebui_sync.generate_sso_token(
        current_user.id,
        current_user.username,
        current_user.email,
        expires_delta=timedelta(hours=24)
    )

    # Generate SSO URL
    sso_url = await openwebui_sync.get_openwebui_login_url(
        current_user.id,
        current_user.username,
        current_user.email,
        request.redirect_to
    )

    return schemas.OpenWebUISSOResponse(
        sso_url=sso_url,
        token=token,
        expires_in=86400  # 24 hours in seconds
    )

# Smart Generation Endpoint
@app.post("/ai/generate-tasks", response_model=schemas.AiGenerateTasksResponse)
async def generate_smart_tasks(
    request: schemas.AiGenerateTasksRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate tasks, events, and smart lists from natural language prompt"""
    helper = AiSmartGenerator(ai_gateway, user_id=current_user.id)

    result = await helper.generate_from_prompt(
        prompt=request.prompt,
        timezone=request.context.timezone,
        current_date=request.context.current_date,
        existing_task_titles=request.context.existing_task_titles,
        upcoming_event_dates=request.context.upcoming_event_dates,
        model_identifier=request.model,
        db=db,
    )

    return schemas.AiGenerateTasksResponse(**result)

# Recipe AI Endpoints
@app.post("/ai/recipes/generate", response_model=schemas.RecipeGenerationResponse)
async def generate_recipes(
    request: schemas.RecipeGenerationRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Generate recipes from available ingredients"""
    helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

    result = await helper.generate_recipes(
        ingredients=request.ingredients,
        dietary_restrictions=request.dietary_restrictions,
        cuisine_preferences=request.cuisine_preferences,
        difficulty_level=request.difficulty_level,
        time_limit_minutes=request.time_limit_minutes,
        servings=request.servings,
        meal_type=request.meal_type,
        model_identifier=request.model,
        db=db,
    )

    return schemas.RecipeGenerationResponse(**result)

@app.post("/ai/recipes/meal-plan", response_model=schemas.MealPlanResponse)
async def generate_meal_plan(
    request: schemas.MealPlanRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Generate a meal plan for multiple days"""
    helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

    result = await helper.generate_meal_plan(
        ingredients=request.ingredients,
        days=request.days,
        dietary_restrictions=request.dietary_restrictions,
        budget=request.budget,
        meals_per_day=request.meals_per_day,
        model_identifier=request.model,
        db=db,
    )

    return schemas.MealPlanResponse(**result)

@app.post("/ai/recipes/suggest-substitutions", response_model=schemas.RecipeGenerationResponse)
async def suggest_ingredient_substitutions(
    request: schemas.SubstitutionRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Suggest ingredient substitutions and alternative recipes"""
    helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

    result = await helper.suggest_substitutions(
        ingredients=request.ingredients,
        recipe_type=request.recipe_type,
        model_identifier=request.model,
        db=db,
    )

    return schemas.RecipeGenerationResponse(**result)

@app.post("/ai/recipes/analyze-ingredients", response_model=schemas.IngredientAnalysis)
async def analyze_ingredients(
    request: schemas.IngredientsRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    """Analyze and categorize ingredients"""
    helper = AiRecipeGenerator(ai_gateway, user_id=current_user.id)

    result = await helper.analyze_ingredients(
        ingredients=request.ingredients,
        model_identifier=request.model,
        db=db,
    )

    return schemas.IngredientAnalysis(**result)

# Finance Endpoints
@app.get("/finance/accounts", response_model=List[schemas.FinanceAccount])
def list_finance_accounts(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_accounts(db, current_user.id)


@app.post("/finance/accounts", response_model=schemas.FinanceAccount, status_code=status.HTTP_201_CREATED)
def create_finance_account(
    payload: schemas.FinanceAccountCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_account(db, current_user.id, payload)


@app.get("/finance/accounts/{account_id}", response_model=schemas.FinanceAccount)
def get_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return account


@app.put("/finance/accounts/{account_id}", response_model=schemas.FinanceAccount)
def update_finance_account(
    account_id: int,
    payload: schemas.FinanceAccountUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    return crud.update_finance_account(db, account, payload)


@app.delete("/finance/accounts/{account_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    crud.delete_finance_account(db, account)


@app.post("/finance/accounts/{account_id}/sync", response_model=schemas.FinanceAccount)
def sync_finance_account(
    account_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    account = crud.get_finance_account(db, current_user.id, account_id)
    if not account:
        raise HTTPException(status_code=404, detail="Account not found")
    account.last_synced = datetime.utcnow()
    db.add(account)
    db.commit()
    db.refresh(account)
    return account


@app.get("/finance/transactions", response_model=List[schemas.FinanceTransaction])
def list_finance_transactions(
    account_id: Optional[int] = None,
    limit: int = 50,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.list_finance_transactions(db, current_user.id, account_id=account_id, limit=limit)


@app.post("/finance/transactions", response_model=schemas.FinanceTransaction, status_code=status.HTTP_201_CREATED)
def create_finance_transaction(
    payload: schemas.FinanceTransactionCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_transaction(db, current_user.id, payload)


@app.get("/finance/budgets", response_model=List[schemas.FinanceBudget])
def list_finance_budgets(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_budgets(db, current_user.id)


@app.post("/finance/budgets", response_model=schemas.FinanceBudget, status_code=status.HTTP_201_CREATED)
def create_finance_budget(
    payload: schemas.FinanceBudgetCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.create_finance_budget(db, current_user.id, payload)


@app.patch("/finance/budgets/{budget_id}", response_model=schemas.FinanceBudget)
def update_finance_budget(
    budget_id: int,
    payload: schemas.FinanceBudgetUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    budget = crud.get_finance_budget(db, current_user.id, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    return crud.update_finance_budget(db, budget, payload)


@app.delete("/finance/budgets/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_finance_budget(
    budget_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    budget = crud.get_finance_budget(db, current_user.id, budget_id)
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    crud.delete_finance_budget(db, budget)


@app.get("/finance/summary", response_model=schemas.FinanceSummary)
def finance_summary(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.get_finance_summary(db, current_user.id)


# Social Circles Endpoints
@app.get("/social/circles", response_model=List[schemas.SocialCircle])
def list_social_circles(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    try:
        circles = crud.list_social_circles(db, current_user.id)
        for circle in circles:
            circle.member_count = len(circle.members)
        return circles
    except Exception as e:
        print(f"Error listing social circles: {e}")
        import traceback
        traceback.print_exc()
        # Return empty list instead of crashing
        return []


@app.post("/social/circles", response_model=schemas.SocialCircle, status_code=status.HTTP_201_CREATED)
def create_social_circle(
    payload: schemas.SocialCircleCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    circle = crud.create_social_circle(db, current_user.id, payload)
    circle.member_count = len(circle.members)
    return circle


@app.post("/social/circles/join", response_model=schemas.SocialCircle)
def join_social_circle(
    invite_code: str,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    circle = crud.join_social_circle(db, current_user.id, invite_code)
    if not circle:
        raise HTTPException(status_code=404, detail="Circle not found")
    circle.member_count = len(circle.members)
    return circle


@app.get("/social/circles/{circle_id}/pulses", response_model=List[schemas.SocialPulse])
def list_social_pulses(
    circle_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    return crud.list_social_pulses(db, current_user.id, circle_id=circle_id)


@app.post("/social/circles/{circle_id}/pulses", response_model=schemas.SocialPulse, status_code=status.HTTP_201_CREATED)
def create_social_pulse(
    circle_id: int,
    payload: schemas.SocialPulseCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db),
):
    pulse = crud.create_social_pulse(db, current_user.id, circle_id, payload)
    if not pulse:
        raise HTTPException(status_code=404, detail="Circle not found")
    return pulse


@app.get("/admin/api-catalog", response_model=List[schemas.ApiRouteInfo])
def admin_api_catalog(
    current_user: models.User = Depends(get_current_admin_user),
):
    routes: List[schemas.ApiRouteInfo] = []
    for route in app.routes:
        if not getattr(route, "methods", None):
            continue
        if not getattr(route, "path", "").startswith("/"):
            continue
        if route.path.startswith("/openapi") or route.path.startswith("/docs"):
            continue
        methods = sorted(m for m in route.methods if m not in {"HEAD", "OPTIONS"})
        if not methods:
            continue
        routes.append(
            schemas.ApiRouteInfo(
                path=route.path,
                methods=methods,
                name=route.name.replace("_", " ").title() if route.name else "Endpoint",
                summary=getattr(route, "summary", None),
            )
        )
    routes.sort(key=lambda item: item.path)
    return routes
