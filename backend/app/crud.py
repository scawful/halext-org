from sqlalchemy.orm import Session, joinedload
from sqlalchemy import or_
from sqlalchemy.sql import func
from datetime import datetime
from typing import Optional, List
import secrets
from . import models, schemas
from passlib.context import CryptContext
from .presets import DEFAULT_LAYOUT_PRESETS
from .encryption import encrypt_api_key, decrypt_api_key, mask_api_key

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
        hashed_password=hashed_password,
        is_admin=getattr(user, "is_admin", False),
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

def _sync_task_labels(db: Session, task: models.Task, label_names: List[str], owner_id: int):
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


def get_task(db: Session, task_id: int):
    return db.query(models.Task).filter(models.Task.id == task_id).first()


def update_task(db: Session, db_task: models.Task, task: schemas.TaskUpdate):
    update_data = task.dict(exclude_unset=True, exclude={"labels"})
    for field, value in update_data.items():
        setattr(db_task, field, value)
    if task.labels is not None:
        _sync_task_labels(db, db_task, task.labels, owner_id=db_task.owner_id)
    db.commit()
    db.refresh(db_task)
    return db_task


def delete_task(db: Session, task_id: int):
    db_task = db.query(models.Task).filter(models.Task.id == task_id).first()
    if db_task:
        db.delete(db_task)
        db.commit()
    return db_task

def get_events_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return (
        db.query(models.Event)
        .options(joinedload(models.Event.shares).joinedload(models.EventShare.user))
        .filter(models.Event.owner_id == user_id)
        .offset(skip)
        .limit(limit)
        .all()
    )

def get_event(db: Session, event_id: int) -> Optional[models.Event]:
    return (
        db.query(models.Event)
        .options(joinedload(models.Event.shares).joinedload(models.EventShare.user))
        .filter(models.Event.id == event_id)
        .first()
    )

def create_user_event(db: Session, event: schemas.EventCreate, user_id: int):
    payload = event.dict(exclude={"shared_with"})
    db_event = models.Event(**payload, owner_id=user_id)
    db.add(db_event)
    db.flush()

    # Sync shares if provided
    shared_with = getattr(event, "shared_with", []) or []
    if shared_with:
        sync_event_shares(db, db_event, shared_with)

    db.commit()
    db.refresh(db_event)
    return db_event

def sync_event_shares(db: Session, event: models.Event, shared_usernames: List[str]):
    """
    Sync event shares to match the provided username list.
    Raises ValueError if any username is unknown.
    """
    normalized = [u.strip() for u in shared_usernames if u and u.strip()]
    if normalized:
        users = db.query(models.User).filter(models.User.username.in_(normalized)).all()
        found = {u.username for u in users}
        missing = sorted(set(normalized) - found)
        if missing:
            raise ValueError(f"Unknown users: {', '.join(missing)}")
    else:
        users = []

    current = {share.user.username for share in event.shares}
    target = {u.username for u in users}

    # Remove stale shares
    for share in list(event.shares):
        if share.user.username not in target:
            db.delete(share)

    # Add new shares
    for user in users:
        if user.username not in current:
            event.shares.append(models.EventShare(user=user))

    db.flush()
    return event

def get_shared_events_for_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    return (
        db.query(models.Event)
        .join(models.EventShare, models.EventShare.event_id == models.Event.id)
        .options(joinedload(models.Event.shares).joinedload(models.EventShare.user))
        .filter(models.EventShare.user_id == user_id)
        .offset(skip)
        .limit(limit)
        .all()
    )

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


# Memories
def _load_memory(db: Session, memory_id: int) -> Optional[models.Memory]:
    return (
        db.query(models.Memory)
        .options(joinedload(models.Memory.shares).joinedload(models.MemoryShare.user))
        .filter(models.Memory.id == memory_id)
        .first()
    )

def list_memories(db: Session, user_id: int, shared_with: Optional[str] = None):
    """
    Return memories owned by user or shared with user. Optional filter for a specific username in shared_with.
    """
    query = (
        db.query(models.Memory)
        .options(joinedload(models.Memory.shares).joinedload(models.MemoryShare.user))
        .outerjoin(models.MemoryShare, models.MemoryShare.memory_id == models.Memory.id)
        .filter(
            or_(
                models.Memory.owner_id == user_id,
                models.MemoryShare.user_id == user_id,
            )
        )
    )
    if shared_with:
        query = query.join(models.User, models.User.id == models.MemoryShare.user_id).filter(
            models.User.username == shared_with
        )
    return query.order_by(models.Memory.created_at.desc()).all()

def create_memory(db: Session, owner_id: int, payload: schemas.MemoryCreate):
    data = payload.dict(exclude={"shared_with"})
    memory = models.Memory(owner_id=owner_id, **data)
    db.add(memory)
    db.flush()
    sync_memory_shares(db, memory, payload.shared_with)
    db.commit()
    db.refresh(memory)
    return memory

def update_memory(db: Session, memory: models.Memory, payload: schemas.MemoryUpdate):
    update_data = payload.dict(exclude_unset=True, exclude={"shared_with"})
    for key, value in update_data.items():
        setattr(memory, key, value)
    if payload.shared_with is not None:
        sync_memory_shares(db, memory, payload.shared_with)
    db.add(memory)
    db.commit()
    db.refresh(memory)
    return memory

def delete_memory(db: Session, memory: models.Memory):
    db.delete(memory)
    db.commit()

def sync_memory_shares(db: Session, memory: models.Memory, shared_usernames: List[str]):
    normalized = [u.strip() for u in shared_usernames if u and u.strip()]
    if normalized:
        users = db.query(models.User).filter(models.User.username.in_(normalized)).all()
        found = {u.username for u in users}
        missing = sorted(set(normalized) - found)
        if missing:
            raise ValueError(f"Unknown users: {', '.join(missing)}")
    else:
        users = []

    current = {share.user.username for share in memory.shares}
    target = {u.username for u in users}

    for share in list(memory.shares):
        if share.user.username not in target:
            db.delete(share)
    for user in users:
        if user.username not in current:
            memory.shares.append(models.MemoryShare(user=user))
    db.flush()
    return memory


# Goals
def _load_goal(db: Session, goal_id: int) -> Optional[models.Goal]:
    return (
        db.query(models.Goal)
        .options(
            joinedload(models.Goal.shares).joinedload(models.GoalShare.user),
            joinedload(models.Goal.milestones),
        )
        .filter(models.Goal.id == goal_id)
        .first()
    )

def list_goals(db: Session, user_id: int, shared_with: Optional[str] = None):
    query = (
        db.query(models.Goal)
        .options(
            joinedload(models.Goal.shares).joinedload(models.GoalShare.user),
            joinedload(models.Goal.milestones),
        )
        .outerjoin(models.GoalShare, models.GoalShare.goal_id == models.Goal.id)
        .filter(
            or_(
                models.Goal.owner_id == user_id,
                models.GoalShare.user_id == user_id,
            )
        )
    )
    if shared_with:
        query = query.join(models.User, models.User.id == models.GoalShare.user_id).filter(
            models.User.username == shared_with
        )
    return query.order_by(models.Goal.created_at.desc()).all()

def create_goal(db: Session, owner_id: int, payload: schemas.GoalCreate):
    goal = models.Goal(
        title=payload.title,
        description=payload.description,
        owner_id=owner_id,
        progress=0.0,
    )
    db.add(goal)
    db.flush()
    sync_goal_shares(db, goal, payload.shared_with)
    db.commit()
    db.refresh(goal)
    return goal

def update_goal_progress(db: Session, goal: models.Goal, progress: float):
    goal.progress = max(0.0, min(progress, 1.0))
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal

def add_milestone(db: Session, goal: models.Goal, payload: schemas.MilestoneCreate):
    milestone = models.Milestone(
        goal_id=goal.id,
        title=payload.title,
        description=payload.description,
        completed=False,
    )
    db.add(milestone)
    db.commit()
    db.refresh(milestone)
    return milestone

def sync_goal_shares(db: Session, goal: models.Goal, shared_usernames: List[str]):
    normalized = [u.strip() for u in shared_usernames if u and u.strip()]
    if normalized:
        users = db.query(models.User).filter(models.User.username.in_(normalized)).all()
        found = {u.username for u in users}
        missing = sorted(set(normalized) - found)
        if missing:
            raise ValueError(f"Unknown users: {', '.join(missing)}")
    else:
        users = []

    current = {share.user.username for share in goal.shares}
    target = {u.username for u in users}

    for share in list(goal.shares):
        if share.user.username not in target:
            db.delete(share)
    for user in users:
        if user.username not in current:
            goal.shares.append(models.GoalShare(user=user))
    db.flush()
    return goal

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
    existing = {preset.name for preset in db.query(models.LayoutPreset).filter(models.LayoutPreset.is_system == True).all()}
    created = False
    for entry in DEFAULT_LAYOUT_PRESETS:
        if entry["name"] in existing:
            continue
        db_preset = models.LayoutPreset(
            name=entry["name"],
            description=entry.get("description"),
            layout=entry["layout"],
            is_system=True,
            owner_id=None,
        )
        db.add(db_preset)
        created = True
    if created:
        db.commit()

def create_layout_preset(db: Session, preset: schemas.LayoutPresetCreate, owner_id: int):
    layout_payload = [column.dict() for column in preset.layout]
    db_preset = models.LayoutPreset(
        name=preset.name,
        description=preset.description,
        layout=layout_payload,
        is_system=False,
        owner_id=owner_id,
    )
    db.add(db_preset)
    db.commit()
    db.refresh(db_preset)
    return db_preset

def update_layout_preset(db: Session, db_preset: models.LayoutPreset, preset: schemas.LayoutPresetBase):
    db_preset.name = preset.name
    db_preset.description = preset.description
    db_preset.layout = [column.dict() for column in preset.layout]
    db.add(db_preset)
    db.commit()
    db.refresh(db_preset)
    return db_preset

def delete_layout_preset(db: Session, preset_id: int):
    db.query(models.LayoutPreset).filter(models.LayoutPreset.id == preset_id).delete()
    db.commit()

def create_conversation(
    db: Session,
    payload: schemas.ConversationCreate,
    owner_id: int,
    participant_ids: Optional[List[int]] = None,
):
    conversation = models.Conversation(
        title=payload.title,
        owner_id=owner_id,
        mode=payload.mode,
        with_ai=payload.with_ai,
        default_model_id=payload.default_model_id,
    )
    db.add(conversation)
    db.flush()

    all_participants = set(participant_ids or [])
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
        .options(
            joinedload(models.Conversation.participants).joinedload(models.ConversationParticipant.user),
            joinedload(models.Conversation.messages),
        )
        .join(models.ConversationParticipant)
        .filter(models.ConversationParticipant.user_id == user_id)
        .order_by(models.Conversation.updated_at.desc())
        .all()
    )

def get_conversation_for_user(db: Session, conversation_id: int, user_id: int):
    return (
        db.query(models.Conversation)
        .options(
            joinedload(models.Conversation.participants).joinedload(models.ConversationParticipant.user),
            joinedload(models.Conversation.messages),
        )
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
    author_id: Optional[int],
    author_type: str = "user",
    model_used: Optional[str] = None,
    extras: Optional[dict] = None,
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


def create_embedding(db: Session, owner_id: int, source: str, source_id: int, embedding: List[float], model_identifier: str):
    db_embedding = models.Embedding(
        owner_id=owner_id,
        source=source,
        source_id=source_id,
        embedding=embedding,
        model_identifier=model_identifier,
    )
    db.add(db_embedding)
    db.commit()
    db.refresh(db_embedding)
    return db_embedding


def get_similar_embeddings(db: Session, owner_id: int, query_embedding: List[float], limit: int = 5):
    import numpy as np

    all_embeddings = db.query(models.Embedding).filter(models.Embedding.owner_id == owner_id).all()
    
    query_vector = np.array(query_embedding)
    
    similarities = []
    for emb in all_embeddings:
        db_vector = np.array(emb.embedding)
        cosine_similarity = np.dot(query_vector, db_vector) / (np.linalg.norm(query_vector) * np.linalg.norm(db_vector))
        similarities.append((cosine_similarity, emb))
        
    similarities.sort(key=lambda x: x[0], reverse=True)
    
    return [emb for _, emb in similarities[:limit]]

# AI Provider Credentials
def _get_default_provider_config(db: Session, provider_type: str, owner_id: Optional[int] = None):
    query = db.query(models.AIProviderConfig).filter(
        models.AIProviderConfig.provider_type == provider_type,
        models.AIProviderConfig.is_default == True,
    )
    if owner_id:
        query = query.filter(models.AIProviderConfig.owner_id == owner_id)
    return query.first()


def set_provider_credentials(
    db: Session,
    *,
    owner_id: int,
    provider_type: str,
    api_key: str,
    model: Optional[str] = None,
    key_name: Optional[str] = None,
):
    """
    Store or update provider credentials (encrypted) and mark them as default for the owner.
    """
    provider = provider_type.lower().strip()
    encrypted = encrypt_api_key(api_key.strip())
    display_name = key_name or f"{provider}-default"

    # Reuse an existing default config if present; otherwise, reuse any config for this provider/owner
    config = _get_default_provider_config(db, provider, owner_id=owner_id)
    if config is None:
        config = (
            db.query(models.AIProviderConfig)
            .filter(
                models.AIProviderConfig.provider_type == provider,
                models.AIProviderConfig.owner_id == owner_id,
            )
            .first()
        )
    api_key_row = config.api_key if config else None

    # Deactivate other defaults for this provider/owner
    deactivate_q = db.query(models.AIProviderConfig).filter(
        models.AIProviderConfig.provider_type == provider,
        models.AIProviderConfig.owner_id == owner_id,
    )
    if config and config.id:
        deactivate_q = deactivate_q.filter(models.AIProviderConfig.id != config.id)
    deactivate_q.update({"is_default": False})

    if config is None:
        api_key_row = models.APIKey(
            owner_id=owner_id,
            provider=provider,
            key_name=display_name,
            encrypted_key=encrypted,
            is_active=True,
        )
        db.add(api_key_row)
        db.flush()
        config = models.AIProviderConfig(
            owner_id=owner_id,
            provider_type=provider,
            is_default=True,
            config={"model": model} if model else {},
            api_key_id=api_key_row.id,
        )
        db.add(config)
    else:
        if api_key_row:
            api_key_row.encrypted_key = encrypted
            api_key_row.key_name = display_name
            api_key_row.is_active = True
            api_key_row.provider = provider
        else:
            api_key_row = models.APIKey(
                owner_id=owner_id,
                provider=provider,
                key_name=display_name,
                encrypted_key=encrypted,
                is_active=True,
            )
            db.add(api_key_row)
            db.flush()
            config.api_key_id = api_key_row.id

        config.is_default = True
        existing_config = config.config or {}
        if model:
            existing_config["model"] = model
        config.config = existing_config

    db.commit()
    db.refresh(config)
    return config


def get_provider_secret(
    db: Session, provider_type: str, owner_id: Optional[int] = None
) -> Optional[dict]:
    """
    Return decrypted credentials for the default provider config.
    """
    config = _get_default_provider_config(db, provider_type.lower(), owner_id=owner_id)
    if not config or not config.api_key_id:
        return None

    api_key = db.query(models.APIKey).filter(models.APIKey.id == config.api_key_id).first()
    if not api_key or not api_key.is_active:
        return None

    try:
        decrypted = decrypt_api_key(api_key.encrypted_key)
    except Exception:
        return None
    return {
        "provider": provider_type.lower(),
        "api_key": decrypted,
        "model": (config.config or {}).get("model"),
        "key_name": api_key.key_name,
    }


def list_provider_credentials(db: Session, owner_id: Optional[int] = None):
    """
    Return masked credentials for UI display.
    """
    providers = ["openai", "gemini"]
    results = []
    for provider in providers:
        config = _get_default_provider_config(db, provider, owner_id=owner_id)
        api_key = None
        if config and config.api_key_id:
            api_key = db.query(models.APIKey).filter(models.APIKey.id == config.api_key_id).first()

        has_key = bool(api_key and api_key.is_active)
        masked = None
        key_name = None
        if api_key and api_key.is_active:
            try:
                if api_key.encrypted_key:
                    masked = mask_api_key(decrypt_api_key(api_key.encrypted_key))
                key_name = api_key.key_name
            except Exception as e:
                # If decryption fails, just mark as having a key but don't show masked value
                print(f"Warning: Failed to decrypt/mask API key for {provider}: {e}")
                masked = None
                key_name = api_key.key_name
            has_key = True

        results.append(
            {
                "provider": provider,
                "key_name": key_name,
                "has_key": has_key,
                "masked_key": masked,
                "model": (config.config or {}).get("model") if config else None,
            }
        )

    return results


# Finance helpers
def get_finance_accounts(db: Session, owner_id: int):
    return (
        db.query(models.FinanceAccount)
        .filter(models.FinanceAccount.owner_id == owner_id)
        .order_by(models.FinanceAccount.created_at.asc())
        .all()
    )


def get_finance_account(db: Session, owner_id: int, account_id: int):
    return (
        db.query(models.FinanceAccount)
        .filter(
            models.FinanceAccount.owner_id == owner_id,
            models.FinanceAccount.id == account_id,
        )
        .first()
    )


def create_finance_account(db: Session, owner_id: int, payload: schemas.FinanceAccountCreate):
    db_account = models.FinanceAccount(
        owner_id=owner_id,
        **payload.dict(),
    )
    db.add(db_account)
    db.commit()
    db.refresh(db_account)
    return db_account


def update_finance_account(
    db: Session,
    db_account: models.FinanceAccount,
    payload: schemas.FinanceAccountUpdate,
):
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(db_account, field, value)
    db.add(db_account)
    db.commit()
    db.refresh(db_account)
    return db_account


def delete_finance_account(db: Session, db_account: models.FinanceAccount):
    db.delete(db_account)
    db.commit()


def list_finance_transactions(
    db: Session,
    owner_id: int,
    account_id: Optional[int] = None,
    limit: int = 50,
):
    query = db.query(models.FinanceTransaction).filter(models.FinanceTransaction.owner_id == owner_id)
    if account_id:
        query = query.filter(models.FinanceTransaction.account_id == account_id)
    return (
        query.order_by(models.FinanceTransaction.transaction_date.desc())
        .limit(limit)
        .all()
    )


def create_finance_transaction(
    db: Session,
    owner_id: int,
    payload: schemas.FinanceTransactionCreate,
):
    db_tx = models.FinanceTransaction(
        owner_id=owner_id,
        **payload.dict(exclude_unset=True),
    )
    if db_tx.transaction_date is None:
        db_tx.transaction_date = func.now()
    db.add(db_tx)

    # Update account balance heuristically
    account = (
        db.query(models.FinanceAccount)
        .filter(
            models.FinanceAccount.owner_id == owner_id,
            models.FinanceAccount.id == db_tx.account_id,
        )
        .first()
    )
    if account:
        sign = 1 if db_tx.transaction_type == "credit" else -1
        account.balance = (account.balance or 0.0) + (db_tx.amount or 0.0) * sign
        db.add(account)

    db.commit()
    db.refresh(db_tx)
    return db_tx


def get_finance_budgets(db: Session, owner_id: int):
    return (
        db.query(models.FinanceBudget)
        .filter(models.FinanceBudget.owner_id == owner_id)
        .order_by(models.FinanceBudget.created_at.asc())
        .all()
    )


def get_finance_budget(db: Session, owner_id: int, budget_id: int):
    return (
        db.query(models.FinanceBudget)
        .filter(
            models.FinanceBudget.owner_id == owner_id,
            models.FinanceBudget.id == budget_id,
        )
        .first()
    )


def create_finance_budget(db: Session, owner_id: int, payload: schemas.FinanceBudgetCreate):
    db_budget = models.FinanceBudget(owner_id=owner_id, **payload.dict())
    db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget


def update_finance_budget(
    db: Session,
    db_budget: models.FinanceBudget,
    payload: schemas.FinanceBudgetUpdate,
):
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(db_budget, field, value)
    db.add(db_budget)
    db.commit()
    db.refresh(db_budget)
    return db_budget


def delete_finance_budget(db: Session, db_budget: models.FinanceBudget):
    db.delete(db_budget)
    db.commit()


def get_budget_period_dates(period: str, reference_date: Optional[datetime] = None):
    """
    Calculate start and end dates for a budget period.
    Returns (start_date, end_date) tuple.
    """
    from datetime import timedelta
    from calendar import monthrange

    if reference_date is None:
        reference_date = datetime.utcnow()

    if period == "weekly":
        # Start of current week (Monday)
        start = reference_date - timedelta(days=reference_date.weekday())
        start = start.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=6, hours=23, minutes=59, seconds=59)
    elif period == "monthly":
        # Start of current month
        start = reference_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        _, last_day = monthrange(reference_date.year, reference_date.month)
        end = reference_date.replace(day=last_day, hour=23, minute=59, second=59, microsecond=999999)
    elif period == "quarterly":
        # Start of current quarter
        quarter_month = ((reference_date.month - 1) // 3) * 3 + 1
        start = reference_date.replace(month=quarter_month, day=1, hour=0, minute=0, second=0, microsecond=0)
        end_month = quarter_month + 2
        _, last_day = monthrange(reference_date.year, end_month)
        end = reference_date.replace(month=end_month, day=last_day, hour=23, minute=59, second=59, microsecond=999999)
    elif period == "yearly":
        # Start of current year
        start = reference_date.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        end = reference_date.replace(month=12, day=31, hour=23, minute=59, second=59, microsecond=999999)
    else:
        # Default to monthly
        start = reference_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        _, last_day = monthrange(reference_date.year, reference_date.month)
        end = reference_date.replace(day=last_day, hour=23, minute=59, second=59, microsecond=999999)

    return start, end


def calculate_budget_spent(
    db: Session,
    owner_id: int,
    category: str,
    start_date: datetime,
    end_date: datetime,
) -> tuple:
    """
    Calculate total spent for a category within a date range.
    Returns (total_spent, transaction_count, last_transaction_date).
    """
    transactions = (
        db.query(models.FinanceTransaction)
        .filter(
            models.FinanceTransaction.owner_id == owner_id,
            models.FinanceTransaction.category == category,
            models.FinanceTransaction.transaction_type == "debit",
            models.FinanceTransaction.transaction_date >= start_date,
            models.FinanceTransaction.transaction_date <= end_date,
        )
        .order_by(models.FinanceTransaction.transaction_date.desc())
        .all()
    )

    total_spent = sum(tx.amount or 0.0 for tx in transactions)
    transaction_count = len(transactions)
    last_transaction_date = transactions[0].transaction_date if transactions else None

    return total_spent, transaction_count, last_transaction_date


def get_budget_progress(
    db: Session,
    owner_id: int,
    budget_id: Optional[int] = None,
    period: Optional[str] = None,
) -> List[schemas.BudgetProgress]:
    """
    Calculate budget progress for one or all budgets.
    Calculates spent amount from transactions in the current period.
    """
    query = db.query(models.FinanceBudget).filter(
        models.FinanceBudget.owner_id == owner_id,
        models.FinanceBudget.is_active == True,
    )

    if budget_id:
        query = query.filter(models.FinanceBudget.id == budget_id)

    budgets = query.all()
    progress_list = []

    for budget in budgets:
        # Determine date range for budget period
        budget_period = period or budget.period

        if budget.start_date and budget.end_date:
            start_date, end_date = budget.start_date, budget.end_date
        else:
            start_date, end_date = get_budget_period_dates(budget_period)

        # Calculate spent from transactions
        spent, tx_count, last_tx_date = calculate_budget_spent(
            db, owner_id, budget.category, start_date, end_date
        )

        # Calculate progress metrics
        limit = budget.limit_amount or 1.0  # Avoid division by zero
        remaining = max(0.0, limit - spent)
        percent_used = min((spent / limit) * 100, 100.0) if limit > 0 else 0.0

        # Check alert conditions
        is_over_budget = spent > limit
        is_at_alert = percent_used >= (budget.alert_threshold or 0.8) * 100

        # Calculate goal progress if goal is set
        goal_progress = None
        if budget.goal_amount and budget.goal_amount > 0:
            goal_progress = min((spent / budget.goal_amount) * 100, 100.0)

        progress = schemas.BudgetProgress(
            id=budget.id,
            budget_id=budget.id,
            name=budget.name,
            category=budget.category,
            limit_amount=budget.limit_amount,
            spent=spent,
            remaining=remaining,
            percent_used=round(percent_used, 2),
            period=budget_period,
            start_date=start_date,
            end_date=end_date,
            is_over_budget=is_over_budget,
            is_at_alert_threshold=is_at_alert,
            goal_amount=budget.goal_amount,
            goal_progress=round(goal_progress, 2) if goal_progress else None,
            emoji=budget.emoji,
            color_hex=budget.color_hex,
            transactions_count=tx_count,
            last_transaction_date=last_tx_date,
        )
        progress_list.append(progress)

    return progress_list


def get_budget_progress_summary(
    db: Session,
    owner_id: int,
    period: str = "monthly",
) -> schemas.BudgetProgressSummary:
    """
    Get aggregated budget progress summary for all budgets.
    """
    progress_list = get_budget_progress(db, owner_id, period=period)

    total_budgeted = sum(p.limit_amount for p in progress_list)
    total_spent = sum(p.spent for p in progress_list)
    total_remaining = sum(p.remaining for p in progress_list)
    overall_percent = (total_spent / total_budgeted * 100) if total_budgeted > 0 else 0.0

    budgets_over_limit = sum(1 for p in progress_list if p.is_over_budget)
    budgets_at_alert = sum(1 for p in progress_list if p.is_at_alert_threshold and not p.is_over_budget)

    return schemas.BudgetProgressSummary(
        budgets=progress_list,
        total_budgeted=total_budgeted,
        total_spent=total_spent,
        total_remaining=total_remaining,
        overall_percent_used=round(overall_percent, 2),
        period=period,
        budgets_over_limit=budgets_over_limit,
        budgets_at_alert=budgets_at_alert,
    )


def update_budget_spent_amount(db: Session, owner_id: int, budget_id: int) -> Optional[models.FinanceBudget]:
    """
    Recalculate and update the spent_amount field for a budget.
    This syncs the denormalized spent_amount with actual transactions.
    """
    budget = get_finance_budget(db, owner_id, budget_id)
    if not budget:
        return None

    if budget.start_date and budget.end_date:
        start_date, end_date = budget.start_date, budget.end_date
    else:
        start_date, end_date = get_budget_period_dates(budget.period)

    spent, _, _ = calculate_budget_spent(db, owner_id, budget.category, start_date, end_date)

    budget.spent_amount = spent
    db.add(budget)
    db.commit()
    db.refresh(budget)
    return budget


def sync_all_budget_spent_amounts(db: Session, owner_id: int) -> List[models.FinanceBudget]:
    """
    Sync spent_amount for all active budgets.
    """
    budgets = db.query(models.FinanceBudget).filter(
        models.FinanceBudget.owner_id == owner_id,
        models.FinanceBudget.is_active == True,
    ).all()

    for budget in budgets:
        update_budget_spent_amount(db, owner_id, budget.id)

    return budgets


def get_finance_summary(db: Session, owner_id: int):
    try:
        # Get accounts, budgets, and transactions with error handling
        accounts = get_finance_accounts(db, owner_id) or []
        budgets = get_finance_budgets(db, owner_id) or []
        transactions = list_finance_transactions(db, owner_id, limit=10) or []

        # Calculate total balance with null checks
        total_balance = 0.0
        if accounts:
            total_balance = sum(
                float(account.balance) if account.balance is not None else 0.0
                for account in accounts
            )

        # Calculate monthly spending with null checks
        monthly_spending = 0.0
        if transactions:
            monthly_spending = sum(
                float(tx.amount) if tx.amount is not None and tx.transaction_type == "debit" else 0.0
                for tx in transactions
            )

        # Calculate monthly income with null checks
        monthly_income = 0.0
        if transactions:
            monthly_income = sum(
                float(tx.amount) if tx.amount is not None and tx.transaction_type == "credit" else 0.0
                for tx in transactions
            )

        return schemas.FinanceSummary(
            total_balance=total_balance,
            active_accounts=len(accounts),
            monthly_spending=monthly_spending,
            monthly_income=monthly_income,
            budget_progress=budgets,
            recent_transactions=transactions,
        )
    except Exception as e:
        # Log error and return default summary
        import logging
        logging.error(f"Error getting finance summary for user {owner_id}: {str(e)}")
        # Return empty summary instead of raising exception
        return schemas.FinanceSummary(
            total_balance=0.0,
            active_accounts=0,
            monthly_spending=0.0,
            monthly_income=0.0,
            budget_progress=[],
            recent_transactions=[],
        )


def _generate_invite_code() -> str:
    return secrets.token_hex(3).upper()


def create_social_circle(db: Session, owner_id: int, payload: schemas.SocialCircleCreate):
    invite_code = _generate_invite_code()
    db_circle = models.SocialCircle(
        owner_id=owner_id,
        invite_code=invite_code,
        **payload.dict(exclude_unset=True),
    )
    db.add(db_circle)
    db.flush()

    membership = models.SocialCircleMember(circle_id=db_circle.id, user_id=owner_id, role="owner")
    db.add(membership)
    db.commit()
    db.refresh(db_circle)
    return db_circle


def list_social_circles(db: Session, owner_id: int):
    circles = (
        db.query(models.SocialCircle)
        .join(models.SocialCircleMember)
        .filter(models.SocialCircleMember.user_id == owner_id)
        .order_by(models.SocialCircle.created_at.asc())
        .all()
    )
    for circle in circles:
        circle.member_count = len(circle.members)
    return circles


def get_social_circle(db: Session, owner_id: int, circle_id: int):
    return (
        db.query(models.SocialCircle)
        .join(models.SocialCircleMember)
        .filter(
            models.SocialCircle.id == circle_id,
            models.SocialCircleMember.user_id == owner_id,
        )
        .first()
    )


def join_social_circle(db: Session, owner_id: int, invite_code: str):
    circle = (
        db.query(models.SocialCircle)
        .filter(models.SocialCircle.invite_code == invite_code)
        .first()
    )
    if not circle:
        return None
    existing = (
        db.query(models.SocialCircleMember)
        .filter(
            models.SocialCircleMember.circle_id == circle.id,
            models.SocialCircleMember.user_id == owner_id,
        )
        .first()
    )
    if existing:
        return circle
    membership = models.SocialCircleMember(circle_id=circle.id, user_id=owner_id, role="member")
    db.add(membership)
    db.commit()
    return circle


def list_social_pulses(db: Session, owner_id: int, circle_id: int, limit: int = 25):
    circle = get_social_circle(db, owner_id, circle_id)
    if not circle:
        return []
    pulses = (
        db.query(models.SocialPulse)
        .filter(models.SocialPulse.circle_id == circle_id)
        .order_by(models.SocialPulse.created_at.desc())
        .limit(limit)
        .all()
    )
    for pulse in pulses:
        pulse.author_name = pulse.author.full_name or pulse.author.username
    return pulses


def create_social_pulse(
    db: Session,
    owner_id: int,
    circle_id: int,
    payload: schemas.SocialPulseCreate,
):
    circle = get_social_circle(db, owner_id, circle_id)
    if not circle:
        return None
    db_pulse = models.SocialPulse(
        circle_id=circle_id,
        author_id=owner_id,
        **payload.dict(),
    )
    db.add(db_pulse)
    db.commit()
    db.refresh(db_pulse)
    db_pulse.author_name = db_pulse.author.full_name or db_pulse.author.username
    return db_pulse


# Presence helpers
def upsert_user_presence(db: Session, user_id: int, update: schemas.PresenceUpdate) -> models.UserPresence:
    presence = db.query(models.UserPresence).filter(models.UserPresence.user_id == user_id).first()
    if not presence:
        presence = models.UserPresence(user_id=user_id)

    if update.is_online is not None:
        presence.is_online = update.is_online
    if update.status is not None:
        presence.status = update.status
        # Update is_online based on status for compatibility
        presence.is_online = update.status != "offline"
    presence.current_activity = update.current_activity
    presence.status_message = update.status_message
    presence.last_seen = datetime.utcnow()

    db.add(presence)
    db.commit()
    db.refresh(presence)
    return presence


def get_user_presence(db: Session, user_id: int) -> Optional[models.UserPresence]:
    return db.query(models.UserPresence).filter(models.UserPresence.user_id == user_id).first()


def get_multiple_user_presences(db: Session, user_ids: List[int]) -> List[models.UserPresence]:
    """Get presence information for multiple users."""
    return db.query(models.UserPresence).filter(models.UserPresence.user_id.in_(user_ids)).all()


def delete_user_account(db: Session, user_id: int) -> None:
    """
    Delete a user account and all associated data.
    This is a cascading delete that removes:
    - User presence
    - Tasks
    - Events
    - Pages and page shares
    - Conversations and messages
    - Finance accounts, transactions, budgets
    - Social circle memberships
    - AI provider configs and API keys
    - And the user record itself
    """
    # Delete user presence
    db.query(models.UserPresence).filter(models.UserPresence.user_id == user_id).delete()

    # Delete tasks and their label associations
    tasks = db.query(models.Task).filter(models.Task.owner_id == user_id).all()
    for task in tasks:
        task.labels = []  # Clear many-to-many relationship
    db.query(models.Task).filter(models.Task.owner_id == user_id).delete()

    # Delete events and shares
    db.query(models.EventShare).filter(models.EventShare.user_id == user_id).delete()
    events = db.query(models.Event).filter(models.Event.owner_id == user_id).all()
    for event in events:
        db.query(models.EventShare).filter(models.EventShare.event_id == event.id).delete()
    db.query(models.Event).filter(models.Event.owner_id == user_id).delete()

    # Delete page shares
    db.query(models.PageShare).filter(models.PageShare.user_id == user_id).delete()
    pages = db.query(models.Page).filter(models.Page.owner_id == user_id).all()
    for page in pages:
        db.query(models.PageShare).filter(models.PageShare.page_id == page.id).delete()
    db.query(models.Page).filter(models.Page.owner_id == user_id).delete()

    # Delete conversations and messages
    conversations = db.query(models.Conversation).filter(models.Conversation.owner_id == user_id).all()
    for conv in conversations:
        db.query(models.ChatMessage).filter(models.ChatMessage.conversation_id == conv.id).delete()
        db.query(models.ConversationParticipant).filter(models.ConversationParticipant.conversation_id == conv.id).delete()
    db.query(models.Conversation).filter(models.Conversation.owner_id == user_id).delete()
    db.query(models.ConversationParticipant).filter(models.ConversationParticipant.user_id == user_id).delete()

    # Delete finance data
    db.query(models.FinanceTransaction).filter(models.FinanceTransaction.owner_id == user_id).delete()
    db.query(models.FinanceAccount).filter(models.FinanceAccount.owner_id == user_id).delete()
    db.query(models.FinanceBudget).filter(models.FinanceBudget.owner_id == user_id).delete()

    # Delete social circle memberships
    db.query(models.SocialCircleMember).filter(models.SocialCircleMember.user_id == user_id).delete()
    circles = db.query(models.SocialCircle).filter(models.SocialCircle.owner_id == user_id).all()
    for circle in circles:
        db.query(models.SocialPulse).filter(models.SocialPulse.circle_id == circle.id).delete()
        db.query(models.SocialCircleMember).filter(models.SocialCircleMember.circle_id == circle.id).delete()
    db.query(models.SocialCircle).filter(models.SocialCircle.owner_id == user_id).delete()

    # Delete memories and shares
    db.query(models.MemoryShare).filter(models.MemoryShare.user_id == user_id).delete()
    memories = db.query(models.Memory).filter(models.Memory.owner_id == user_id).all()
    for memory in memories:
        db.query(models.MemoryShare).filter(models.MemoryShare.memory_id == memory.id).delete()
    db.query(models.Memory).filter(models.Memory.owner_id == user_id).delete()

    # Delete goals and shares
    db.query(models.GoalShare).filter(models.GoalShare.user_id == user_id).delete()
    goals = db.query(models.Goal).filter(models.Goal.owner_id == user_id).all()
    for goal in goals:
        db.query(models.Milestone).filter(models.Milestone.goal_id == goal.id).delete()
        db.query(models.GoalShare).filter(models.GoalShare.goal_id == goal.id).delete()
    db.query(models.Goal).filter(models.Goal.owner_id == user_id).delete()

    # Delete labels
    db.query(models.Label).filter(models.Label.owner_id == user_id).delete()

    # Delete embeddings
    db.query(models.Embedding).filter(models.Embedding.owner_id == user_id).delete()

    # Delete AI provider configs and API keys
    configs = db.query(models.AIProviderConfig).filter(models.AIProviderConfig.owner_id == user_id).all()
    for config in configs:
        if config.api_key_id:
            db.query(models.APIKey).filter(models.APIKey.id == config.api_key_id).delete()
    db.query(models.AIProviderConfig).filter(models.AIProviderConfig.owner_id == user_id).delete()
    db.query(models.APIKey).filter(models.APIKey.owner_id == user_id).delete()

    # Delete AI client nodes
    db.query(models.AIClientNode).filter(models.AIClientNode.owner_id == user_id).delete()

    # Delete layout presets owned by the user
    db.query(models.LayoutPreset).filter(models.LayoutPreset.owner_id == user_id).delete()

    # Finally, delete the user
    db.query(models.User).filter(models.User.id == user_id).delete()

    db.commit()