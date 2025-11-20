import { useState } from 'react'
import { MdAutoAwesome, MdClose, MdCheck, MdEvent, MdList, MdCheckBox } from 'react-icons/md'
import { generateSmartTasks } from '../../utils/aiApi'
import type { AiGenerateTasksResponse } from '../../utils/aiApi'
import { useAiProvider } from '../../contexts/AiProviderContext'
import './SmartTaskGenerator.css'

interface SmartTaskGeneratorProps {
  token: string
  onClose: () => void
  onCreateTasks: (tasks: any[]) => Promise<void>
  onCreateEvents: (events: any[]) => Promise<void>
}

const EXAMPLE_PROMPTS = [
  {
    title: 'Plan a trip',
    prompt: 'Plan a 2-week trip to Japan next month including flights, hotels, and key sightseeing spots.',
  },
  {
    title: 'Weekly Meal Prep',
    prompt: 'Create a meal prep plan for next week with healthy dinners and a grocery list.',
  },
  {
    title: 'Project Launch',
    prompt: 'Outline tasks for launching a new website marketing campaign starting next Monday.',
  },
  {
    title: 'House Cleaning',
    prompt: 'Schedule a deep cleaning routine for my apartment for this weekend.',
  },
]

export const SmartTaskGenerator = ({
  token,
  onClose,
  onCreateTasks,
  onCreateEvents,
}: SmartTaskGeneratorProps) => {
  const { selectedModelId } = useAiProvider()
  const [prompt, setPrompt] = useState('')
  const [isGenerating, setIsGenerating] = useState(false)
  const [result, setResult] = useState<AiGenerateTasksResponse | null>(null)
  const [selectedTasks, setSelectedTasks] = useState<Set<number>>(new Set())
  const [selectedEvents, setSelectedEvents] = useState<Set<number>>(new Set())
  const [error, setError] = useState<string | null>(null)

  const handleGenerate = async () => {
    if (!prompt.trim()) return

    setIsGenerating(true)
    setError(null)
    try {
      const context = {
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        current_date: new Date().toISOString(),
      }
      
      const response = await generateSmartTasks(token, prompt, context, selectedModelId || undefined)
      setResult(response)
      
      // Select all by default
      setSelectedTasks(new Set(response.tasks.map((_, i) => i)))
      setSelectedEvents(new Set(response.events.map((_, i) => i)))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate tasks')
    } finally {
      setIsGenerating(false)
    }
  }

  const handleCreate = async () => {
    if (!result) return

    try {
      const tasksToCreate = result.tasks.filter((_, i) => selectedTasks.has(i))
      const eventsToCreate = result.events.filter((_, i) => selectedEvents.has(i))

      await Promise.all([
        onCreateTasks(tasksToCreate),
        onCreateEvents(eventsToCreate)
      ])

      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create items')
    }
  }

  const toggleTask = (index: number) => {
    const newSelected = new Set(selectedTasks)
    if (newSelected.has(index)) {
      newSelected.delete(index)
    } else {
      newSelected.add(index)
    }
    setSelectedTasks(newSelected)
  }

  const toggleEvent = (index: number) => {
    const newSelected = new Set(selectedEvents)
    if (newSelected.has(index)) {
      newSelected.delete(index)
    } else {
      newSelected.add(index)
    }
    setSelectedEvents(newSelected)
  }

  return (
    <div className="smart-generator-overlay">
      <div className="smart-generator-card">
        <div className="smart-generator-header">
          <div className="flex items-center gap-2">
            <MdAutoAwesome className="text-purple-400" size={24} />
            <h2 className="text-xl font-bold text-white">AI Smart Generator</h2>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-white">
            <MdClose size={24} />
          </button>
        </div>

        {!result ? (
          <div className="smart-generator-content">
            <div className="input-section">
              <textarea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="Describe what you want to organize (e.g., 'Plan a birthday party for Sarah next Saturday')..."
                className="prompt-input"
                rows={4}
                disabled={isGenerating}
              />
              <button
                onClick={handleGenerate}
                disabled={!prompt.trim() || isGenerating}
                className="generate-btn"
              >
                {isGenerating ? 'Generating...' : 'Generate Plan'}
              </button>
              <p className="model-hint">
                Using {selectedModelId ? selectedModelId : 'system default model'}
              </p>
            </div>

            {error && <div className="error-message">{error}</div>}

            <div className="examples-section">
              <h3 className="text-sm font-medium text-gray-400 mb-3">Try these examples:</h3>
              <div className="examples-grid">
                {EXAMPLE_PROMPTS.map((ex, i) => (
                  <button
                    key={i}
                    onClick={() => setPrompt(ex.prompt)}
                    className="example-card"
                  >
                    <span className="font-medium text-purple-300">{ex.title}</span>
                    <span className="text-xs text-gray-400 mt-1 line-clamp-2">{ex.prompt}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="smart-generator-results">
            {result.metadata && (
              <div className="smart-metadata">
                {result.metadata.model && (
                  <span className="metadata-chip">Model {result.metadata.model}</span>
                )}
                {result.metadata.summary && (
                  <p className="metadata-summary">{result.metadata.summary}</p>
                )}
              </div>
            )}
            <div className="results-scroll">
              {result.tasks.length > 0 && (
                <div className="result-section">
                  <div className="section-header">
                    <MdCheckBox className="text-blue-400" />
                    <h3>Tasks ({result.tasks.length})</h3>
                  </div>
                  <div className="items-list">
                    {result.tasks.map((task, i) => (
                      <div
                        key={i}
                        className={`result-item ${selectedTasks.has(i) ? 'selected' : ''}`}
                        onClick={() => toggleTask(i)}
                      >
                        <div className="checkbox">
                          {selectedTasks.has(i) && <MdCheck size={14} />}
                        </div>
                        <div className="item-content">
                          <div className="item-title">{task.title}</div>
                          <div className="item-meta">
                            {task.priority && <span className="badge">{task.priority}</span>}
                            {task.due_date && (
                              <span className="date">Due: {new Date(task.due_date).toLocaleDateString()}</span>
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {result.events.length > 0 && (
                <div className="result-section">
                  <div className="section-header">
                    <MdEvent className="text-orange-400" />
                    <h3>Events ({result.events.length})</h3>
                  </div>
                  <div className="items-list">
                    {result.events.map((event, i) => (
                      <div
                        key={i}
                        className={`result-item ${selectedEvents.has(i) ? 'selected' : ''}`}
                        onClick={() => toggleEvent(i)}
                      >
                        <div className="checkbox">
                          {selectedEvents.has(i) && <MdCheck size={14} />}
                        </div>
                        <div className="item-content">
                          <div className="item-title">{event.title}</div>
                          <div className="item-meta">
                            <span className="date">
                              {new Date(event.start_time).toLocaleString()}
                            </span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {result.smart_lists.length > 0 && (
                <div className="result-section">
                  <div className="section-header">
                    <MdList className="text-green-400" />
                    <h3>Smart Lists ({result.smart_lists.length})</h3>
                  </div>
                  <div className="smart-lists-grid">
                    {result.smart_lists.map((list, i) => (
                      <div key={i} className="smart-list-card">
                        <h4>{list.name}</h4>
                        <ul>
                          {list.items.slice(0, 3).map((item, j) => (
                            <li key={j}>{item}</li>
                          ))}
                          {list.items.length > 3 && (
                            <li className="more">+{list.items.length - 3} more</li>
                          )}
                        </ul>
                      </div>
                    ))}
                  </div>
                  <p className="text-xs text-gray-500 mt-2 italic">
                    * Smart lists are currently for display only
                  </p>
                </div>
              )}
            </div>

            <div className="results-actions">
              <button onClick={() => setResult(null)} className="btn-secondary">
                Back
              </button>
              <button onClick={handleCreate} className="create-btn">
                Create {selectedTasks.size + selectedEvents.size} Items
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
