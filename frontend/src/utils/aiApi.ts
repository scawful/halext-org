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
  ollama_url?: string
  openwebui_url?: string
  openwebui_public_url?: string
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
 * Get AI suggestions for a task
 */
export async function getTaskSuggestions(
  token: string,
  title: string,
  description?: string
): Promise<AiTaskSuggestion> {
  const response = await fetch(`${API_BASE_URL}/ai/tasks/suggest`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ title, description }),
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
  event_type?: string
): Promise<AiEventAnalysis> {
  const response = await fetch(`${API_BASE_URL}/ai/events/analyze`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ title, description, start_time, end_time, event_type }),
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
  max_length = 200
): Promise<AiNoteSummary> {
  const response = await fetch(`${API_BASE_URL}/ai/notes/summarize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ content, max_length }),
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
export async function* streamChatMessage(
  token: string,
  prompt: string,
  history: AiChatMessage[] = [],
  model?: string
): AsyncGenerator<string> {
  const response = await fetch(`${API_BASE_URL}/ai/stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ prompt, history, model }),
  })

  if (!response.ok) throw new Error('Failed to stream chat message')

  const reader = response.body?.getReader()
  if (!reader) throw new Error('No response body')

  const decoder = new TextDecoder()

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
