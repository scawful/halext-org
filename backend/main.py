from fastapi import FastAPI, Depends, HTTPException, status, Header
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import Optional
import os

from app import crud, models, schemas, auth
from app.database import SessionLocal, engine
from app.ai import AiGateway

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Halext Org API",
    description="The backend API for the Halext Org productivity suite.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

ACCESS_CODE = os.getenv("ACCESS_CODE", "").strip()

def verify_access_code(x_halext_code: Optional[str] = Header(default=None)):
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

@app.on_event("startup")
def startup_seed():
    db = SessionLocal()
    try:
        crud.seed_layout_presets(db)
    finally:
        db.close()

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
    db: Session = Depends(get_db),
    _: str = Depends(verify_access_code)
):
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    db_user = crud.get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    return crud.create_user(db=db, user=user)


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


@app.get("/tasks/", response_model=list[schemas.Task])
def read_tasks(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    tasks = crud.get_tasks_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return tasks


@app.post("/events/", response_model=schemas.Event)
def create_event(
    event: schemas.EventCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    return crud.create_user_event(db=db, event=event, user_id=current_user.id)


@app.get("/events/", response_model=list[schemas.Event])
def read_events(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    events = crud.get_events_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return events

@app.get("/labels/", response_model=list[schemas.Label])
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

@app.get("/pages/", response_model=list[schemas.PageDetail])
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

@app.get("/layout-presets/", response_model=list[schemas.LayoutPresetInfo])
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

@app.post("/pages/{page_id}/share", response_model=list[schemas.PageShareInfo])
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

@app.get("/conversations/", response_model=list[schemas.ConversationSummary])
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
    participant_ids: list[int] = []
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

@app.get("/conversations/{conversation_id}/messages", response_model=list[schemas.ChatMessage])
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

@app.post("/conversations/{conversation_id}/messages", response_model=list[schemas.ChatMessage])
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
