import { useState, useEffect, useCallback } from 'react'
import { MdAutoAwesome, MdClose, MdCheck, MdEvent, MdList, MdCheckBox, MdRefresh } from 'react-icons/md'
import { generateSmartTasks } from '../../utils/aiApi'
import type { AiGenerateTasksResponse } from '../../utils/aiApi'
import { useAiProvider } from '../../contexts/AiProviderContext'
import { AiModelSelector } from './AiModelSelector'
import './SmartTaskGenerator.css'

interface SmartTaskGeneratorProps {
  token: string
  onClose: () => void
  onCreateTasks: (tasks: any[]) => Promise<void>
  onCreateEvents: (events: any[]) => Promise<void>
}

type GenerationProgress = 'idle' | 'analyzing' | 'generating' | 'organizing' | 'complete'

const PROGRESS_MESSAGES: Record<GenerationProgress, string> = {
  idle: '',
  analyzing: 'Analyzing your request...',
  generating: 'Generating tasks and events...',
  organizing: 'Organizing results...',
  complete: 'Complete!',
}

const EXAMPLE_PROMPTS = [
  {
    title: 'Plan a trip',
    icon: 'airplane',
    prompt: 'Plan a 2-week trip to Japan next month including flights, hotels, and key sightseeing spots.',
  },
  {
    title: 'Weekly Meal Prep',
    icon: 'restaurant',
    prompt: 'Create a meal prep plan for next week with healthy dinners and a grocery list.',
  },
  {
    title: 'Project Launch',
    icon: 'rocket',
    prompt: 'Outline tasks for launching a new website marketing campaign starting next Monday.',
  },
  {
    title: 'House Cleaning',
    icon: 'home',
    prompt: 'Schedule a deep cleaning routine for my apartment for this weekend.',
  },
  {
    title: 'Birthday Party',
    icon: 'cake',
    prompt: 'Prepare for a birthday party next Saturday including invitations, decorations, and food.',
  },
  {
    title: 'Fitness Goals',
    icon: 'fitness',
    prompt: 'Create a workout routine for the next month with weekly gym sessions and progress milestones.',
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
  const [progress, setProgress] = useState<GenerationProgress>('idle')
  const [result, setResult] = useState<AiGenerateTasksResponse | null>(null)
  const [selectedTasks, setSelectedTasks] = useState<Set<number>>(new Set())
  const [selectedEvents, setSelectedEvents] = useState<Set<number>>(new Set())
  const [error, setError] = useState<string | null>(null)
  const [canRetry, setCanRetry] = useState(false)
  const [isCreating, setIsCreating] = useState(false)
  const [showModelSelector, setShowModelSelector] = useState(false)

  // Handle keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose()
      }
      if (e.key === 'Enter' && e.metaKey && prompt.trim() && !isGenerating) {
        handleGenerate()
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [prompt, isGenerating, onClose])

  const handleGenerate = useCallback(async () => {
    if (!prompt.trim()) return

    setIsGenerating(true)
    setError(null)
    setCanRetry(false)
    setProgress('analyzing')

    try {
      const context = {
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        current_date: new Date().toISOString(),
      }

      setProgress('generating')
      const response = await generateSmartTasks(token, prompt, context, selectedModelId || undefined)

      setProgress('organizing')
      setResult(response)

      // Select all by default
      setSelectedTasks(new Set(response.tasks.map((_, i) => i)))
      setSelectedEvents(new Set(response.events.map((_, i) => i)))
      setProgress('complete')
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to generate tasks'
      setError(errorMessage)
      // Allow retry for most errors except auth issues
      setCanRetry(!errorMessage.toLowerCase().includes('unauthorized'))
      setProgress('idle')
    } finally {
      setIsGenerating(false)
    }
  }, [prompt, token, selectedModelId])

  const handleCreate = async () => {
    if (!result) return

    setIsCreating(true)
    setError(null)

    try {
      const tasksToCreate = result.tasks.filter((_, i) => selectedTasks.has(i))
      const eventsToCreate = result.events.filter((_, i) => selectedEvents.has(i))

      await Promise.all([
        tasksToCreate.length > 0 ? onCreateTasks(tasksToCreate) : Promise.resolve(),
        eventsToCreate.length > 0 ? onCreateEvents(eventsToCreate) : Promise.resolve()
      ])

      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create items')
    } finally {
      setIsCreating(false)
    }
  }

  const handleReset = () => {
    setResult(null)
    setSelectedTasks(new Set())
    setSelectedEvents(new Set())
    setError(null)
    setProgress('idle')
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

  const toggleAllTasks = () => {
    if (!result) return
    if (selectedTasks.size === result.tasks.length) {
      setSelectedTasks(new Set())
    } else {
      setSelectedTasks(new Set(result.tasks.map((_, i) => i)))
    }
  }

  const toggleAllEvents = () => {
    if (!result) return
    if (selectedEvents.size === result.events.length) {
      setSelectedEvents(new Set())
    } else {
      setSelectedEvents(new Set(result.events.map((_, i) => i)))
    }
  }

  const selectedCount = selectedTasks.size + selectedEvents.size

  return (
    <div className="smart-generator-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="smart-generator-card">
        {/* Generation Progress Overlay */}
        {isGenerating && (
          <div className="generation-overlay">
            <div className="generation-content">
              <div className="sparkle-animation">
                <MdAutoAwesome className="sparkle-icon" size={48} />
              </div>
              <p className="progress-text">{PROGRESS_MESSAGES[progress]}</p>
              <div className="progress-bar">
                <div className={`progress-fill progress-${progress}`} />
              </div>
            </div>
          </div>
        )}

        <div className="smart-generator-header">
          <div className="header-left">
            <MdAutoAwesome className="header-icon" size={24} />
            <h2>AI Smart Generator</h2>
          </div>
          <button onClick={onClose} className="close-btn" aria-label="Close">
            <MdClose size={24} />
          </button>
        </div>

        {!result ? (
          <div className="smart-generator-content">
            {/* Hero Section */}
            <div className="hero-section">
              <div className="hero-icon">
                <MdAutoAwesome size={48} />
              </div>
              <h3>What would you like to create?</h3>
              <p>Describe your tasks, events, or plans in plain English</p>
            </div>

            <div className="input-section">
              <label className="input-label">Your Idea</label>
              <textarea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="Describe what you want to organize (e.g., 'Plan a birthday party for Sarah next Saturday')..."
                className="prompt-input"
                rows={4}
                disabled={isGenerating}
                autoFocus
              />
              <div className="char-count">{prompt.length} characters</div>

              <div className="actions-row">
                <button
                  type="button"
                  className="model-toggle-btn"
                  onClick={() => setShowModelSelector(!showModelSelector)}
                >
                  {selectedModelId ? `Model: ${selectedModelId.split(':').pop()}` : 'Using default model'}
                </button>
                <button
                  onClick={handleGenerate}
                  disabled={!prompt.trim() || isGenerating}
                  className="generate-btn"
                >
                  <MdAutoAwesome size={18} />
                  <span>Generate</span>
                </button>
              </div>

              {showModelSelector && (
                <div className="model-selector-wrapper">
                  <AiModelSelector
                    token={token}
                    showLabel={false}
                    className="model-selector"
                  />
                </div>
              )}

              <p className="keyboard-hint">
                Press <kbd>Cmd</kbd> + <kbd>Enter</kbd> to generate
              </p>
            </div>

            {error && (
              <div className="error-message">
                <span>{error}</span>
                {canRetry && (
                  <button onClick={handleGenerate} className="retry-btn">
                    <MdRefresh size={16} />
                    Retry
                  </button>
                )}
              </div>
            )}

            <div className="examples-section">
              <h3>Quick Examples</h3>
              <div className="examples-grid">
                {EXAMPLE_PROMPTS.map((ex, i) => (
                  <button
                    key={i}
                    onClick={() => setPrompt(ex.prompt)}
                    className="example-card"
                    disabled={isGenerating}
                  >
                    <span className="example-title">{ex.title}</span>
                    <span className="example-prompt">{ex.prompt}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="smart-generator-results">
            {/* Success Header */}
            <div className="results-header">
              <div className="success-icon">
                <MdCheck size={32} />
              </div>
              <div className="results-summary">
                <h3>Generated {result.tasks.length + result.events.length + result.smart_lists.length} items</h3>
                {result.metadata?.summary && (
                  <p className="summary-text">{result.metadata.summary}</p>
                )}
              </div>
              <button onClick={handleReset} className="start-over-btn">
                Start Over
              </button>
            </div>

            {result.metadata?.model && (
              <div className="model-badge-row">
                <span className="metadata-chip">Model: {result.metadata.model}</span>
              </div>
            )}

            {error && (
              <div className="error-message results-error">
                <span>{error}</span>
              </div>
            )}

            <div className="results-scroll">
              {result.tasks.length > 0 && (
                <div className="result-section">
                  <div className="section-header">
                    <div className="section-title">
                      <MdCheckBox className="section-icon tasks" />
                      <h3>Tasks ({result.tasks.length})</h3>
                    </div>
                    <button
                      type="button"
                      className="select-all-btn"
                      onClick={toggleAllTasks}
                    >
                      {selectedTasks.size === result.tasks.length ? 'Deselect All' : 'Select All'}
                    </button>
                  </div>
                  <div className="items-list">
                    {result.tasks.map((task, i) => (
                      <div
                        key={i}
                        className={`result-item ${selectedTasks.has(i) ? 'selected' : ''}`}
                        onClick={() => toggleTask(i)}
                        role="checkbox"
                        aria-checked={selectedTasks.has(i)}
                        tabIndex={0}
                        onKeyDown={(e) => e.key === 'Enter' && toggleTask(i)}
                      >
                        <div className="checkbox">
                          {selectedTasks.has(i) && <MdCheck size={14} />}
                        </div>
                        <div className="item-content">
                          <div className="item-title">{task.title}</div>
                          {task.description && (
                            <div className="item-description">{task.description}</div>
                          )}
                          <div className="item-meta">
                            {task.priority && (
                              <span className={`badge priority-${task.priority.toLowerCase()}`}>
                                {task.priority}
                              </span>
                            )}
                            {task.due_date && (
                              <span className="date">Due: {new Date(task.due_date).toLocaleDateString()}</span>
                            )}
                            {task.labels && task.labels.length > 0 && (
                              <span className="labels">{task.labels.join(', ')}</span>
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
                    <div className="section-title">
                      <MdEvent className="section-icon events" />
                      <h3>Events ({result.events.length})</h3>
                    </div>
                    <button
                      type="button"
                      className="select-all-btn"
                      onClick={toggleAllEvents}
                    >
                      {selectedEvents.size === result.events.length ? 'Deselect All' : 'Select All'}
                    </button>
                  </div>
                  <div className="items-list">
                    {result.events.map((event, i) => (
                      <div
                        key={i}
                        className={`result-item ${selectedEvents.has(i) ? 'selected' : ''}`}
                        onClick={() => toggleEvent(i)}
                        role="checkbox"
                        aria-checked={selectedEvents.has(i)}
                        tabIndex={0}
                        onKeyDown={(e) => e.key === 'Enter' && toggleEvent(i)}
                      >
                        <div className="checkbox">
                          {selectedEvents.has(i) && <MdCheck size={14} />}
                        </div>
                        <div className="item-content">
                          <div className="item-title">{event.title}</div>
                          {event.description && (
                            <div className="item-description">{event.description}</div>
                          )}
                          <div className="item-meta">
                            <span className="date">
                              {new Date(event.start_time).toLocaleString()}
                            </span>
                            {event.location && (
                              <span className="location">{event.location}</span>
                            )}
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
                    <div className="section-title">
                      <MdList className="section-icon lists" />
                      <h3>Smart Lists ({result.smart_lists.length})</h3>
                    </div>
                  </div>
                  <div className="smart-lists-grid">
                    {result.smart_lists.map((list, i) => (
                      <div key={i} className="smart-list-card">
                        <h4>{list.name}</h4>
                        {list.description && <p className="list-description">{list.description}</p>}
                        <ul>
                          {list.items.slice(0, 4).map((item, j) => (
                            <li key={j}>{item}</li>
                          ))}
                          {list.items.length > 4 && (
                            <li className="more">+{list.items.length - 4} more items</li>
                          )}
                        </ul>
                      </div>
                    ))}
                  </div>
                  <p className="smart-list-note">
                    Smart lists are for reference only and will not be created
                  </p>
                </div>
              )}
            </div>

            <div className="results-actions">
              <button onClick={handleReset} className="btn-secondary">
                Back
              </button>
              <button
                onClick={handleCreate}
                className="create-btn"
                disabled={selectedCount === 0 || isCreating}
              >
                {isCreating ? 'Creating...' : `Create ${selectedCount} Item${selectedCount !== 1 ? 's' : ''}`}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
