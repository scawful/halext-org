from sqlalchemy.orm import Session
from sqlalchemy import or_
from sqlalchemy.sql import func
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

def create_conversation(db: Session, owner_id: int, payload: schemas.ConversationCreate, participant_ids: List[int]):
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

        masked = None
        key_name = None
        if api_key and api_key.is_active:
            try:
                masked = mask_api_key(decrypt_api_key(api_key.encrypted_key))
                key_name = api_key.key_name
            except Exception:
                masked = None
                key_name = api_key.key_name

        results.append(
            {
                "provider": provider,
                "key_name": key_name,
                "has_key": bool(masked),
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


def get_finance_summary(db: Session, owner_id: int):
    accounts = get_finance_accounts(db, owner_id)
    budgets = get_finance_budgets(db, owner_id)
    transactions = list_finance_transactions(db, owner_id, limit=10)

    total_balance = sum(account.balance or 0.0 for account in accounts)
    monthly_spending = sum(
        tx.amount or 0.0 for tx in transactions if tx.transaction_type == "debit"
    )
    monthly_income = sum(
        tx.amount or 0.0 for tx in transactions if tx.transaction_type == "credit"
    )

    return schemas.FinanceSummary(
        total_balance=total_balance,
        active_accounts=len(accounts),
        monthly_spending=monthly_spending,
        monthly_income=monthly_income,
        budget_progress=budgets,
        recent_transactions=transactions,
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
