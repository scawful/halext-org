from pydantic import BaseModel, Field
from datetime import datetime
from typing import Any, Optional, List, Dict

# Task schemas for CRUD operations

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    labels: List[str] = Field(default_factory=list)

class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    completed: Optional[bool] = None
    labels: Optional[List[str]] = None


class Task(TaskBase):
    id: int
    owner_id: int
    completed: bool
    created_at: datetime
    labels: List["Label"] = Field(default_factory=list)

    class Config:
        from_attributes = True

class EventBase(BaseModel):
    title: str
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    location: Optional[str] = None
    recurrence_type: str = "none"
    recurrence_interval: int = 1
    recurrence_end_date: Optional[datetime] = None

class EventCreate(EventBase):
    pass

class Event(EventBase):
    id: int
    owner_id: int

    class Config:
        from_attributes = True

class LabelBase(BaseModel):
    name: str
    color: Optional[str] = None

class LabelCreate(LabelBase):
    pass

class Label(LabelBase):
    id: int

    class Config:
        from_attributes = True

class LayoutWidget(BaseModel):
    id: str
    type: str
    title: str
    config: Optional[Dict[str, Any]] = None

class LayoutColumn(BaseModel):
    id: str
    title: str
    width: int = 1
    widgets: List[LayoutWidget] = Field(default_factory=list)

class LayoutPresetBase(BaseModel):
    name: str
    description: Optional[str] = None
    layout: List[LayoutColumn] = Field(default_factory=list)

class LayoutPresetCreate(LayoutPresetBase):
    pass

class LayoutPresetInfo(LayoutPresetBase):
    id: int
    is_system: bool = False
    owner_id: Optional[int] = None

    class Config:
        from_attributes = True

class PageBase(BaseModel):
    title: str
    description: Optional[str] = None
    visibility: str = "private"
    layout: List[LayoutColumn] = Field(default_factory=list)

class PageCreate(PageBase):
    pass

class Page(PageBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class PageShareUpdate(BaseModel):
    username: str
    can_edit: bool = False

class PageShareInfo(BaseModel):
    user_id: int
    username: str
    can_edit: bool = False

class PageDetail(Page):
    shared_with: List[PageShareInfo] = Field(default_factory=list)

class ConversationBase(BaseModel):
    title: str
    mode: str = "solo"
    with_ai: bool = True

class ConversationCreate(ConversationBase):
    participant_usernames: List[str] = Field(default_factory=list)

class Conversation(ConversationBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ConversationSummary(Conversation):
    participants: List[str] = Field(default_factory=list)

class ChatMessageBase(BaseModel):
    content: str

class ChatMessageCreate(ChatMessageBase):
    pass

class ChatMessage(ChatMessageBase):
    id: int
    conversation_id: int
    author_id: Optional[int] = None
    author_type: str
    model_used: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class UserBase(BaseModel):
    username: str
    email: str
    full_name: Optional[str] = None
    is_admin: bool = False

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    created_at: datetime
    tasks: List[Task] = Field(default_factory=list)
    events: List[Event] = Field(default_factory=list)
    pages: List[Page] = Field(default_factory=list)
    labels: List[Label] = Field(default_factory=list)

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class OpenWebUiStatus(BaseModel):
    enabled: bool
    url: Optional[str] = None


class SiteSection(BaseModel):
    type: str
    title: Optional[str] = None
    body: Optional[str] = None
    items: List[Dict[str, Any]] = Field(default_factory=list)
    media: Optional[Dict[str, Any]] = None


class SiteNavLink(BaseModel):
    label: str
    url: str
    description: Optional[str] = None


class SitePageBase(BaseModel):
    slug: str
    title: str
    summary: Optional[str] = None
    hero_image_url: Optional[str] = None
    sections: List[SiteSection] = Field(default_factory=list)
    nav_links: List[SiteNavLink] = Field(default_factory=list)
    theme: Dict[str, Any] = Field(default_factory=dict)
    is_published: bool = False


class SitePageCreate(SitePageBase):
    pass


class SitePageUpdate(BaseModel):
    title: Optional[str] = None
    summary: Optional[str] = None
    hero_image_url: Optional[str] = None
    sections: Optional[List[SiteSection]] = None
    nav_links: Optional[List[SiteNavLink]] = None
    theme: Optional[Dict[str, Any]] = None
    is_published: Optional[bool] = None


class SitePageDetail(SitePageBase):
    id: int
    owner_id: Optional[int]
    updated_by_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PhotoAlbumBase(BaseModel):
    slug: str
    title: str
    description: Optional[str] = None
    cover_image_url: Optional[str] = None
    hero_text: Optional[str] = None
    photos: List[Dict[str, Any]] = Field(default_factory=list)
    is_public: bool = True


class PhotoAlbumCreate(PhotoAlbumBase):
    pass


class PhotoAlbumUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    cover_image_url: Optional[str] = None
    hero_text: Optional[str] = None
    photos: Optional[List[Dict[str, Any]]] = None
    is_public: Optional[bool] = None


class PhotoAlbum(PhotoAlbumBase):
    id: int
    owner_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class MediaAssetBase(BaseModel):
    title: Optional[str] = None
    file_path: str
    public_url: str
    thumbnail_url: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class MediaAsset(MediaAssetBase):
    id: int
    owner_id: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True


class BlogPostBase(BaseModel):
    slug: str
    title: str
    summary: Optional[str] = None
    body_markdown: str
    tags: List[str] = Field(default_factory=list)
    hero_image_url: Optional[str] = None
    status: str = "draft"
    published_at: Optional[datetime] = None


class BlogPostCreate(BlogPostBase):
    pass


class BlogPostUpdate(BaseModel):
    title: Optional[str] = None
    summary: Optional[str] = None
    body_markdown: Optional[str] = None
    tags: Optional[List[str]] = None
    hero_image_url: Optional[str] = None
    status: Optional[str] = None
    published_at: Optional[datetime] = None


class BlogPost(BlogPostBase):
    id: int
    author_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# AI Schemas
class AiChatRequest(BaseModel):
    prompt: str
    history: Optional[List[Dict[str, str]]] = Field(default_factory=list)
    model: Optional[str] = None

class AiChatResponse(BaseModel):
    response: str
    model: str
    provider: str

class AiModelInfo(BaseModel):
    name: str
    size: Any
    provider: str
    modified_at: Optional[str] = None

class AiModelsResponse(BaseModel):
    models: List[AiModelInfo]
    provider: str
    current_model: str

class AiEmbeddingsRequest(BaseModel):
    text: str
    model: Optional[str] = None

class AiEmbeddingsResponse(BaseModel):
    embeddings: List[float]
    model: str
    dimension: int

class AiProviderInfo(BaseModel):
    provider: str
    model: str
    ollama_url: Optional[str] = None
    openwebui_url: Optional[str] = None
    openwebui_public_url: Optional[str] = None

# AI Task Features
class AiTaskSuggestionsRequest(BaseModel):
    title: str
    description: Optional[str] = None

class AiTaskSuggestionsResponse(BaseModel):
    subtasks: List[str]
    labels: List[str]
    estimated_hours: float
    priority: str
    priority_reasoning: str

class AiTimeEstimateResponse(BaseModel):
    estimated_hours: float
    confidence: str
    factors: str

class AiPriorityResponse(BaseModel):
    priority: str
    reasoning: str

# AI Event Features
class AiEventAnalysisRequest(BaseModel):
    title: str
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    event_type: Optional[str] = None

class AiEventAnalysisResponse(BaseModel):
    summary: str
    preparation_steps: List[str]
    optimal_times: List[Dict[str, str]]
    conflicts: Dict[str, Any]

# AI Note Features
class AiNoteSummaryRequest(BaseModel):
    content: str
    max_length: Optional[int] = 200

class AiNoteSummaryResponse(BaseModel):
    summary: str
    tags: List[str]
    extracted_tasks: List[str]

# OpenWebUI Sync Schemas
class OpenWebUISyncStatus(BaseModel):
    enabled: bool
    configured: bool
    admin_configured: bool
    openwebui_url: Optional[str] = None
    features: Dict[str, bool]

class OpenWebUISyncRequest(BaseModel):
    user_id: int
    username: str
    email: str
    full_name: Optional[str] = None

class OpenWebUISyncResponse(BaseModel):
    success: bool
    action: Optional[str] = None
    user_id: Optional[str] = None
    message: str
    error: Optional[str] = None

class OpenWebUISSORequest(BaseModel):
    redirect_to: Optional[str] = None

class OpenWebUISSOResponse(BaseModel):
    sso_url: str
    token: str
    expires_in: int
