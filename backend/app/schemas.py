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
    default_model_id: Optional[str] = None

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
    model: Optional[str] = None  # Optional model override for this message

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
    meta: Dict[str, Any] = Field(default_factory=dict)


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
    file_path: Optional[str] = None


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
    file_path: Optional[str] = None


class BlogPost(BlogPostBase):
    id: int
    author_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class SiteSetting(BaseModel):
    key: str
    value: Dict[str, Any]
    updated_at: datetime

    class Config:
        from_attributes = True


class BlogTheme(BaseModel):
    gradient_start: str = "#4c3b52"
    gradient_end: str = "#000000"
    accent_color: str = "#9775a3"
    font_family: str = "'Source Sans Pro', sans-serif"

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
    id: str
    name: str
    provider: str
    size: Optional[Any] = None
    source: Optional[str] = None
    node_id: Optional[int] = None
    node_name: Optional[str] = None
    endpoint: Optional[str] = None
    latency_ms: Optional[int] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)
    modified_at: Optional[str] = None
    # Enhanced metadata for cloud models
    description: Optional[str] = None
    context_window: Optional[int] = None
    max_output_tokens: Optional[int] = None
    input_cost_per_1m: Optional[float] = None
    output_cost_per_1m: Optional[float] = None
    supports_vision: Optional[bool] = None
    supports_function_calling: Optional[bool] = None

class AiModelsResponse(BaseModel):
    models: List[AiModelInfo]
    provider: str
    current_model: str
    default_model_id: Optional[str] = None

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
    default_model_id: Optional[str] = None
    available_providers: List[str] = Field(default_factory=list)
    ollama_url: Optional[str] = None
    openwebui_url: Optional[str] = None
    openwebui_public_url: Optional[str] = None


class ProviderCredentialStatus(BaseModel):
    provider: str
    has_key: bool = False
    masked_key: Optional[str] = None
    key_name: Optional[str] = None
    model: Optional[str] = None


class ProviderCredentialUpdate(BaseModel):
    provider: str  # openai | gemini
    api_key: str
    model: Optional[str] = None
    key_name: Optional[str] = None


class ServiceStatus(BaseModel):
    name: str
    status: str
    last_checked: datetime


class ResourceUsage(BaseModel):
    total: int
    used: int
    free: int
    percent: float


class ServerStatusResponse(BaseModel):
    hostname: str
    uptime_seconds: float
    uptime_human: str
    load_avg: Dict[str, float]
    memory: ResourceUsage
    disk: ResourceUsage
    services: List[ServiceStatus]
    git: Dict[str, Optional[str]]
    generated_at: datetime

# AI Task Features
class AiTaskSuggestionsRequest(BaseModel):
    title: str
    description: Optional[str] = None
    model: Optional[str] = None

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
    model: Optional[str] = None

class AiEventAnalysisResponse(BaseModel):
    summary: str
    preparation_steps: List[str]
    optimal_times: List[Dict[str, str]]
    conflicts: Dict[str, Any]

# AI Note Features
class AiNoteSummaryRequest(BaseModel):
    content: str
    max_length: Optional[int] = 200
    model: Optional[str] = None

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

# Smart Generation Schemas
class GenerationContext(BaseModel):
    timezone: str
    current_date: datetime
    existing_task_titles: Optional[List[str]] = None
    upcoming_event_dates: Optional[List[datetime]] = None

class AiGenerateTasksRequest(BaseModel):
    prompt: str
    context: GenerationContext
    model: Optional[str] = None

class GeneratedTaskData(BaseModel):
    title: str
    description: str
    due_date: Optional[datetime] = None
    priority: str
    labels: List[str] = Field(default_factory=list)
    estimated_minutes: Optional[int] = None
    subtasks: List[str] = Field(default_factory=list)
    reasoning: str

class GeneratedEventData(BaseModel):
    title: str
    description: str
    start_time: datetime
    end_time: datetime
    location: Optional[str] = None
    recurrence_type: str = "none"
    reasoning: str

class GeneratedSmartListData(BaseModel):
    name: str
    description: str
    category: str
    items: List[str] = Field(default_factory=list)
    reasoning: str

class GenerationMetadataData(BaseModel):
    original_prompt: str
    model: str
    summary: str

class AiGenerateTasksResponse(BaseModel):
    tasks: List[GeneratedTaskData] = Field(default_factory=list)
    events: List[GeneratedEventData] = Field(default_factory=list)
    smart_lists: List[GeneratedSmartListData] = Field(default_factory=list)
    metadata: GenerationMetadataData

# Recipe AI Schemas
class NutritionInfo(BaseModel):
    calories: Optional[int] = None
    protein: Optional[float] = None
    carbohydrates: Optional[float] = None
    fat: Optional[float] = None
    fiber: Optional[float] = None
    sugar: Optional[float] = None
    sodium: Optional[float] = None

class RecipeIngredient(BaseModel):
    id: str
    name: str
    amount: str
    unit: str
    notes: Optional[str] = None
    is_optional: bool = False

class RecipeInstruction(BaseModel):
    id: str
    step_number: int
    instruction: str
    time_minutes: Optional[int] = None
    image_url: Optional[str] = None
    timer_name: Optional[str] = None

class Recipe(BaseModel):
    id: str
    name: str
    description: str
    ingredients: List[RecipeIngredient] = Field(default_factory=list)
    instructions: List[RecipeInstruction] = Field(default_factory=list)
    prep_time_minutes: int
    cook_time_minutes: int
    total_time_minutes: int
    servings: int
    difficulty: str
    cuisine: Optional[str] = None
    image_url: Optional[str] = None
    nutrition: Optional[NutritionInfo] = None
    tags: List[str] = Field(default_factory=list)
    matched_ingredients: List[str] = Field(default_factory=list)
    missing_ingredients: List[str] = Field(default_factory=list)
    match_score: float

class RecipeGenerationRequest(BaseModel):
    ingredients: List[str]
    dietary_restrictions: Optional[List[str]] = None
    cuisine_preferences: Optional[List[str]] = None
    difficulty_level: Optional[str] = None
    time_limit_minutes: Optional[int] = None
    servings: Optional[int] = None
    meal_type: Optional[str] = None
    model: Optional[str] = None

class RecipeGenerationResponse(BaseModel):
    recipes: List[Recipe] = Field(default_factory=list)
    total_recipes: int
    match_score: float

class DailyMealRecipe(BaseModel):
    id: str
    meal_type: str
    recipe: Recipe

class DailyMeal(BaseModel):
    id: str
    day: str
    meals: List[DailyMealRecipe] = Field(default_factory=list)

class MealPlanRequest(BaseModel):
    ingredients: List[str]
    days: int
    dietary_restrictions: Optional[List[str]] = None
    budget: Optional[float] = None
    meals_per_day: int
    model: Optional[str] = None

class MealPlanResponse(BaseModel):
    meal_plan: List[DailyMeal] = Field(default_factory=list)
    shopping_list: List[str] = Field(default_factory=list)
    estimated_cost: Optional[float] = None
    nutrition_summary: NutritionInfo

class SubstitutionRequest(BaseModel):
    ingredients: List[str]
    recipe_type: Optional[str] = None
    model: Optional[str] = None

class IngredientSubstitution(BaseModel):
    original: str
    substitute: str
    ratio: str
    notes: Optional[str] = None

class IngredientsRequest(BaseModel):
    ingredients: List[str]
    model: Optional[str] = None

class IngredientCategory(BaseModel):
    id: str
    name: str
    ingredients: List[str] = Field(default_factory=list)

class IngredientAnalysis(BaseModel):
    extracted_ingredients: List[str] = Field(default_factory=list)
    categories: List[IngredientCategory] = Field(default_factory=list)
    suggestions: List[str] = Field(default_factory=list)

# Finance Schemas
class FinanceAccountBase(BaseModel):
    account_name: str
    account_type: str = "checking"
    institution_name: Optional[str] = None
    account_number: Optional[str] = None
    balance: float = 0.0
    currency: str = "USD"
    is_active: bool = True
    theme_emoji: Optional[str] = None
    accent_color: Optional[str] = None
    plaid_account_id: Optional[str] = None


class FinanceAccountCreate(FinanceAccountBase):
    pass


class FinanceAccountUpdate(BaseModel):
    account_name: Optional[str] = None
    balance: Optional[float] = None
    is_active: Optional[bool] = None
    accent_color: Optional[str] = None
    theme_emoji: Optional[str] = None


class FinanceAccount(FinanceAccountBase):
    id: int
    owner_id: int
    last_synced: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class FinanceTransactionBase(BaseModel):
    account_id: int
    amount: float
    description: str
    category: str = "other"
    transaction_type: str = "debit"
    transaction_date: Optional[datetime] = None
    merchant: Optional[str] = None
    notes: Optional[str] = None
    tags: List[str] = Field(default_factory=list)
    mood_icon: Optional[str] = None


class FinanceTransactionCreate(FinanceTransactionBase):
    pass


class FinanceTransaction(FinanceTransactionBase):
    id: int
    owner_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class FinanceBudgetBase(BaseModel):
    name: str
    category: str = "general"
    limit_amount: float
    spent_amount: float = 0.0
    period: str = "monthly"
    emoji: Optional[str] = None
    color_hex: Optional[str] = None


class FinanceBudgetCreate(FinanceBudgetBase):
    pass


class FinanceBudgetUpdate(BaseModel):
    spent_amount: Optional[float] = None
    limit_amount: Optional[float] = None
    emoji: Optional[str] = None
    color_hex: Optional[str] = None


class FinanceBudget(FinanceBudgetBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class FinanceSummary(BaseModel):
    total_balance: float
    active_accounts: int
    monthly_spending: float
    monthly_income: float
    budget_progress: List[FinanceBudget]
    recent_transactions: List[FinanceTransaction]


# Social Schemas
class SocialCircleBase(BaseModel):
    name: str
    description: Optional[str] = None
    emoji: Optional[str] = None
    theme_color: Optional[str] = None
    vibe: Optional[str] = None


class SocialCircleCreate(SocialCircleBase):
    pass


class SocialCircle(SocialCircleBase):
    id: int
    owner_id: int
    invite_code: str
    created_at: datetime
    member_count: int = 0

    class Config:
        from_attributes = True


class SocialCircleMember(BaseModel):
    circle_id: int
    user_id: int
    role: str = "member"
    joined_at: datetime

    class Config:
        from_attributes = True


class SocialPulseBase(BaseModel):
    message: str
    mood: Optional[str] = None
    attachments: List[str] = Field(default_factory=list)


class SocialPulseCreate(SocialPulseBase):
    pass


class SocialPulse(SocialPulseBase):
    id: int
    circle_id: int
    author_id: int
    created_at: datetime
    author_name: Optional[str] = None

    class Config:
        from_attributes = True


class ApiRouteInfo(BaseModel):
    path: str
    methods: List[str]
    name: str
    summary: Optional[str] = None
