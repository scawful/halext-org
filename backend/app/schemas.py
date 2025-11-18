from pydantic import BaseModel, Field
from datetime import datetime
from typing import Any, Optional, List, Dict

class TaskBase(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    labels: List[str] = Field(default_factory=list)

class TaskCreate(TaskBase):
    pass

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
