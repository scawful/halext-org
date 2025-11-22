export type Label = {
  id: number
  name: string
  color: string
}

export type Task = {
  id: number
  title: string
  description?: string | null
  due_date?: string | null
  completed: boolean
  created_at: string
  labels: Label[]
}

export type EventItem = {
  id: number
  title: string
  description?: string | null
  start_time: string
  end_time: string
  location?: string | null
  recurrence_type: string
  recurrence_interval: number
  recurrence_end_date?: string | null
}

export type WidgetType = 'tasks' | 'events' | 'notes' | 'gift-list' | 'openwebui'

export type LayoutWidget = {
  id: string
  type: WidgetType
  title: string
  config?: Record<string, unknown>
}

export type LayoutColumn = {
  id: string
  title: string
  width: number
  widgets: LayoutWidget[]
}

export type LayoutPreset = {
  id: number
  name: string
  description?: string | null
  layout: LayoutColumn[]
  is_system: boolean
  owner_id?: number | null
}

export type PageShareInfo = {
  user_id: number
  username: string
  can_edit: boolean
}

export type PageDetail = {
  id: number
  title: string
  description?: string | null
  owner_id: number
  visibility: string
  created_at: string
  updated_at: string
  layout: LayoutColumn[]
  shared_with: PageShareInfo[]
}

export type ConversationSummary = {
  id: number
  title: string
  owner_id: number
  mode: string
  with_ai: boolean
  default_model_id?: string | null
  created_at: string
  updated_at: string
  participants: string[]
}

export type ChatMessage = {
  id: number
  conversation_id: number
  author_id?: number | null
  author_type: 'user' | 'ai'
  model_used?: string | null
  content: string
  created_at: string
}

export type User = {
  id: number
  username: string
  email: string
  full_name?: string | null
}

export type OpenWebUiStatus = {
  enabled: boolean
  url?: string | null
}

export type MenuSection =
  | 'dashboard'
  | 'tasks'
  | 'chat'
  | 'calendar'
  | 'iot'
  | 'settings'
  | 'image-gen'
  | 'anime'
  | 'admin'
  | 'recipes'
  | 'finance'
  | 'social'

// Recipe Types
export type RecipeIngredient = {
  id: string
  name: string
  amount?: string
  unit?: string
  notes?: string
  is_optional?: boolean
}

export type RecipeInstruction = {
  id: string
  step_number: number
  instruction: string
  time_minutes?: number
  image_url?: string
  timer_name?: string
}

export type RecipeNutrition = {
  calories?: number
  protein?: number
  carbohydrates?: number
  fat?: number
  fiber?: number
  sugar?: number
  sodium?: number
}

export type DifficultyLevel = 'beginner' | 'intermediate' | 'advanced' | 'expert'

export type Recipe = {
  id: string
  name: string
  description?: string
  prep_time_minutes?: number
  cook_time_minutes?: number
  total_time_minutes?: number
  servings?: number
  difficulty?: DifficultyLevel
  cuisine?: string
  image_url?: string
  nutrition?: RecipeNutrition
  tags?: string[]
  ingredients: RecipeIngredient[]
  instructions: RecipeInstruction[]
  matched_ingredients?: string[]
  missing_ingredients?: string[]
  match_score?: number
  is_saved?: boolean
  created_at?: string
  updated_at?: string
}

export type RecipeGenerationFilters = {
  dietary_restrictions?: string[]
  cuisine_preferences?: string[]
  difficulty_level?: DifficultyLevel
  time_limit_minutes?: number
}

export type MealPlanMeal = {
  id: string
  meal_type: string
  recipe: Recipe
}

export type MealPlanDay = {
  id: string
  day: string
  meals: MealPlanMeal[]
}

export type MealPlan = {
  meal_plan: MealPlanDay[]
  shopping_list: string[]
  estimated_cost?: number
  nutrition_summary?: RecipeNutrition
}
