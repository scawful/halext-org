import { useState, useEffect, useMemo } from 'react'
import { getAiModels, type AiModelInfo } from '../../utils/aiApi'
import { useAiProvider } from '../../contexts/AiProviderContext'

interface AiModelSelectorProps {
  token: string
  compact?: boolean
  className?: string
  showLabel?: boolean
  label?: string
}

export const AiModelSelector = ({
  token,
  compact: _compact = false,
  className = '',
  showLabel = true,
  label = 'AI Model',
}: AiModelSelectorProps) => {
  const { selectedModelId, setSelectedModelId, preferredSources } = useAiProvider()
  const [models, setModels] = useState<AiModelInfo[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    loadModels()
  }, [token])

  const loadModels = async () => {
    try {
      setLoading(true)
      const response = await getAiModels(token)
      setModels(response.models)
    } catch (err) {
      console.error('Failed to load AI models:', err)
      setError('Failed to load models')
    } finally {
      setLoading(false)
    }
  }

  const filteredModels = useMemo(() => {
    if (!preferredSources.length) return models

    const normalized = preferredSources.map((source) => source.toLowerCase())

    return models.filter((model) => {
      const source = (model.source || model.provider || '').toLowerCase()
      const isRemote = Boolean(model.node_id) || source.includes('remote')

      return normalized.some((pref) => {
        if (pref === 'remote') {
          return isRemote
        }
        if (pref === 'openwebui') {
          return source.includes('openwebui')
        }
        return source.includes(pref)
      })
    })
  }, [models, preferredSources])

  useEffect(() => {
    if (selectedModelId && !filteredModels.some((model) => model.id === selectedModelId)) {
      setSelectedModelId(undefined)
    }
  }, [filteredModels, selectedModelId, setSelectedModelId])

  const groupedModels = useMemo(() => {
    return filteredModels.reduce((acc, model) => {
      const group = model.source || model.provider || 'Other'
      if (!acc[group]) acc[group] = []
      acc[group].push(model)
      return acc
    }, {} as Record<string, AiModelInfo[]>)
  }, [filteredModels])

  const handleSelectionChange = (value: string) => {
    setSelectedModelId(value || undefined)
  }

  return (
    <div className={className}>
      {showLabel && (
        <label className="block text-sm font-medium text-gray-300 mb-1">
          {label}
        </label>
      )}

      {loading ? (
        <div className="text-xs text-gray-400">Loading models...</div>
      ) : error ? (
        <div className="text-xs text-red-400">{error}</div>
      ) : (
        <>
          <select
            value={selectedModelId || ''}
            onChange={(e) => handleSelectionChange(e.target.value)}
            className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded text-sm focus:outline-none focus:border-purple-500"
          >
            <option value="">System Default</option>
            {Object.entries(groupedModels).map(([group, groupModels]) => (
              <optgroup key={group} label={group}>
                {groupModels.map((model) => (
                  <option key={model.id} value={model.id}>
                    {model.name}
                    {model.node_name ? ` (${model.node_name})` : ''}
                    {model.latency_ms ? ` - ${model.latency_ms}ms` : ''}
                  </option>
                ))}
              </optgroup>
            ))}
          </select>
          {preferredSources.length > 0 && filteredModels.length === 0 && (
            <p className="text-xs text-amber-300 mt-2">
              No models available for the current provider filters.
            </p>
          )}
        </>
      )}
    </div>
  )
}
