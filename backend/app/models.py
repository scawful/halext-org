from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, JSON, Table, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

task_labels_table = Table(
    "task_labels",
    Base.metadata,
    Column("task_id", ForeignKey("tasks.id"), primary_key=True),
    Column("label_id", ForeignKey("labels.id"), primary_key=True),
)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    tasks = relationship("Task", back_populates="owner")
    events = relationship("Event", back_populates="owner")
    shared_events = relationship("EventShare", back_populates="user")
    pages = relationship("Page", back_populates="owner")
    shared_pages = relationship("PageShare", back_populates="user")
    conversations = relationship("ConversationParticipant", back_populates="user")
    labels = relationship("Label", back_populates="owner")
    api_keys = relationship("APIKey", back_populates="owner", cascade="all, delete-orphan")
    presence = relationship("UserPresence", back_populates="user", uselist=False, cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(username='{self.username}', email='{self.email}')>"


class APIKey(Base):
    """API keys for external AI providers (OpenAI, Gemini, etc.)"""
    __tablename__ = "api_keys"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider = Column(String, nullable=False)  # 'openai', 'gemini', 'ollama'
    key_name = Column(String, nullable=False)  # User-friendly name
    encrypted_key = Column(String, nullable=False)  # Encrypted API key
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_used_at = Column(DateTime(timezone=True), nullable=True)

    owner = relationship("User", back_populates="api_keys")

    def __repr__(self):
        return f"<APIKey(provider='{self.provider}', name='{self.key_name}')>"


class AIProviderConfig(Base):
    """User-specific AI provider configurations"""
    __tablename__ = "ai_provider_configs"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider_type = Column(String, nullable=False)  # 'openai', 'gemini', 'ollama', 'openwebui'
    is_default = Column(Boolean, default=False)
    config = Column(JSON, nullable=False)  # Provider-specific config (model, base_url, etc.)
    api_key_id = Column(Integer, ForeignKey("api_keys.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User")
    api_key = relationship("APIKey")

    def __repr__(self):
        return f"<AIProviderConfig(provider='{self.provider_type}', default={self.is_default})>"


class AIClientNode(Base):
    """AI client nodes (Ollama instances, OpenWebUI instances, etc.)"""
    __tablename__ = "ai_client_nodes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)  # User-friendly name: "Mac Studio", "Windows PC"
    node_type = Column(String, nullable=False)  # 'ollama', 'openwebui', 'llama-cpp'
    hostname = Column(String, nullable=False)  # IP or hostname
    port = Column(Integer, default=11434)
    is_active = Column(Boolean, default=True)
    is_public = Column(Boolean, default=False)  # If true, available to all users
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Health tracking
    last_seen_at = Column(DateTime(timezone=True), nullable=True)
    status = Column(String, default="unknown")  # 'online', 'offline', 'error', 'unknown'

    # Capabilities
    capabilities = Column(JSON, default=dict)  # {"models": [...], "gpu": true, "memory_gb": 16}

    # Metadata
    node_metadata = Column(JSON, default=dict)  # OS, version, etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User")

    def __repr__(self):
        return f"<AIClientNode(name='{self.name}', type='{self.node_type}', status='{self.status}')>"

    @property
    def base_url(self):
        """Get the full base URL for this node"""
        return f"http://{self.hostname}:{self.port}"

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    description = Column(String, nullable=True)
    completed = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    due_date = Column(DateTime(timezone=True), nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="tasks")
    labels = relationship("Label", secondary=task_labels_table, back_populates="tasks")

class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    description = Column(String, nullable=True)
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    location = Column(String, nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"))
    recurrence_type = Column(String, default="none")
    recurrence_interval = Column(Integer, default=1)
    recurrence_end_date = Column(DateTime(timezone=True), nullable=True)

    owner = relationship("User", back_populates="events")
    shares = relationship("EventShare", back_populates="event", cascade="all, delete-orphan")


class EventShare(Base):
    """
    Event sharing links participants to events they can view (or edit in future).
    """
    __tablename__ = "event_shares"

    event_id = Column(Integer, ForeignKey("events.id"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    can_edit = Column(Boolean, default=False)

    event = relationship("Event", back_populates="shares")
    user = relationship("User", back_populates="shared_events")


class Memory(Base):
    __tablename__ = "memories"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(Text, nullable=True)
    photos = Column(JSON, default=list)
    location = Column(String, nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User")
    shares = relationship("MemoryShare", back_populates="memory", cascade="all, delete-orphan")


class MemoryShare(Base):
    __tablename__ = "memory_shares"

    memory_id = Column(Integer, ForeignKey("memories.id"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    can_edit = Column(Boolean, default=False)

    memory = relationship("Memory", back_populates="shares")
    user = relationship("User")


class Goal(Base):
    __tablename__ = "goals"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    progress = Column(Float, default=0.0)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User")
    milestones = relationship("Milestone", back_populates="goal", cascade="all, delete-orphan")
    shares = relationship("GoalShare", back_populates="goal", cascade="all, delete-orphan")


class GoalShare(Base):
    __tablename__ = "goal_shares"

    goal_id = Column(Integer, ForeignKey("goals.id"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    can_edit = Column(Boolean, default=False)

    goal = relationship("Goal", back_populates="shares")
    user = relationship("User")


class Milestone(Base):
    __tablename__ = "milestones"

    id = Column(Integer, primary_key=True, index=True)
    goal_id = Column(Integer, ForeignKey("goals.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    completed = Column(Boolean, default=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    goal = relationship("Goal", back_populates="milestones")

class Label(Base):
    __tablename__ = "labels"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    color = Column(String, default="#5d72ff")
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    owner = relationship("User", back_populates="labels")
    tasks = relationship("Task", secondary=task_labels_table, back_populates="labels")
    __table_args__ = (
        {"sqlite_autoincrement": True},
    )

class LayoutPreset(Base):
    __tablename__ = "layout_presets"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    layout = Column(JSON, nullable=False)
    is_system = Column(Boolean, default=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User")

class Page(Base):
    __tablename__ = "pages"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    visibility = Column(String, default="private")  # private, shared
    layout = Column(JSON, default=list)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User", back_populates="pages")
    shares = relationship("PageShare", back_populates="page", cascade="all, delete-orphan")

class PageShare(Base):
    __tablename__ = "page_shares"

    page_id = Column(Integer, ForeignKey("pages.id"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    can_edit = Column(Boolean, default=False)

    page = relationship("Page", back_populates="shares")
    user = relationship("User", back_populates="shared_pages")

class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    mode = Column(String, default="solo")  # solo, partner, group, hive_mind
    with_ai = Column(Boolean, default=True)
    default_model_id = Column(String, nullable=True)  # AI model to use for this conversation
    hive_mind_goal = Column(Text, nullable=True)  # Objective for the hive mind
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    messages = relationship("ChatMessage", back_populates="conversation", cascade="all, delete-orphan")
    participants = relationship("ConversationParticipant", back_populates="conversation", cascade="all, delete-orphan")

class ConversationParticipant(Base):
    __tablename__ = "conversation_participants"

    conversation_id = Column(Integer, ForeignKey("conversations.id"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    role = Column(String, default="member")  # member, owner

    conversation = relationship("Conversation", back_populates="participants")
    user = relationship("User", back_populates="conversations")

class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"), nullable=False, index=True)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    author_type = Column(String, default="user")  # user or ai
    content = Column(Text, nullable=False)
    model_used = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    extras = Column(JSON, default=dict)

    conversation = relationship("Conversation", back_populates="messages")
    author = relationship("User")


class UserPresence(Base):
    """
    Lightweight presence tracking for users (online/offline + activity).
    """
    __tablename__ = "user_presences"

    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    is_online = Column(Boolean, default=True)
    status = Column(String, default="online")  # online, away, busy, offline
    current_activity = Column(String, nullable=True)
    status_message = Column(String, nullable=True)
    last_seen = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="presence")


class SitePage(Base):
    __tablename__ = "site_pages"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String, unique=True, nullable=False, index=True)
    title = Column(String, nullable=False)
    summary = Column(Text, nullable=True)
    hero_image_url = Column(String, nullable=True)
    sections = Column(JSON, default=list)
    nav_links = Column(JSON, default=list)
    theme = Column(JSON, default=dict)
    is_published = Column(Boolean, default=False)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    updated_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User", foreign_keys=[owner_id], backref="site_pages")
    updated_by = relationship("User", foreign_keys=[updated_by_id])


class PhotoAlbum(Base):
    __tablename__ = "photo_albums"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String, unique=True, nullable=False, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    cover_image_url = Column(String, nullable=True)
    hero_text = Column(String, nullable=True)
    photos = Column(JSON, default=list)
    is_public = Column(Boolean, default=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User", backref="photo_albums")


class MediaAsset(Base):
    __tablename__ = "media_assets"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=True)
    file_path = Column(String, nullable=False)
    public_url = Column(String, nullable=False)
    thumbnail_url = Column(String, nullable=True)
    meta = Column(JSON, default=dict)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", backref="media_assets")


class BlogPost(Base):
    __tablename__ = "blog_posts"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String, unique=True, nullable=False, index=True)
    title = Column(String, nullable=False)
    summary = Column(Text, nullable=True)
    body_markdown = Column(Text, nullable=False)
    tags = Column(JSON, default=list)
    hero_image_url = Column(String, nullable=True)
    status = Column(String, default="draft")  # draft, published
    published_at = Column(DateTime(timezone=True), nullable=True)
    file_path = Column(String, nullable=True)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    author = relationship("User", backref="blog_posts")


class SiteSetting(Base):
    __tablename__ = "site_settings"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String, unique=True, nullable=False, index=True)
    value = Column(JSON, default=dict)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class AIUsageLog(Base):
    """Log of AI API usage for analytics and cost tracking"""
    __tablename__ = "ai_usage_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"), nullable=True, index=True)
    model_identifier = Column(String, nullable=False, index=True)  # e.g., "client:1:llama3.1"
    endpoint = Column(String, nullable=False)  # e.g., "/ai/chat", "/ai/tasks/suggest"
    prompt_tokens = Column(Integer, default=0)
    response_tokens = Column(Integer, default=0)
    total_tokens = Column(Integer, default=0)
    latency_ms = Column(Integer, nullable=True)  # Response time in milliseconds
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User")
    conversation = relationship("Conversation")

    def __repr__(self):
        return f"<AIUsageLog(user_id={self.user_id}, model='{self.model_identifier}', endpoint='{self.endpoint}')>"


class FinanceAccount(Base):
    __tablename__ = "finance_accounts"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    account_name = Column(String, nullable=False)
    account_type = Column(String, default="checking")
    institution_name = Column(String, nullable=True)
    account_number = Column(String, nullable=True)
    balance = Column(Float, default=0.0)
    currency = Column(String, default="USD")
    is_active = Column(Boolean, default=True)
    theme_emoji = Column(String, default="💳")
    accent_color = Column(String, default="#8B5CF6")
    plaid_account_id = Column(String, nullable=True)
    last_synced = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User", backref="finance_accounts")
    transactions = relationship(
        "FinanceTransaction",
        back_populates="account",
        cascade="all, delete-orphan",
    )


class FinanceTransaction(Base):
    __tablename__ = "finance_transactions"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    account_id = Column(Integer, ForeignKey("finance_accounts.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    description = Column(String, nullable=False)
    category = Column(String, default="other")
    transaction_type = Column(String, default="debit")
    transaction_date = Column(DateTime(timezone=True), server_default=func.now())
    merchant = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    tags = Column(JSON, default=list)
    mood_icon = Column(String, default="✨")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", backref="finance_transactions")
    account = relationship("FinanceAccount", back_populates="transactions")


class FinanceBudget(Base):
    __tablename__ = "finance_budgets"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    category = Column(String, default="general")
    limit_amount = Column(Float, nullable=False)
    spent_amount = Column(Float, default=0.0)
    period = Column(String, default="monthly")  # weekly, monthly, quarterly, yearly
    emoji = Column(String, default="🍰")
    color_hex = Column(String, default="#F472B6")
    # Budget period tracking
    start_date = Column(DateTime(timezone=True), nullable=True)
    end_date = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True)
    # Goal tracking
    goal_amount = Column(Float, nullable=True)  # Optional savings/spending goal
    rollover_enabled = Column(Boolean, default=False)  # Carry over unused budget
    alert_threshold = Column(Float, default=0.8)  # Alert when this % is reached
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    owner = relationship("User", backref="finance_budgets")


class SocialCircle(Base):
    __tablename__ = "social_circles"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    emoji = Column(String, default="🌈")
    theme_color = Column(String, default="#A855F7")
    vibe = Column(String, default="cozy")
    invite_code = Column(String, unique=True, index=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", backref="social_circles")
    members = relationship(
        "SocialCircleMember",
        back_populates="circle",
        cascade="all, delete-orphan",
    )
    pulses = relationship(
        "SocialPulse",
        back_populates="circle",
        cascade="all, delete-orphan",
    )


class SocialCircleMember(Base):
    __tablename__ = "social_circle_members"

    circle_id = Column(Integer, ForeignKey("social_circles.id"), primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    role = Column(String, default="member")
    joined_at = Column(DateTime(timezone=True), server_default=func.now())

    circle = relationship("SocialCircle", back_populates="members")
    user = relationship("User", backref="social_circle_memberships")


class SocialPulse(Base):
    __tablename__ = "social_pulses"

    id = Column(Integer, primary_key=True, index=True)
    circle_id = Column(Integer, ForeignKey("social_circles.id"), nullable=False)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    mood = Column(String, default="sparkles")
    message = Column(Text, nullable=False)
    attachments = Column(JSON, default=list)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    circle = relationship("SocialCircle", back_populates="pulses")
    author = relationship("User")


class Embedding(Base):
    __tablename__ = "embeddings"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    source = Column(String, nullable=False)  # e.g., "note", "task"
    source_id = Column(Integer, nullable=False)
    embedding = Column(JSON, nullable=False)
    model_identifier = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    owner = relationship("User", backref="embeddings")
