import { useState } from 'react'
import { getTaskSuggestions } from '../../utils/aiApi'
import type { AiTaskSuggestion } from '../../utils/aiApi'

interface AiTaskAssistantProps {
  token: string
  taskTitle: string
  taskDescription?: string
  onApplySuggestions?: (suggestions: AiTaskSuggestion) => void
}

export const AiTaskAssistant = ({
  token,
  taskTitle,
  taskDescription,
  onApplySuggestions,
}: AiTaskAssistantProps) => {
  const [loading, setLoading] = useState(false)
  const [suggestions, setSuggestions] = useState<AiTaskSuggestion | null>(null)
  const [error, setError] = useState<string | null>(null)

  const getSuggestions = async () => {
    if (!taskTitle.trim()) {
      setError('Please enter a task title first')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const result = await getTaskSuggestions(token, taskTitle, taskDescription)
      setSuggestions(result)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to get AI suggestions')
    } finally {
      setLoading(false)
    }
  }

  const applySuggestions = () => {
    if (suggestions && onApplySuggestions) {
      onApplySuggestions(suggestions)
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'bg-red-500/20 text-red-300 border-red-500/30'
      case 'medium':
        return 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30'
      case 'low':
        return 'bg-green-500/20 text-green-300 border-green-500/30'
      default:
        return 'bg-gray-500/20 text-gray-300 border-gray-500/30'
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-medium text-purple-300">AI Task Assistant</h3>
        <button
          onClick={getSuggestions}
          disabled={loading || !taskTitle.trim()}
          className="px-3 py-1 text-xs bg-purple-600 hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed rounded transition-colors"
        >
          {loading ? 'Analyzing...' : 'Get AI Suggestions'}
        </button>
      </div>

      {error && (
        <div className="p-3 bg-red-500/10 border border-red-500/30 rounded text-red-300 text-sm">
          {error}
        </div>
      )}

      {suggestions && (
        <div className="space-y-4 p-4 bg-white/5 backdrop-blur-sm rounded-lg border border-white/10">
          {/* Priority */}
          <div>
            <label className="block text-xs text-gray-400 mb-2">Suggested Priority</label>
            <div
              className={`inline-flex items-center gap-2 px-3 py-1 rounded border ${getPriorityColor(suggestions.priority)}`}
            >
              <span className="text-sm font-medium">{suggestions.priority.toUpperCase()}</span>
            </div>
            <p className="mt-2 text-sm text-gray-300">{suggestions.priority_reasoning}</p>
          </div>

          {/* Time Estimate */}
          <div>
            <label className="block text-xs text-gray-400 mb-2">Estimated Time</label>
            <div className="text-sm text-gray-200">
              {suggestions.estimated_hours} hour{suggestions.estimated_hours !== 1 ? 's' : ''}
            </div>
          </div>

          {/* Labels */}
          {suggestions.labels.length > 0 && (
            <div>
              <label className="block text-xs text-gray-400 mb-2">Suggested Labels</label>
              <div className="flex flex-wrap gap-2">
                {suggestions.labels.map((label, index) => (
                  <span
                    key={index}
                    className="px-2 py-1 text-xs bg-purple-500/20 text-purple-300 rounded border border-purple-500/30"
                  >
                    {label}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Subtasks */}
          {suggestions.subtasks.length > 0 && (
            <div>
              <label className="block text-xs text-gray-400 mb-2">Suggested Subtasks</label>
              <ul className="space-y-2">
                {suggestions.subtasks.map((subtask, index) => (
                  <li key={index} className="flex items-start gap-2 text-sm text-gray-200">
                    <span className="text-purple-400 mt-0.5">•</span>
                    <span>{subtask}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {onApplySuggestions && (
            <button
              onClick={applySuggestions}
              className="w-full px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded transition-colors text-sm font-medium"
            >
              Apply Suggestions
            </button>
          )}
        </div>
      )}
    </div>
  )
}
