import { useState, useEffect } from 'react'
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
  const { selectedModelId, setSelectedModelId } = useAiProvider()
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

      // If no model is selected and we have a default, use it
      if (!selectedModelId && response.default_model_id) {
        setSelectedModelId(response.default_model_id)
      }
    } catch (err) {
      console.error('Failed to load AI models:', err)
      setError('Failed to load models')
    } finally {
      setLoading(false)
    }
  }

  const groupedModels = models.reduce((acc, model) => {
    const group = model.source || model.provider || 'Other'
    if (!acc[group]) acc[group] = []
    acc[group].push(model)
    return acc
  }, {} as Record<string, AiModelInfo[]>)

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
        <select
          value={selectedModelId || ''}
          onChange={(e) => setSelectedModelId(e.target.value)}
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
      )}
    </div>
  )
}
