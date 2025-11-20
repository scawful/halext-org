import { useState, useEffect, useCallback } from 'react'
import { getAiModels, type AiModelsResponse, type AiModelInfo } from '../utils/aiApi'

export interface GroupedModels {
  openai: AiModelInfo[]
  gemini: AiModelInfo[]
  remote: AiModelInfo[]
  openwebui: AiModelInfo[]
  local: AiModelInfo[]
  other: AiModelInfo[]
}

export interface UseAiModelsResult {
  data: AiModelsResponse | null
  groupedModels: GroupedModels
  defaultModelId?: string
  currentModel?: string
  isLoading: boolean
  error: Error | null
  refetch: () => Promise<void>
}

/**
 * Hook to fetch and manage AI models
 * Normalizes data into provider groups (openai, gemini, remote, local)
 */
export function useAiModels(token: string | null): UseAiModelsResult {
  const [data, setData] = useState<AiModelsResponse | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  const fetchModels = useCallback(async () => {
    if (!token) {
      setData(null)
      setError(null)
      return
    }

    setIsLoading(true)
    setError(null)

    try {
      const response = await getAiModels(token)
      setData(response)
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch AI models'))
    } finally {
      setIsLoading(false)
    }
  }, [token])

  useEffect(() => {
    fetchModels()
  }, [fetchModels])

  // Normalize models into provider groups
  const groupedModels: GroupedModels = {
    openai: [],
    gemini: [],
    remote: [],
    openwebui: [],
    local: [],
    other: [],
  }

  if (data?.models) {
    data.models.forEach((model) => {
      const provider = model.provider.toLowerCase()
      const source = model.source?.toLowerCase() || ''

      if (provider.includes('openai') || model.id.startsWith('openai:')) {
        groupedModels.openai.push(model)
      } else if (provider.includes('gemini') || provider.includes('google') || model.id.startsWith('gemini:')) {
        groupedModels.gemini.push(model)
      } else if (source === 'remote' || model.node_id) {
        groupedModels.remote.push(model)
      } else if (source === 'openwebui' || model.id.startsWith('openwebui:')) {
        groupedModels.openwebui.push(model)
      } else if (provider.includes('ollama') || provider.includes('local') || source === 'local') {
        groupedModels.local.push(model)
      } else {
        groupedModels.other.push(model)
      }
    })
  }

  return {
    data,
    groupedModels,
    defaultModelId: data?.default_model_id,
    currentModel: data?.current_model,
    isLoading,
    error,
    refetch: fetchModels,
  }
}
