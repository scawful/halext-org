import type { FormEvent, KeyboardEvent } from 'react'
import type { Label } from '../../types/models'
import './CreatePanel.css'

type CreatePanelProps = {
  taskForm: { title: string; description: string; due_date: string }
  onTaskFormChange: (form: { title: string; description: string; due_date: string }) => void
  onTaskSubmit: (event: FormEvent) => void
  newTaskLabels: string[]
  taskLabelInput: string
  onTaskLabelInputChange: (value: string) => void
  onTaskLabelInputKeyDown: (event: KeyboardEvent<HTMLInputElement>) => void
  onAddTaskLabel: (label: string) => void
  onRemoveTaskLabel: (label: string) => void
  availableLabels: Label[]
  eventForm: {
    title: string
    description: string
    start_time: string
    end_time: string
    location: string
    recurrence_type: string
    recurrence_interval: number
    recurrence_end_date: string
  }
  onEventFormChange: (form: any) => void
  onEventSubmit: (event: FormEvent) => void
  pageForm: { title: string; description: string; visibility: string }
  onPageFormChange: (form: { title: string; description: string; visibility: string }) => void
  onPageSubmit: (event: FormEvent) => void
}

export const CreatePanel = ({
  taskForm,
  onTaskFormChange,
  onTaskSubmit,
  newTaskLabels,
  taskLabelInput,
  onTaskLabelInputChange,
  onTaskLabelInputKeyDown,
  onAddTaskLabel,
  onRemoveTaskLabel,
  availableLabels,
  eventForm,
  onEventFormChange,
  onEventSubmit,
  pageForm,
  onPageFormChange,
  onPageSubmit,
}: CreatePanelProps) => {
  const remainingSuggestions = availableLabels.filter((label) => !newTaskLabels.includes(label.name)).slice(0, 6)

  return (
    <div className="create-panel">
      <header className="create-panel-header">
        <div>
          <p className="muted">Creation Center</p>
          <h2>Spin up tasks, events, and dashboards</h2>
        </div>
      </header>

      <section className="creator-card">
        <div className="creator-card-header">
          <h3>Quick Task</h3>
          <p className="muted">Capture ideas with labels and due dates</p>
        </div>
        <form onSubmit={onTaskSubmit} className="creator-form">
          <input
            value={taskForm.title}
            onChange={(e) => onTaskFormChange({ ...taskForm, title: e.target.value })}
            placeholder="Task title"
            required
          />
          <textarea
            value={taskForm.description}
            onChange={(e) => onTaskFormChange({ ...taskForm, description: e.target.value })}
            placeholder="Description"
          />
          <div className="label-manager">
            <div className="label-chip-row">
              {newTaskLabels.map((label) => (
                <span key={label} className="label-chip">
                  {label}
                  <button type="button" onClick={() => onRemoveTaskLabel(label)}>
                    ×
                  </button>
                </span>
              ))}
            </div>
            <input
              value={taskLabelInput}
              onChange={(e) => onTaskLabelInputChange(e.target.value)}
              onKeyDown={onTaskLabelInputKeyDown}
              placeholder="Add label and press Enter"
            />
            {remainingSuggestions.length > 0 && (
              <div className="label-suggestions">
                {remainingSuggestions.map((label) => (
                  <button type="button" className="ghost-btn" key={label.id} onClick={() => onAddTaskLabel(label.name)}>
                    {label.name}
                  </button>
                ))}
              </div>
            )}
          </div>
          <label className="inline-field">
            <span>Due date</span>
            <input
              type="date"
              value={taskForm.due_date}
              onChange={(e) => onTaskFormChange({ ...taskForm, due_date: e.target.value })}
            />
          </label>
          <button type="submit">Add task</button>
        </form>
      </section>

      <section className="creator-card">
        <div className="creator-card-header">
          <h3>Schedule an Event</h3>
          <p className="muted">Block time, locations, and recurring cadence</p>
        </div>
        <form onSubmit={onEventSubmit} className="creator-form">
          <input
            value={eventForm.title}
            onChange={(e) => onEventFormChange({ ...eventForm, title: e.target.value })}
            placeholder="Event title"
            required
          />
          <textarea
            value={eventForm.description}
            onChange={(e) => onEventFormChange({ ...eventForm, description: e.target.value })}
            placeholder="Description"
          />
          <div className="creator-grid">
            <label>
              <span>Starts</span>
              <input
                type="datetime-local"
                value={eventForm.start_time}
                onChange={(e) => onEventFormChange({ ...eventForm, start_time: e.target.value })}
                required
              />
            </label>
            <label>
              <span>Ends</span>
              <input
                type="datetime-local"
                value={eventForm.end_time}
                onChange={(e) => onEventFormChange({ ...eventForm, end_time: e.target.value })}
                required
              />
            </label>
          </div>
          <input
            value={eventForm.location}
            onChange={(e) => onEventFormChange({ ...eventForm, location: e.target.value })}
            placeholder="Location"
          />
          <div className="creator-grid">
            <label>
              <span>Repeats</span>
              <select
                value={eventForm.recurrence_type}
                onChange={(e) => onEventFormChange({ ...eventForm, recurrence_type: e.target.value })}
              >
                <option value="none">Never</option>
                <option value="daily">Daily</option>
                <option value="weekly">Weekly</option>
                <option value="monthly">Monthly</option>
              </select>
            </label>
            {eventForm.recurrence_type !== 'none' && (
              <label>
                <span>Until</span>
                <input
                  type="date"
                  value={eventForm.recurrence_end_date}
                  onChange={(e) => onEventFormChange({ ...eventForm, recurrence_end_date: e.target.value })}
                />
              </label>
            )}
          </div>
          <button type="submit">Add event</button>
        </form>
      </section>

      <section className="creator-card">
        <div className="creator-card-header">
          <h3>New Dashboard Page</h3>
          <p className="muted">Create a blank layout to start placing widgets</p>
        </div>
        <form onSubmit={onPageSubmit} className="creator-form">
          <input
            value={pageForm.title}
            onChange={(e) => onPageFormChange({ ...pageForm, title: e.target.value })}
            placeholder="Page title"
            required
          />
          <textarea
            value={pageForm.description}
            onChange={(e) => onPageFormChange({ ...pageForm, description: e.target.value })}
            placeholder="Description"
          />
          <label className="inline-field">
            <span>Visibility</span>
            <select
              value={pageForm.visibility}
              onChange={(e) => onPageFormChange({ ...pageForm, visibility: e.target.value })}
            >
              <option value="private">Private</option>
              <option value="shared">Shared</option>
            </select>
          </label>
          <button type="submit">Create page</button>
        </form>
      </section>
    </div>
  )
}
