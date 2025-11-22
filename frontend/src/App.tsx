import { useEffect, useState } from 'react'
import type { FormEvent, KeyboardEvent } from 'react'
import { MdAutoAwesome } from 'react-icons/md'
import { MenuBar } from './components/layout/MenuBar'
import { CreatePanel } from './components/pages/CreatePanel'
import { DashboardGrid } from './components/layout/DashboardGrid'
import { ImageGenerationSection } from './components/sections/ImageGenerationSection'
import { AnimeSection } from './components/sections/AnimeSection'
import { CalendarSection } from './components/sections/CalendarSection'
import { IoTSection } from './components/sections/IoTSection'
import { ChatSection } from './components/sections/ChatSection'
import { TasksPage } from './components/pages/TasksPage'
import { AdminSection } from './components/sections/AdminSection'
import { SettingsSection } from './components/sections/SettingsSection'
import { RecipeSection } from './components/sections/RecipeSection'
import { SmartTaskGenerator } from './components/ai/SmartTaskGenerator'
import { FinanceSection } from './components/sections/FinanceSection'
import { SocialSection } from './components/sections/SocialSection'

import { useUIStore } from './stores/useUIStore'
import { useAuthStore } from './stores/useAuthStore'
import { useDataStore } from './stores/useDataStore'
import './App.css'

type TaskUpdateInput = { labels?: string[] } & Record<string, any>

function App() {
  // Store hooks
  const { 
    isLoading, 
    appMessage, 
    activeSection, 
    isCreateOverlayOpen, 
    isSmartGenOpen,
    setCreateOverlayOpen,
    setSmartGenOpen
  } = useUIStore()
  
  const { 
    token, 
    accessCode, 
    authError, 
    authMode,
    setAccessCode,
    setAuthMode,
    login,
    register
  } = useAuthStore()
  
  const { 
    events,
    availableLabels,
    loadWorkspace,
    createTask,
    updateTask,
    deleteTask,
    createEvent,
    createPage
  } = useDataStore()

  // Local state for forms (kept local as they are transient)
  const [taskForm, setTaskForm] = useState({ title: '', description: '', due_date: '' })
  const [newTaskLabels, setNewTaskLabels] = useState<string[]>([])
  const [taskLabelInput, setTaskLabelInput] = useState('')
  const [eventForm, setEventForm] = useState({
    title: '',
    description: '',
    start_time: '',
    end_time: '',
    location: '',
    recurrence_type: 'none',
    recurrence_interval: 1,
    recurrence_end_date: '',
  })
  const [pageForm, setPageForm] = useState({ title: '', description: '', visibility: 'private' })

  // Effects
  useEffect(() => {
    if (token) {
      loadWorkspace()
    }
  }, [token, loadWorkspace])

  // Handlers
  const handleLogin = async (event: FormEvent) => {
    event.preventDefault()
    const form = event.target as HTMLFormElement
    const formData = new FormData(form)
    const username = formData.get('username') as string
    const password = formData.get('password') as string
    
    if (!username || !password) return

    const payload = new URLSearchParams()
    payload.set('username', username)
    payload.set('password', password)
    payload.set('grant_type', 'password')
    
    try {
      await login(payload)
    } catch {
      // Error handled in store
    }
  }

  const handleRegister = async (event: FormEvent) => {
    event.preventDefault()
    const formData = new FormData(event.target as HTMLFormElement)
    const payload = {
      username: formData.get('username'),
      password: formData.get('password'),
      email: formData.get('email'),
      full_name: formData.get('full_name'),
    }
    
    try {
      await register(payload)
    } catch {
      // Error handled in store
    }
  }

  const handleCreateTask = async (event: FormEvent) => {
    event.preventDefault()
    if (!taskForm.title.trim()) return
    
    await createTask({
      title: taskForm.title,
      description: taskForm.description || undefined,
      due_date: taskForm.due_date ? new Date(taskForm.due_date).toISOString() : undefined,
      labels: newTaskLabels,
    })
    
    setTaskForm({ title: '', description: '', due_date: '' })
    setNewTaskLabels([])
    setTaskLabelInput('')
  }

  const handleCreateTaskDirect = async (payload: {
    title: string
    description?: string
    due_date?: string
    labels: string[]
  }) => {
    await createTask({
      ...payload,
      due_date: payload.due_date ? new Date(payload.due_date).toISOString() : undefined,
    })
  }

  const handleCreateTasks = async (newTasks: any[]) => {
    for (const task of newTasks) {
      await handleCreateTaskDirect(task)
    }
  }

  const handleUpdateTask = async (id: number, updates: TaskUpdateInput) => {
    const payload: any = { ...updates }
    if (payload.due_date) {
      payload.due_date = new Date(payload.due_date).toISOString()
    }
    await updateTask(id, payload)
  }

  const handleCreateEvent = async (event: FormEvent) => {
    event.preventDefault()
    if (!eventForm.title || !eventForm.start_time || !eventForm.end_time) return
    
    await createEvent({
      title: eventForm.title,
      description: eventForm.description || undefined,
      start_time: new Date(eventForm.start_time).toISOString(),
      end_time: new Date(eventForm.end_time).toISOString(),
      location: eventForm.location || undefined,
      recurrence_type: eventForm.recurrence_type,
      recurrence_interval: Number(eventForm.recurrence_interval) || 1,
      recurrence_end_date: eventForm.recurrence_end_date ? new Date(eventForm.recurrence_end_date).toISOString() : undefined,
    })
    
    setEventForm({ title: '', description: '', start_time: '', end_time: '', location: '', recurrence_type: 'none', recurrence_interval: 1, recurrence_end_date: '' })
  }

  const handleCreateEvents = async (newEvents: any[]) => {
    for (const event of newEvents) {
      await createEvent(event)
    }
  }

  const handleCreatePage = async (event: FormEvent) => {
    event.preventDefault()
    if (!pageForm.title.trim()) return
    
    await createPage({
      title: pageForm.title,
      description: pageForm.description || undefined,
      visibility: pageForm.visibility,
    })
    
    setPageForm({ title: '', description: '', visibility: 'private' })
  }

  const addTaskLabel = (labelName: string) => {
    const normalized = labelName.trim()
    if (!normalized) return
    if (!newTaskLabels.includes(normalized)) {
      setNewTaskLabels((prev) => [...prev, normalized])
    }
    setTaskLabelInput('')
  }

  const handleLabelInputKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter' || event.key === ',') {
      event.preventDefault()
      addTaskLabel(taskLabelInput)
    }
  }

  const removeTaskLabel = (label: string) => {
    setNewTaskLabels((prev) => prev.filter((item) => item !== label))
  }

  if (!token) {
    return (
      <div className="auth-shell">
        <div className="auth-logo">☕</div>
        <h1>Cafe</h1>
        <p className="muted">Your productivity companion for tasks, calendar, and AI assistance.</p>
        <div className="auth-card">
          <div className="stack">
            <label>
              Access code (registration only)
              <input
                value={accessCode}
                onChange={(event) => setAccessCode(event.target.value)}
                placeholder="Shared code"
                autoComplete="one-time-code"
                required={authMode === 'register'}
              />
              <span className="muted">Only needed the first time you register.</span>
            </label>
          </div>
          <div className="auth-toggle">
            <button className={authMode === 'login' ? 'active' : ''} onClick={() => setAuthMode('login')}>
              Login
            </button>
            <button className={authMode === 'register' ? 'active' : ''} onClick={() => setAuthMode('register')}>
              Register
            </button>
          </div>
          {authMode === 'login' ? (
            <form onSubmit={handleLogin} className="stack" autoComplete="on">
              <label>
                Username
                <input
                  name="username"
                  type="text"
                  inputMode="text"
                  placeholder="Your username"
                  autoComplete="username"
                  autoCapitalize="none"
                  autoCorrect="off"
                  spellCheck={false}
                  required
                />
              </label>
              <label>
                Password
                <input
                  name="password"
                  type="password"
                  placeholder="Password"
                  autoComplete="current-password"
                  autoCapitalize="none"
                  autoCorrect="off"
                  required
                />
              </label>
              <button type="submit" disabled={isLoading}>
                Sign in
              </button>
            </form>
          ) : (
            <form onSubmit={handleRegister} className="stack" autoComplete="on">
              <label>
                Username
                <input
                  name="username"
                  type="text"
                  inputMode="text"
                  placeholder="Choose a username"
                  autoComplete="username"
                  autoCapitalize="none"
                  autoCorrect="off"
                  spellCheck={false}
                  required
                />
              </label>
              <label>
                Full name
                <input name="full_name" placeholder="Full name" autoComplete="name" />
              </label>
              <label>
                Email
                <input name="email" type="email" placeholder="you@example.com" autoComplete="email" required />
              </label>
              <label>
                Password
                <input
                  name="password"
                  type="password"
                  placeholder="Create a password"
                  autoComplete="new-password"
                  autoCapitalize="none"
                  autoCorrect="off"
                  required
                />
              </label>
              <button type="submit" disabled={isLoading}>
                Create account
              </button>
            </form>
          )}
          {authError && <p className="error">{authError}</p>}
          {appMessage && <p className="muted">{appMessage}</p>}
        </div>
      </div>
    )
  }

  const renderSection = () => {
    switch (activeSection) {
      case 'dashboard':
        return <DashboardGrid />
      case 'tasks':
        return (
          <TasksPage
            token={token}
            tasks={useDataStore.getState().tasks} // We can access state directly if needed, or pass it. 
            // Better: TasksPage should use useDataStore internally. But for now, passing from state to avoid refactoring everything at once.
            availableLabels={availableLabels}
            onCreateTask={handleCreateTaskDirect}
            onUpdateTask={handleUpdateTask}
            onDeleteTask={deleteTask}
          />
        )
      case 'calendar':
        return <CalendarSection events={events} />
      case 'chat':
        return <ChatSection token={token} />
      case 'recipes':
        return <RecipeSection token={token} />
      case 'finance':
        return <FinanceSection token={token} />
      case 'social':
        return <SocialSection token={token} />
      case 'image-gen':
        return <ImageGenerationSection token={token} />
      case 'anime':
        return <AnimeSection />
      case 'iot':
        return <IoTSection />
      case 'settings':
        return <SettingsSection token={token} />
      case 'admin':
        return <AdminSection token={token} />
      default:
        return null
    }
  }

  return (
    <div className="app-container">
      <MenuBar />
      <div className="app-main">
        <main className="main-content">
          <div className="workspace-shell">{renderSection()}</div>
        </main>
        
        <div className="floating-actions">
          <button
            className="floating-btn ai-btn"
            onClick={() => setSmartGenOpen(true)}
            aria-label="AI Smart Generator"
            title="AI Smart Generator"
          >
            <MdAutoAwesome size={24} />
          </button>
          <button
            className="floating-btn create-btn"
            onClick={() => setCreateOverlayOpen(true)}
            aria-label="Open creation panel"
            title="Create New"
          >
            <span>+</span>
          </button>
        </div>
        
        {isCreateOverlayOpen && (
          <div className="create-overlay" role="dialog" aria-modal="true">
            <div className="create-overlay-card">
              <button
                className="overlay-close"
                onClick={() => setCreateOverlayOpen(false)}
                aria-label="Close creation panel"
              >
                ×
              </button>
              <CreatePanel
                taskForm={taskForm}
                onTaskFormChange={setTaskForm}
                onTaskSubmit={handleCreateTask}
                newTaskLabels={newTaskLabels}
                taskLabelInput={taskLabelInput}
                onTaskLabelInputChange={setTaskLabelInput}
                onTaskLabelInputKeyDown={handleLabelInputKeyDown}
                onAddTaskLabel={addTaskLabel}
                onRemoveTaskLabel={removeTaskLabel}
                availableLabels={availableLabels}
                eventForm={eventForm}
                onEventFormChange={setEventForm}
                onEventSubmit={handleCreateEvent}
                pageForm={pageForm}
                onPageFormChange={setPageForm}
                onPageSubmit={handleCreatePage}
              />
            </div>
          </div>
        )}
        {isSmartGenOpen && (
          <SmartTaskGenerator
            token={token}
            onClose={() => setSmartGenOpen(false)}
            onCreateTasks={handleCreateTasks}
            onCreateEvents={handleCreateEvents}
          />
        )}
      </div>
    </div>
  )
}

export default App