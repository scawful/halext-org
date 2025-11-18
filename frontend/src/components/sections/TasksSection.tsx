import { useState, FormEvent } from 'react'
import { MdAdd, MdClose, MdEdit, MdDelete, MdCheckCircle, MdRadioButtonUnchecked, MdAutoAwesome } from 'react-icons/md'
import { AiTaskAssistant } from '../ai/AiTaskAssistant'
import type { Task, Label } from '../../types/models'
import type { AiTaskSuggestion } from '../../utils/aiApi'
import './TasksSection.css'

interface TasksSectionProps {
  token: string
  tasks: Task[]
  availableLabels: Label[]
  onCreateTask: (task: {
    title: string
    description?: string
    due_date?: string
    labels: string[]
  }) => Promise<void>
  onUpdateTask: (id: number, completed: boolean) => Promise<void>
  onDeleteTask: (id: number) => Promise<void>
}

type FilterType = 'all' | 'active' | 'completed'
type SortType = 'created' | 'due_date' | 'priority'

export const TasksSection = ({
  token,
  tasks,
  availableLabels,
  onCreateTask,
  onUpdateTask,
  onDeleteTask,
}: TasksSectionProps) => {
  const [showNewTask, setShowNewTask] = useState(false)
  const [taskForm, setTaskForm] = useState({
    title: '',
    description: '',
    due_date: '',
    labels: [] as string[],
  })
  const [filter, setFilter] = useState<FilterType>('active')
  const [sort, setSort] = useState<SortType>('created')
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedLabelFilter, setSelectedLabelFilter] = useState<string | null>(null)
  const [showAiAssistant, setShowAiAssistant] = useState(false)
  const [isCreating, setIsCreating] = useState(false)

  // Filter and sort tasks
  const filteredTasks = tasks
    .filter((task) => {
      // Filter by completion status
      if (filter === 'active' && task.completed) return false
      if (filter === 'completed' && !task.completed) return false

      // Filter by search query
      if (searchQuery && !task.title.toLowerCase().includes(searchQuery.toLowerCase())) {
        return false
      }

      // Filter by label
      if (selectedLabelFilter) {
        return task.labels.some((label) => label.name === selectedLabelFilter)
      }

      return true
    })
    .sort((a, b) => {
      switch (sort) {
        case 'due_date':
          if (!a.due_date) return 1
          if (!b.due_date) return -1
          return new Date(a.due_date).getTime() - new Date(b.due_date).getTime()
        case 'priority':
          // For now, tasks with due dates are higher priority
          if (!a.due_date) return 1
          if (!b.due_date) return -1
          return new Date(a.due_date).getTime() - new Date(b.due_date).getTime()
        case 'created':
        default:
          return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
      }
    })

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    if (!taskForm.title.trim()) return

    setIsCreating(true)
    try {
      await onCreateTask({
        title: taskForm.title,
        description: taskForm.description || undefined,
        due_date: taskForm.due_date || undefined,
        labels: taskForm.labels,
      })
      setTaskForm({ title: '', description: '', due_date: '', labels: [] })
      setShowNewTask(false)
      setShowAiAssistant(false)
    } finally {
      setIsCreating(false)
    }
  }

  const handleApplyAiSuggestions = (suggestions: AiTaskSuggestion) => {
    setTaskForm((prev) => ({
      ...prev,
      labels: [...new Set([...prev.labels, ...suggestions.labels])],
    }))
  }

  const addLabel = (labelName: string) => {
    if (!taskForm.labels.includes(labelName)) {
      setTaskForm((prev) => ({
        ...prev,
        labels: [...prev.labels, labelName],
      }))
    }
  }

  const removeLabel = (labelName: string) => {
    setTaskForm((prev) => ({
      ...prev,
      labels: prev.labels.filter((l) => l !== labelName),
    }))
  }

  const activeTasks = tasks.filter((t) => !t.completed).length
  const completedTasks = tasks.filter((t) => t.completed).length

  return (
    <div className="tasks-section">
      <div className="tasks-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">Tasks</h2>
          <p className="text-sm text-gray-400 mt-1">
            {activeTasks} active • {completedTasks} completed
          </p>
        </div>
        <button
          onClick={() => setShowNewTask(!showNewTask)}
          className="btn-primary"
        >
          <MdAdd size={20} />
          New Task
        </button>
      </div>

      {/* New Task Form */}
      {showNewTask && (
        <div className="task-form-card">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold text-purple-300">Create New Task</h3>
            <button
              onClick={() => {
                setShowNewTask(false)
                setShowAiAssistant(false)
                setTaskForm({ title: '', description: '', due_date: '', labels: [] })
              }}
              className="text-gray-400 hover:text-white transition-colors"
            >
              <MdClose size={24} />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm text-gray-300 mb-2">Title *</label>
              <input
                type="text"
                value={taskForm.title}
                onChange={(e) => setTaskForm((prev) => ({ ...prev, title: e.target.value }))}
                placeholder="What needs to be done?"
                className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded focus:outline-none focus:border-purple-500 text-white"
                required
              />
            </div>

            <div>
              <label className="block text-sm text-gray-300 mb-2">Description</label>
              <textarea
                value={taskForm.description}
                onChange={(e) => setTaskForm((prev) => ({ ...prev, description: e.target.value }))}
                placeholder="Add more details..."
                className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded focus:outline-none focus:border-purple-500 text-white resize-none"
                rows={3}
              />
            </div>

            <div>
              <label className="block text-sm text-gray-300 mb-2">Due Date</label>
              <input
                type="datetime-local"
                value={taskForm.due_date}
                onChange={(e) => setTaskForm((prev) => ({ ...prev, due_date: e.target.value }))}
                className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded focus:outline-none focus:border-purple-500 text-white"
              />
            </div>

            <div>
              <label className="block text-sm text-gray-300 mb-2">Labels</label>
              <div className="flex flex-wrap gap-2 mb-2">
                {taskForm.labels.map((labelName) => {
                  const label = availableLabels.find((l) => l.name === labelName)
                  return (
                    <span
                      key={labelName}
                      className="inline-flex items-center gap-1 px-2 py-1 rounded text-xs"
                      style={{
                        backgroundColor: label?.color ? `${label.color}20` : '#9333ea20',
                        borderColor: label?.color || '#9333ea',
                        borderWidth: '1px',
                        color: label?.color || '#9333ea',
                      }}
                    >
                      {labelName}
                      <button
                        type="button"
                        onClick={() => removeLabel(labelName)}
                        className="hover:opacity-70"
                      >
                        <MdClose size={14} />
                      </button>
                    </span>
                  )
                })}
              </div>
              <div className="flex flex-wrap gap-2">
                {availableLabels
                  .filter((label) => !taskForm.labels.includes(label.name))
                  .map((label) => (
                    <button
                      key={label.id}
                      type="button"
                      onClick={() => addLabel(label.name)}
                      className="px-2 py-1 rounded text-xs transition-opacity hover:opacity-80"
                      style={{
                        backgroundColor: `${label.color}20`,
                        borderColor: label.color,
                        borderWidth: '1px',
                        color: label.color,
                      }}
                    >
                      + {label.name}
                    </button>
                  ))}
              </div>
            </div>

            {/* AI Assistant Toggle */}
            <button
              type="button"
              onClick={() => setShowAiAssistant(!showAiAssistant)}
              className="flex items-center gap-2 text-sm text-purple-300 hover:text-purple-200 transition-colors"
            >
              <MdAutoAwesome size={18} />
              {showAiAssistant ? 'Hide' : 'Show'} AI Suggestions
            </button>

            {showAiAssistant && (
              <AiTaskAssistant
                token={token}
                taskTitle={taskForm.title}
                taskDescription={taskForm.description}
                onApplySuggestions={handleApplyAiSuggestions}
              />
            )}

            <div className="flex gap-2 pt-4">
              <button
                type="submit"
                disabled={isCreating || !taskForm.title.trim()}
                className="flex-1 px-4 py-2 bg-purple-600 hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed rounded transition-colors font-medium"
              >
                {isCreating ? 'Creating...' : 'Create Task'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowNewTask(false)
                  setShowAiAssistant(false)
                  setTaskForm({ title: '', description: '', due_date: '', labels: [] })
                }}
                className="px-4 py-2 bg-white/10 hover:bg-white/20 rounded transition-colors"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Filters and Search */}
      <div className="tasks-filters">
        <div className="flex items-center gap-2 flex-wrap">
          <button
            onClick={() => setFilter('all')}
            className={`filter-btn ${filter === 'all' ? 'active' : ''}`}
          >
            All ({tasks.length})
          </button>
          <button
            onClick={() => setFilter('active')}
            className={`filter-btn ${filter === 'active' ? 'active' : ''}`}
          >
            Active ({activeTasks})
          </button>
          <button
            onClick={() => setFilter('completed')}
            className={`filter-btn ${filter === 'completed' ? 'active' : ''}`}
          >
            Completed ({completedTasks})
          </button>

          <div className="ml-auto flex items-center gap-2">
            <select
              value={sort}
              onChange={(e) => setSort(e.target.value as SortType)}
              className="px-3 py-1.5 bg-white/10 border border-white/20 rounded text-sm text-white focus:outline-none focus:border-purple-500"
            >
              <option value="created">Recently Created</option>
              <option value="due_date">Due Date</option>
              <option value="priority">Priority</option>
            </select>
          </div>
        </div>

        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search tasks..."
          className="w-full px-3 py-2 bg-white/10 border border-white/20 rounded focus:outline-none focus:border-purple-500 text-white text-sm"
        />

        {/* Label filters */}
        {availableLabels.length > 0 && (
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => setSelectedLabelFilter(null)}
              className={`px-2 py-1 rounded text-xs transition-colors ${
                selectedLabelFilter === null
                  ? 'bg-purple-600 text-white'
                  : 'bg-white/10 text-gray-300 hover:bg-white/20'
              }`}
            >
              All Labels
            </button>
            {availableLabels.map((label) => (
              <button
                key={label.id}
                onClick={() =>
                  setSelectedLabelFilter(selectedLabelFilter === label.name ? null : label.name)
                }
                className={`px-2 py-1 rounded text-xs transition-opacity hover:opacity-80`}
                style={{
                  backgroundColor:
                    selectedLabelFilter === label.name ? label.color : `${label.color}20`,
                  borderColor: label.color,
                  borderWidth: '1px',
                  color: selectedLabelFilter === label.name ? 'white' : label.color,
                }}
              >
                {label.name}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Task List */}
      <div className="tasks-list">
        {filteredTasks.length === 0 ? (
          <div className="empty-state">
            <p className="text-gray-400">
              {searchQuery || selectedLabelFilter
                ? 'No tasks match your filters'
                : filter === 'completed'
                ? 'No completed tasks yet'
                : 'No active tasks. Create one to get started!'}
            </p>
          </div>
        ) : (
          filteredTasks.map((task) => (
            <TaskItem
              key={task.id}
              task={task}
              onToggle={() => onUpdateTask(task.id, !task.completed)}
              onDelete={() => onDeleteTask(task.id)}
            />
          ))
        )}
      </div>
    </div>
  )
}

interface TaskItemProps {
  task: Task
  onToggle: () => void
  onDelete: () => void
}

const TaskItem = ({ task, onToggle, onDelete }: TaskItemProps) => {
  const [showDetails, setShowDetails] = useState(false)

  const isOverdue =
    task.due_date && !task.completed && new Date(task.due_date) < new Date()

  return (
    <div className={`task-item ${task.completed ? 'completed' : ''}`}>
      <div className="task-item-main">
        <button onClick={onToggle} className="task-checkbox">
          {task.completed ? (
            <MdCheckCircle size={24} className="text-green-500" />
          ) : (
            <MdRadioButtonUnchecked size={24} className="text-gray-400 hover:text-purple-400" />
          )}
        </button>

        <div className="task-content" onClick={() => setShowDetails(!showDetails)}>
          <h3 className={`task-title ${task.completed ? 'line-through text-gray-500' : ''}`}>
            {task.title}
          </h3>

          <div className="task-meta">
            {task.due_date && (
              <span className={`task-due-date ${isOverdue ? 'overdue' : ''}`}>
                Due: {new Date(task.due_date).toLocaleDateString()}
              </span>
            )}
            {task.labels && task.labels.length > 0 && (
              <div className="task-labels">
                {task.labels.map((label) => (
                  <span
                    key={label.id}
                    className="task-label"
                    style={{
                      backgroundColor: `${label.color}20`,
                      borderColor: label.color,
                      color: label.color,
                    }}
                  >
                    {label.name}
                  </span>
                ))}
              </div>
            )}
          </div>

          {showDetails && task.description && (
            <p className="task-description">{task.description}</p>
          )}
        </div>

        <div className="task-actions">
          <button
            onClick={(e) => {
              e.stopPropagation()
              setShowDetails(!showDetails)
            }}
            className="task-action-btn"
            title="View details"
          >
            <MdEdit size={18} />
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              if (confirm('Delete this task?')) {
                onDelete()
              }
            }}
            className="task-action-btn text-red-400 hover:text-red-300"
            title="Delete task"
          >
            <MdDelete size={18} />
          </button>
        </div>
      </div>
    </div>
  )
}
