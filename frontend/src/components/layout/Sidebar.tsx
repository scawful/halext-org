import type { FormEvent } from 'react'
import type { Label } from '../../types/models'
import './Sidebar.css'

type SidebarProps = {
  // Task form
  taskForm: { title: string; description: string; due_date: string }
  onTaskFormChange: (form: { title: string; description: string; due_date: string }) => void
  onTaskSubmit: (event: FormEvent) => void
  newTaskLabels: string[]
  taskLabelInput: string
  onTaskLabelInputChange: (value: string) => void
  onTaskLabelInputKeyDown: (event: React.KeyboardEvent<HTMLInputElement>) => void
  onAddTaskLabel: (label: string) => void
  onRemoveTaskLabel: (label: string) => void
  availableLabels: Label[]

  // Event form
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

  // Page form
  pageForm: { title: string; description: string; visibility: string }
  onPageFormChange: (form: { title: string; description: string; visibility: string }) => void
  onPageSubmit: (event: FormEvent) => void

  user?: { full_name?: string | null; username: string } | null
  onLogout: () => void
}

export const Sidebar = ({
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
  user,
  onLogout,
}: SidebarProps) => {
  return (
    <aside className="sidebar">
      <div className="profile-section">
        <h2>Welcome back{user?.full_name ? `, ${user.full_name}` : ''}</h2>
        <p className="muted">@{user?.username}</p>
        <button onClick={onLogout} className="logout-btn">
          Logout
        </button>
      </div>

      <section className="sidebar-section">
        <h3>Tasks</h3>
        <form onSubmit={onTaskSubmit} className="form-stack">
          <input
            value={taskForm.title}
            onChange={(e) => onTaskFormChange({ ...taskForm, title: e.target.value })}
            placeholder="Task title"
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
            {availableLabels.filter((l) => !newTaskLabels.includes(l.name)).length > 0 && (
              <div className="label-suggestions">
                {availableLabels
                  .filter((l) => !newTaskLabels.includes(l.name))
                  .slice(0, 5)
                  .map((label) => (
                    <button
                      type="button"
                      key={label.id}
                      className="ghost-btn"
                      onClick={() => onAddTaskLabel(label.name)}
                    >
                      {label.name}
                    </button>
                  ))}
              </div>
            )}
          </div>
          <input
            type="date"
            value={taskForm.due_date}
            onChange={(e) => onTaskFormChange({ ...taskForm, due_date: e.target.value })}
          />
          <button type="submit">Add task</button>
        </form>
      </section>

      <section className="sidebar-section">
        <h3>Events</h3>
        <form onSubmit={onEventSubmit} className="form-stack">
          <input
            value={eventForm.title}
            onChange={(e) => onEventFormChange({ ...eventForm, title: e.target.value })}
            placeholder="Event title"
          />
          <textarea
            value={eventForm.description}
            onChange={(e) => onEventFormChange({ ...eventForm, description: e.target.value })}
            placeholder="Description"
          />
          <input
            type="datetime-local"
            value={eventForm.start_time}
            onChange={(e) => onEventFormChange({ ...eventForm, start_time: e.target.value })}
          />
          <input
            type="datetime-local"
            value={eventForm.end_time}
            onChange={(e) => onEventFormChange({ ...eventForm, end_time: e.target.value })}
          />
          <input
            value={eventForm.location}
            onChange={(e) => onEventFormChange({ ...eventForm, location: e.target.value })}
            placeholder="Location"
          />
          <div className="recurrence-row">
            <label>
              Repeats
              <select
                value={eventForm.recurrence_type}
                onChange={(e) =>
                  onEventFormChange({ ...eventForm, recurrence_type: e.target.value })
                }
              >
                <option value="none">Never</option>
                <option value="daily">Daily</option>
                <option value="weekly">Weekly</option>
                <option value="monthly">Monthly</option>
              </select>
            </label>
            {eventForm.recurrence_type !== 'none' && (
              <>
                <label>
                  Every
                  <input
                    type="number"
                    min="1"
                    value={eventForm.recurrence_interval}
                    onChange={(e) =>
                      onEventFormChange({
                        ...eventForm,
                        recurrence_interval: Number(e.target.value) || 1,
                      })
                    }
                  />
                </label>
                <label>
                  Until
                  <input
                    type="date"
                    value={eventForm.recurrence_end_date}
                    onChange={(e) =>
                      onEventFormChange({ ...eventForm, recurrence_end_date: e.target.value })
                    }
                  />
                </label>
              </>
            )}
          </div>
          <button type="submit">Add event</button>
        </form>
      </section>

      <section className="sidebar-section">
        <h3>New Page</h3>
        <form onSubmit={onPageSubmit} className="form-stack">
          <input
            value={pageForm.title}
            onChange={(e) => onPageFormChange({ ...pageForm, title: e.target.value })}
            placeholder="Page title"
          />
          <textarea
            value={pageForm.description}
            onChange={(e) => onPageFormChange({ ...pageForm, description: e.target.value })}
            placeholder="Description"
          />
          <select
            value={pageForm.visibility}
            onChange={(e) => onPageFormChange({ ...pageForm, visibility: e.target.value })}
          >
            <option value="private">Private</option>
            <option value="shared">Shared</option>
          </select>
          <button type="submit">Create page</button>
        </form>
      </section>
    </aside>
  )
}
