from sqlalchemy.orm import Session
from sqlalchemy import or_
from sqlalchemy.sql import func
from . import models, schemas
from passlib.context import CryptContext
from .presets import DEFAULT_LAYOUT_PRESETS

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(
        email=user.email,
        username=user.username,
        full_name=user.full_name,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_tasks_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return (
        db.query(models.Task)
        .filter(models.Task.owner_id == user_id)
        .order_by(models.Task.created_at.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )

def _sync_task_labels(db: Session, task: models.Task, label_names: list[str], owner_id: int):
    normalized = []
    for raw in label_names:
        name = raw.strip()
        if name:
            normalized.append(name)
    labels = []
    for name in normalized:
        label = (
            db.query(models.Label)
            .filter(models.Label.owner_id == owner_id, models.Label.name == name)
            .first()
        )
        if not label:
            label = models.Label(name=name, owner_id=owner_id)
            db.add(label)
            db.flush()
        labels.append(label)
    task.labels = labels

def create_user_task(db: Session, task: schemas.TaskCreate, user_id: int):
    payload = task.dict(exclude={"labels"})
    db_task = models.Task(**payload, owner_id=user_id)
    db.add(db_task)
    db.flush()
    _sync_task_labels(db, db_task, task.labels, owner_id=user_id)
    db.commit()
    db.refresh(db_task)
    return db_task

def get_events_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return db.query(models.Event).filter(models.Event.owner_id == user_id).offset(skip).limit(limit).all()

def create_user_event(db: Session, event: schemas.EventCreate, user_id: int):
    db_event = models.Event(**event.dict(), owner_id=user_id)
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    return db_event

def get_page(db: Session, page_id: int):
    return db.query(models.Page).filter(models.Page.id == page_id).first()

def get_pages_for_user(db: Session, user_id: int):
    shared_page_ids = db.query(models.PageShare.page_id).filter(models.PageShare.user_id == user_id)
    return (
        db.query(models.Page)
        .filter(
            or_(
                models.Page.owner_id == user_id,
                models.Page.id.in_(shared_page_ids),
            )
        )
        .order_by(models.Page.created_at.asc())
        .all()
    )

def create_page(db: Session, user_id: int, page: schemas.PageCreate):
    layout_payload = [column.dict() for column in page.layout]
    db_page = models.Page(
        title=page.title,
        description=page.description,
        owner_id=user_id,
        visibility=page.visibility,
        layout=layout_payload,
    )
    db.add(db_page)
    db.commit()
    db.refresh(db_page)
    return db_page

def update_page(db: Session, db_page: models.Page, page: schemas.PageBase):
    db_page.title = page.title
    db_page.description = page.description
    db_page.visibility = page.visibility
    db_page.layout = [column.dict() for column in page.layout]
    db.add(db_page)
    db.commit()
    db.refresh(db_page)
    return db_page

def share_page_with_user(db: Session, page_id: int, user_id: int, can_edit: bool = False):
    share = (
        db.query(models.PageShare)
        .filter(
            models.PageShare.page_id == page_id,
            models.PageShare.user_id == user_id,
        )
        .first()
    )
    if share:
        share.can_edit = can_edit
    else:
        share = models.PageShare(page_id=page_id, user_id=user_id, can_edit=can_edit)
        db.add(share)
    db.commit()
    return share

def remove_page_share(db: Session, page_id: int, user_id: int):
    db.query(models.PageShare).filter(
        models.PageShare.page_id == page_id,
        models.PageShare.user_id == user_id,
    ).delete()
    db.commit()

def get_page_shares(db: Session, page_id: int):
    return (
        db.query(models.PageShare)
        .filter(models.PageShare.page_id == page_id)
        .all()
    )

def get_labels_for_user(db: Session, user_id: int):
    return (
        db.query(models.Label)
        .filter(models.Label.owner_id == user_id)
        .order_by(models.Label.name.asc())
        .all()
    )

def create_label(db: Session, owner_id: int, payload: schemas.LabelCreate):
    label = models.Label(
        name=payload.name.strip(),
        color=payload.color or "#5d72ff",
        owner_id=owner_id,
    )
    db.add(label)
    db.commit()
    db.refresh(label)
    return label

def get_layout_presets(db: Session):
    return db.query(models.LayoutPreset).order_by(models.LayoutPreset.created_at.asc()).all()

def get_layout_preset(db: Session, preset_id: int):
    return db.query(models.LayoutPreset).filter(models.LayoutPreset.id == preset_id).first()

def apply_layout_preset(db: Session, page: models.Page, preset: models.LayoutPreset):
    page.layout = preset.layout
    db.add(page)
    db.commit()
    db.refresh(page)
    return page

def seed_layout_presets(db: Session):
    existing = {preset.name for preset in db.query(models.LayoutPreset).all()}
    created = False
    for entry in DEFAULT_LAYOUT_PRESETS:
        if entry["name"] in existing:
            continue
        db_preset = models.LayoutPreset(
            name=entry["name"],
            description=entry.get("description"),
            layout=entry["layout"],
        )
        db.add(db_preset)
        created = True
    if created:
        db.commit()

def create_conversation(db: Session, owner_id: int, payload: schemas.ConversationCreate, participant_ids: list[int]):
    conversation = models.Conversation(
        title=payload.title,
        owner_id=owner_id,
        mode=payload.mode,
        with_ai=payload.with_ai,
    )
    db.add(conversation)
    db.flush()

    all_participants = set(participant_ids)
    all_participants.add(owner_id)
    for participant_id in all_participants:
        role = "owner" if participant_id == owner_id else "member"
        participant = models.ConversationParticipant(
            conversation_id=conversation.id,
            user_id=participant_id,
            role=role,
        )
        db.add(participant)

    db.commit()
    db.refresh(conversation)
    return conversation

def get_conversations_for_user(db: Session, user_id: int):
    return (
        db.query(models.Conversation)
        .join(models.ConversationParticipant)
        .filter(models.ConversationParticipant.user_id == user_id)
        .order_by(models.Conversation.updated_at.desc())
        .all()
    )

def get_conversation_for_user(db: Session, conversation_id: int, user_id: int):
    return (
        db.query(models.Conversation)
        .join(models.ConversationParticipant)
        .filter(
            models.Conversation.id == conversation_id,
            models.ConversationParticipant.user_id == user_id,
        )
        .first()
    )

def add_message_to_conversation(
    db: Session,
    conversation_id: int,
    content: str,
    author_id: int | None,
    author_type: str = "user",
    model_used: str | None = None,
    extras: dict | None = None,
):
    db_message = models.ChatMessage(
        conversation_id=conversation_id,
        author_id=author_id,
        author_type=author_type,
        content=content,
        model_used=model_used,
        extras=extras or {},
    )
    db.add(db_message)
    db.query(models.Conversation).filter(models.Conversation.id == conversation_id).update(
        {"updated_at": func.now()}
    )
    db.commit()
    db.refresh(db_message)
    return db_message

def get_messages_for_conversation(db: Session, conversation_id: int, limit: int = 100):
    return (
        db.query(models.ChatMessage)
        .filter(models.ChatMessage.conversation_id == conversation_id)
        .order_by(models.ChatMessage.created_at.asc())
        .limit(limit)
        .all()
    )
