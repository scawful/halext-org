import { API_BASE_URL } from './helpers'

export interface AiTaskSuggestion {
  subtasks: string[]
  labels: string[]
  estimated_hours: number
  priority: string
  priority_reasoning: string
}

export interface AiEventAnalysis {
  summary: string
  preparation_steps: string[]
  optimal_times: Array<{ start_time: string; end_time: string }>
  conflicts: {
    has_conflicts: boolean
    conflict_count: number
    conflicts: Array<{
      event_id: number
      event_title: string
      start_time: string
      end_time: string
    }>
  }
}

export interface AiNoteSummary {
  summary: string
  tags: string[]
  extracted_tasks: string[]
}

export interface AiChatMessage {
  role: 'user' | 'assistant'
  content: string
}

export interface AiProviderInfo {
  provider: string
  model: string
  default_model_id?: string
  available_providers?: string[]
  ollama_url?: string
  openwebui_url?: string
  openwebui_public_url?: string
}

export interface AiModelInfo {
  id: string
  name: string
  provider: string
  source?: string
  size?: number | string | null
  node_id?: number
  node_name?: string
  endpoint?: string
  latency_ms?: number
  metadata?: Record<string, unknown>
  modified_at?: string
}

export interface AiModelsResponse {
  models: AiModelInfo[]
  provider: string
  current_model: string
  default_model_id?: string
}

export interface ProviderCredentialStatus {
  provider: string
  has_key: boolean
  masked_key?: string
  key_name?: string
  model?: string | null
}

export interface ProviderCredentialUpdate {
  provider: string
  api_key: string
  model?: string
  key_name?: string
}

export interface OpenWebUISyncStatus {
  enabled: boolean
  configured: boolean
  admin_configured: boolean
  openwebui_url?: string
  features: {
    user_provisioning: boolean
    sso: boolean
    auto_sync: boolean
  }
}

export interface OpenWebUISSOResponse {
  sso_url: string
  token: string
  expires_in: number
}

/**
 * Get AI provider information
 */
export async function getAiProviderInfo(token: string): Promise<AiProviderInfo> {
  const response = await fetch(`${API_BASE_URL}/ai/info`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })
  if (!response.ok) throw new Error('Failed to get AI provider info')
  return response.json()
}

/**
 * Get available AI models
 */
export async function getAiModels(token: string): Promise<AiModelsResponse> {
  const response = await fetch(`${API_BASE_URL}/ai/models`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })
  if (!response.ok) throw new Error('Failed to get AI models')
  return response.json()
}

/**
 * Admin: fetch masked provider credentials
 */
export async function getProviderCredentials(token: string): Promise<ProviderCredentialStatus[]> {
  const response = await fetch(`${API_BASE_URL}/admin/ai/credentials`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })
  if (!response.ok) throw new Error('Failed to load provider credentials')
  return response.json()
}

/**
 * Admin: store encrypted OpenAI/Gemini credentials
 */
export async function saveProviderCredential(
  token: string,
  payload: ProviderCredentialUpdate
): Promise<ProviderCredentialStatus> {
  const response = await fetch(`${API_BASE_URL}/admin/ai/credentials`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  })
  if (!response.ok) {
    const detail = await response.text()
    throw new Error(detail || 'Failed to save provider credential')
  }
  return response.json()
}

/**
 * Get AI suggestions for a task
 */
export async function getTaskSuggestions(
  token: string,
  title: string,
  description?: string,
  model?: string
): Promise<AiTaskSuggestion> {
  const response = await fetch(`${API_BASE_URL}/ai/tasks/suggest`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ title, description, model }),
  })
  if (!response.ok) throw new Error('Failed to get task suggestions')
  return response.json()
}

/**
 * Get AI analysis for an event
 */
export async function getEventAnalysis(
  token: string,
  title: string,
  description: string | undefined,
  start_time: string,
  end_time: string,
  event_type?: string,
  model?: string
): Promise<AiEventAnalysis> {
  const response = await fetch(`${API_BASE_URL}/ai/events/analyze`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ title, description, start_time, end_time, event_type, model }),
  })
  if (!response.ok) throw new Error('Failed to get event analysis')
  return response.json()
}

/**
 * Get AI summary for a note
 */
export async function getNoteSummary(
  token: string,
  content: string,
  max_length = 200,
  model?: string
): Promise<AiNoteSummary> {
  const response = await fetch(`${API_BASE_URL}/ai/notes/summarize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ content, max_length, model }),
  })
  if (!response.ok) throw new Error('Failed to get note summary')
  return response.json()
}

/**
 * Send a chat message to AI
 */
export async function sendChatMessage(
  token: string,
  prompt: string,
  history: AiChatMessage[] = [],
  model?: string
): Promise<string> {
  const response = await fetch(`${API_BASE_URL}/ai/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ prompt, history, model }),
  })
  if (!response.ok) throw new Error('Failed to send chat message')
  const data = await response.json()
  return data.response
}

/**
 * Stream chat response from AI
 */
export interface ChatStreamResult {
  stream: AsyncGenerator<string>
  model?: string
  provider?: string
}

export async function streamChatMessage(
  token: string,
  prompt: string,
  history: AiChatMessage[] = [],
  model?: string
): Promise<ChatStreamResult> {
  const response = await fetch(`${API_BASE_URL}/ai/stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ prompt, history, model }),
  })

  if (!response.ok) throw new Error('Failed to stream chat message')

  const responseBody = response.body
  if (!responseBody) {
    throw new Error('No response body')
  }
  const reader = responseBody.getReader()

  const decoder = new TextDecoder()
  const resolvedModel = response.headers.get('x-halext-ai-model') ?? undefined
  const provider = resolvedModel?.split(':')[0]

  async function* iterator(): AsyncGenerator<string> {
    while (true) {
      const { done, value } = await reader.read()
      if (done) break

      const chunk = decoder.decode(value, { stream: true })
      const lines = chunk.split('\n')

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6)
          if (data === '[DONE]') return
          yield data
        }
      }
    }
  }

  return {
    stream: iterator(),
    model: resolvedModel || undefined,
    provider: provider || undefined,
  }
}

export interface AiGenerateTasksResponse {
  tasks: Array<{
    title: string
    description?: string
    due_date?: string
    priority: string
    labels: string[]
    estimated_minutes?: number
    subtasks?: string[]
    reasoning?: string
  }>
  events: Array<{
    title: string
    description?: string
    start_time: string
    end_time: string
    location?: string
    recurrence_type?: string
    reasoning?: string
  }>
  smart_lists: Array<{
    name: string
    description?: string
    items: string[]
    reasoning?: string
  }>
  metadata?: {
    original_prompt?: string
    summary?: string
    model?: string
  }
}

/**
 * Generate tasks, events, and lists from natural language prompt
 */
export async function generateSmartTasks(
  token: string,
  prompt: string,
  context: {
    timezone: string
    current_date: string
    existing_task_titles?: string[]
    upcoming_event_dates?: string[]
  },
  model?: string
): Promise<AiGenerateTasksResponse> {
  const response = await fetch(`${API_BASE_URL}/ai/generate-tasks`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ prompt, context, model }),
  })
  if (!response.ok) throw new Error('Failed to generate tasks')
  return response.json()
}

export interface RecipeIngredient {
  id: string
  name: string
  amount?: string
  unit?: string
  notes?: string
  is_optional?: boolean
}

export interface RecipeInstruction {
  id: string
  step_number: number
  instruction: string
  time_minutes?: number
  image_url?: string
  timer_name?: string
}

export interface RecipeNutrition {
  calories?: number
  protein?: number
  carbohydrates?: number
  fat?: number
  fiber?: number
  sugar?: number
  sodium?: number
}

export interface Recipe {
  id: string
  name: string
  description?: string
  prep_time_minutes?: number
  cook_time_minutes?: number
  total_time_minutes?: number
  servings?: number
  difficulty?: string
  cuisine?: string
  image_url?: string
  nutrition?: RecipeNutrition
  tags?: string[]
  ingredients: RecipeIngredient[]
  instructions: RecipeInstruction[]
  matched_ingredients?: string[]
  missing_ingredients?: string[]
  match_score?: number
}

export interface RecipeGenerationResponse {
  recipes: Recipe[]
  summary?: string
}

export interface MealPlanMeal {
  id: string
  meal_type: string
  recipe: Recipe
}

export interface MealPlanDay {
  id: string
  day: string
  meals: MealPlanMeal[]
}

export interface NutritionSummary {
  calories?: number
  protein?: number
  carbohydrates?: number
  fat?: number
  fiber?: number
  sugar?: number
  sodium?: number
}

export interface MealPlanResponse {
  meal_plan: MealPlanDay[]
  shopping_list: string[]
  estimated_cost?: number
  nutrition_summary?: NutritionSummary
}

/**
 * Generate recipes from ingredients
 */
export async function generateRecipes(
  token: string,
  ingredients: string[],
  filters: {
    dietary_restrictions?: string[]
    cuisine_preferences?: string[]
    difficulty_level?: string
    time_limit_minutes?: number
  },
  model?: string
): Promise<RecipeGenerationResponse> {
  const response = await fetch(`${API_BASE_URL}/ai/recipes/generate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ ingredients, ...filters, model }),
  })
  if (!response.ok) throw new Error('Failed to generate recipes')
  return response.json()
}

/**
 * Generate a meal plan
 */
export async function generateMealPlan(
  token: string,
  ingredients: string[],
  options: {
    days: number
    dietary_restrictions?: string[]
    meals_per_day?: number
  },
  model?: string
): Promise<MealPlanResponse> {
  const response = await fetch(`${API_BASE_URL}/ai/recipes/meal-plan`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ ingredients, ...options, model }),
  })
  if (!response.ok) throw new Error('Failed to generate meal plan')
  return response.json()
}

/**
 * Get OpenWebUI sync status
 */
export async function getOpenWebUISyncStatus(token: string): Promise<OpenWebUISyncStatus> {
  const response = await fetch(`${API_BASE_URL}/integrations/openwebui/sync/status`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })
  if (!response.ok) throw new Error('Failed to get OpenWebUI sync status')
  return response.json()
}

/**
 * Sync current user to OpenWebUI
 */
export async function syncUserToOpenWebUI(token: string): Promise<{
  success: boolean
  action?: string
  user_id?: string
  message: string
  error?: string
}> {
  const response = await fetch(`${API_BASE_URL}/integrations/openwebui/sync/user`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
    },
  })
  if (!response.ok) throw new Error('Failed to sync user to OpenWebUI')
  return response.json()
}

/**
 * Get SSO link for OpenWebUI
 */
export async function getOpenWebUISSO(
  token: string,
  redirect_to?: string
): Promise<OpenWebUISSOResponse> {
  const response = await fetch(`${API_BASE_URL}/integrations/openwebui/sso`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ redirect_to }),
  })
  if (!response.ok) throw new Error('Failed to get OpenWebUI SSO link')
  return response.json()
}
