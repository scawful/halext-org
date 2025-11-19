from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import Optional, List
import os

from app import crud, models, schemas, auth
from app.database import SessionLocal, engine
from app.ai import AiGateway
from app.ai_features import AiTaskHelper, AiEventHelper, AiNoteHelper
from app.openwebui_sync import OpenWebUISync
from app.admin_routes import router as admin_router
from app.ai_routes import router as ai_router
from app.content_routes import router as content_router

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
    participants = [
        participant.user.username
        for participant in conversation.participants
        if participant.user is not None
    ]
    return schemas.ConversationSummary(**base, participants=participants)

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
    return messages

@app.post("/conversations/{conversation_id}/messages", response_model=List[schemas.ChatMessage])
async def send_conversation_message(
    conversation_id: int,
    message: schemas.ChatMessageCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
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
    responses = [user_message]
    if conversation.with_ai:
        history_messages = crud.get_messages_for_conversation(db=db, conversation_id=conversation_id, limit=50)
        history_payload = [
            {"role": "assistant" if msg.author_type == "ai" else "user", "content": msg.content}
            for msg in history_messages
        ]
        ai_reply = await ai_gateway.generate_reply(message.content, history_payload)
        ai_message = crud.add_message_to_conversation(
            db=db,
            conversation_id=conversation_id,
            content=ai_reply,
            author_id=None,
            author_type="ai",
            model_used=ai_gateway.model,
        )
        responses.append(ai_message)
    return responses

@app.get("/integrations/openwebui", response_model=schemas.OpenWebUiStatus)
def openwebui_status():
    status_payload = ai_gateway.openwebui_status()
    return schemas.OpenWebUiStatus(**status_payload)

# AI Endpoints
@app.get("/ai/info", response_model=schemas.AiProviderInfo)
def get_ai_provider_info():
    """Get current AI provider configuration"""
    return schemas.AiProviderInfo(**ai_gateway.get_provider_info())

@app.get("/ai/models", response_model=schemas.AiModelsResponse)
async def list_ai_models(current_user: models.User = Depends(auth.get_current_user)):
    """List available AI models"""
    models_list = await ai_gateway.get_models()
    return schemas.AiModelsResponse(
        models=[schemas.AiModelInfo(**m) for m in models_list],
        provider=ai_gateway.provider,
        current_model=ai_gateway.model
    )

@app.post("/ai/chat", response_model=schemas.AiChatResponse)
async def ai_chat(
    request: schemas.AiChatRequest,
    current_user: models.User = Depends(auth.get_current_user)
):
    """Generate AI chat response"""
    response = await ai_gateway.generate_reply(request.prompt, request.history)
    return schemas.AiChatResponse(
        response=response,
        model=request.model or ai_gateway.model,
        provider=ai_gateway.provider
    )

@app.post("/ai/stream")
async def ai_chat_stream(
    request: schemas.AiChatRequest,
    current_user: models.User = Depends(auth.get_current_user)
):
    """Stream AI chat response (Server-Sent Events)"""
    from fastapi.responses import StreamingResponse

    async def generate():
        async for chunk in ai_gateway.generate_stream(
            request.prompt,
            request.history,
            request.model
        ):
            yield f"data: {chunk}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")

@app.post("/ai/embeddings", response_model=schemas.AiEmbeddingsResponse)
async def generate_embeddings(
    request: schemas.AiEmbeddingsRequest,
    current_user: models.User = Depends(auth.get_current_user)
):
    """Generate embeddings for text"""
    embeddings = await ai_gateway.generate_embeddings(request.text, request.model)
    return schemas.AiEmbeddingsResponse(
        embeddings=embeddings,
        model=request.model or ai_gateway.model,
        dimension=len(embeddings)
    )

# AI Task Features
@app.post("/ai/tasks/suggest", response_model=schemas.AiTaskSuggestionsResponse)
async def suggest_task_enhancements(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user)
):
    """Get AI suggestions for task breakdown, labels, time estimate, and priority"""
    helper = AiTaskHelper(ai_gateway)

    # Run all suggestions in parallel
    import asyncio
    subtasks, labels, time_est, priority = await asyncio.gather(
        helper.suggest_subtasks(request.title, request.description),
        helper.suggest_labels(request.title, request.description),
        helper.estimate_time(request.title, request.description),
        helper.suggest_priority(request.title, request.description)
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
    current_user: models.User = Depends(auth.get_current_user)
):
    """Estimate time required for a task"""
    helper = AiTaskHelper(ai_gateway)
    result = await helper.estimate_time(request.title, request.description)
    return schemas.AiTimeEstimateResponse(**result)

@app.post("/ai/tasks/suggest-priority", response_model=schemas.AiPriorityResponse)
async def suggest_task_priority(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user)
):
    """Suggest priority for a task"""
    helper = AiTaskHelper(ai_gateway)
    result = await helper.suggest_priority(request.title, request.description)
    return schemas.AiPriorityResponse(**result)

@app.post("/ai/tasks/suggest-labels", response_model=List[str])
async def suggest_task_labels(
    request: schemas.AiTaskSuggestionsRequest,
    current_user: models.User = Depends(auth.get_current_user)
):
    """Suggest labels for a task"""
    helper = AiTaskHelper(ai_gateway)
    return await helper.suggest_labels(request.title, request.description)

# AI Event Features
@app.post("/ai/events/analyze", response_model=schemas.AiEventAnalysisResponse)
async def analyze_event(
    request: schemas.AiEventAnalysisRequest,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Analyze event and provide AI suggestions"""
    helper = AiEventHelper(ai_gateway)

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
        helper.summarize_event(request.title, request.description, duration_minutes),
        helper.suggest_preparation(request.title, request.description, request.event_type),
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
    current_user: models.User = Depends(auth.get_current_user)
):
    """Summarize note and extract information"""
    helper = AiNoteHelper(ai_gateway)

    import asyncio
    summary, tags, tasks = await asyncio.gather(
        helper.summarize_note(request.content, request.max_length),
        helper.generate_tags(request.content),
        helper.extract_tasks(request.content)
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
    status = openwebui_sync.get_sync_status()
    return schemas.OpenWebUISyncStatus(**status)

@app.post("/integrations/openwebui/sync/user", response_model=schemas.OpenWebUISyncResponse)
async def sync_user_to_openwebui(
    current_user: models.User = Depends(auth.get_current_user)
):
    """Sync current user to OpenWebUI"""
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
    current_user: models.User = Depends(auth.get_current_user)
):
    """Generate SSO link for OpenWebUI"""
    from datetime import timedelta

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
