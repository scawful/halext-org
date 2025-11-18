from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text, JSON, Table
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
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    tasks = relationship("Task", back_populates="owner")
    events = relationship("Event", back_populates="owner")
    pages = relationship("Page", back_populates="owner")
    shared_pages = relationship("PageShare", back_populates="user")
    conversations = relationship("ConversationParticipant", back_populates="user")
    labels = relationship("Label", back_populates="owner")
    api_keys = relationship("APIKey", back_populates="owner", cascade="all, delete-orphan")

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
    metadata = Column(JSON, default=dict)  # OS, version, etc.
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
    mode = Column(String, default="solo")  # solo, partner, group
    with_ai = Column(Boolean, default=True)
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
