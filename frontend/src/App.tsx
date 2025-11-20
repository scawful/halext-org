import type { FormEvent, KeyboardEvent } from 'react'
import { useCallback, useEffect, useState } from 'react'
import { MenuBar } from './components/layout/MenuBar'
import type { MenuSection } from './components/layout/MenuBar'
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
import type {
  Task,
  EventItem,
  PageDetail,
  User,
  OpenWebUiStatus,
  Label,
  LayoutWidget,
  WidgetType
} from './types/models'
import { API_BASE_URL, createDefaultLayout, createWidget, randomId } from './utils/helpers'
import './App.css'

type TaskUpdateInput = Partial<Omit<Task, 'labels'>> & { labels?: string[] }

function App() {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('halext_token'))
  const [accessCode, setAccessCode] = useState<string>(() => localStorage.getItem('halext_access_code') ?? '')
  const [authMode, setAuthMode] = useState<'login' | 'register'>('login')
  const [authError, setAuthError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [user, setUser] = useState<User | null>(null)
  const [tasks, setTasks] = useState<Task[]>([])
  const [events, setEvents] = useState<EventItem[]>([])
  const [pages, setPages] = useState<PageDetail[]>([])
  const [selectedPageId, setSelectedPageId] = useState<number | null>(null)
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
  const [appMessage, setAppMessage] = useState<string | null>(null)
  const [openwebui, setOpenwebui] = useState<OpenWebUiStatus | null>(null)
  const [availableLabels, setAvailableLabels] = useState<Label[]>([])
  const [activeSection, setActiveSection] = useState<MenuSection>('dashboard')

  const logout = useCallback(() => {
    localStorage.removeItem('halext_token')
    localStorage.removeItem('halext_access_code')
    setToken(null)
    setUser(null)
    setTasks([])
    setEvents([])
    setPages([])
  }, [])

  useEffect(() => {
    if (accessCode) {
      localStorage.setItem('halext_access_code', accessCode)
    } else {
      localStorage.removeItem('halext_access_code')
    }
  }, [accessCode])

  const authorizedFetch = useCallback(
    async <T,>(path: string, options: RequestInit = {}): Promise<T> => {
      if (!token) {
        throw new Error('You need to sign in first')
      }
      const headers = new Headers(options.headers)
      if (!(options.body instanceof FormData) && !headers.has('Content-Type') && options.method && options.method !== 'GET') {
        headers.set('Content-Type', 'application/json')
      }
      headers.set('Authorization', `Bearer ${token}`)
      const response = await fetch(`${API_BASE_URL}${path}`, {
        ...options,
        headers,
      })
      if (response.status === 401) {
        logout()
        throw new Error('Session expired. Please sign in again.')
      }
      if (!response.ok) {
        const text = await response.text()
        throw new Error(text || 'Request failed')
      }
      if (response.status === 204) {
        return null as T
      }
      const text = await response.text()
      return text ? (JSON.parse(text) as T) : (null as T)
    },
    [logout, token],
  )

  const loadWorkspace = useCallback(async () => {
    if (!token) return
    setIsLoading(true)
    try {
      const [
        profile,
        tasksResponse,
        eventsResponse,
        pagesResponse,
        openwebuiResponse,
        labelsResponse,
      ] = await Promise.all([
        authorizedFetch<User>('/users/me/'),
        authorizedFetch<Task[]>('/tasks/'),
        authorizedFetch<EventItem[]>('/events/'),
        authorizedFetch<PageDetail[]>('/pages/'),
        authorizedFetch<OpenWebUiStatus>('/integrations/openwebui'),
        authorizedFetch<Label[]>('/labels/'),
      ])
      setUser(profile)
      setTasks(tasksResponse)
      setEvents(eventsResponse)
      setPages(pagesResponse)
      setOpenwebui(openwebuiResponse)
      setAvailableLabels(labelsResponse)
      if (pagesResponse.length > 0) {
        setSelectedPageId((current) => current ?? pagesResponse[0].id)
      }
      setAppMessage('Synced with Cafe servers.')
    } catch (error) {
      setAppMessage((error as Error).message)
    } finally {
      setIsLoading(false)
    }
  }, [authorizedFetch, token])

  useEffect(() => {
    if (token) {
      loadWorkspace()
    }
  }, [token, loadWorkspace])

  const handleLogin = async (event: FormEvent) => {
    event.preventDefault()
    setAuthError(null)
    const form = event.target as HTMLFormElement
    const formData = new FormData(form)
    const username = formData.get('username') as string
    const password = formData.get('password') as string
    if (!username || !password) {
      setAuthError('Username and password are required')
      return
    }
    setIsLoading(true)
    try {
      const payload = new URLSearchParams()
      payload.set('username', username)
      payload.set('password', password)
      payload.set('grant_type', 'password')
      const response = await fetch(`${API_BASE_URL}/token`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: payload,
      })
      if (!response.ok) {
        throw new Error('Invalid credentials')
      }
      const data = await response.json()
      localStorage.setItem('halext_token', data.access_token)
      setToken(data.access_token)
    } catch (error) {
      setAuthError((error as Error).message)
    } finally {
      setIsLoading(false)
    }
  }

  const handleRegister = async (event: FormEvent) => {
    event.preventDefault()
    setAuthError(null)
    if (!accessCode.trim()) {
      setAuthError('Access code is required.')
      return
    }
    const formData = new FormData(event.target as HTMLFormElement)
    const payload = {
      username: formData.get('username'),
      password: formData.get('password'),
      email: formData.get('email'),
      full_name: formData.get('full_name'),
    }
    if (!payload.username || !payload.password || !payload.email) {
      setAuthError('Please fill in username, email, and password.')
      return
    }
    setIsLoading(true)
    try {
      await fetch(`${API_BASE_URL}/users/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Halext-Code': accessCode.trim(),
        },
        body: JSON.stringify(payload),
      }).then((response) => {
        if (!response.ok) {
          throw new Error('Unable to register right now.')
        }
      })
      setAuthMode('login')
      setAppMessage('Account ready! Sign in to continue.')
    } catch (error) {
      setAuthError((error as Error).message)
    } finally {
      setIsLoading(false)
    }
  }

  const handleCreateTask = async (event: FormEvent) => {
    event.preventDefault()
    if (!taskForm.title.trim()) return
    const payload = {
      title: taskForm.title,
      description: taskForm.description || undefined,
      due_date: taskForm.due_date ? new Date(taskForm.due_date).toISOString() : undefined,
      labels: newTaskLabels,
    }
    const task = await authorizedFetch<Task>('/tasks/', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
    setTasks((prev) => [task, ...prev])
    setTaskForm({ title: '', description: '', due_date: '' })
    setNewTaskLabels([])
    setTaskLabelInput('')
    const mergedLabels = [...availableLabels]
    task.labels.forEach((label) => {
      if (!mergedLabels.some((existing) => existing.id === label.id)) {
        mergedLabels.push(label)
      }
    })
    setAvailableLabels(mergedLabels)
  }

  const handleCreateTaskDirect = async (payload: {
    title: string
    description?: string
    due_date?: string
    labels: string[]
  }) => {
    const task = await authorizedFetch<Task>('/tasks/', {
      method: 'POST',
      body: JSON.stringify({
        ...payload,
        due_date: payload.due_date ? new Date(payload.due_date).toISOString() : undefined,
      }),
    })
    setTasks((prev) => [task, ...prev])
    const mergedLabels = [...availableLabels]
    task.labels.forEach((label) => {
      if (!mergedLabels.some((existing) => existing.id === label.id)) {
        mergedLabels.push(label)
      }
    })
    setAvailableLabels(mergedLabels)
  }

  const handleUpdateTask = async (id: number, updates: TaskUpdateInput) => {
    const payload: any = { ...updates }
    if (payload.due_date) {
      payload.due_date = new Date(payload.due_date).toISOString()
    }
    const task = await authorizedFetch<Task>(`/tasks/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    })
    setTasks((prev) => prev.map((t) => (t.id === id ? task : t)))
    
    // Update available labels if new ones were created
    const mergedLabels = [...availableLabels]
    task.labels.forEach((label) => {
      if (!mergedLabels.some((existing) => existing.id === label.id)) {
        mergedLabels.push(label)
      }
    })
    setAvailableLabels(mergedLabels)
  }

  const handleDeleteTask = async (id: number) => {
    await authorizedFetch(`/tasks/${id}`, {
      method: 'DELETE',
    })
    setTasks((prev) => prev.filter((t) => t.id !== id))
  }

  const handleCreateEvent = async (event: FormEvent) => {
    event.preventDefault()
    if (!eventForm.title || !eventForm.start_time || !eventForm.end_time) return
    const payload = {
      title: eventForm.title,
      description: eventForm.description || undefined,
      start_time: new Date(eventForm.start_time).toISOString(),
      end_time: new Date(eventForm.end_time).toISOString(),
      location: eventForm.location || undefined,
      recurrence_type: eventForm.recurrence_type,
      recurrence_interval: Number(eventForm.recurrence_interval) || 1,
      recurrence_end_date: eventForm.recurrence_end_date ? new Date(eventForm.recurrence_end_date).toISOString() : undefined,
    }
    const created = await authorizedFetch<EventItem>('/events/', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
    setEvents((prev) => [created, ...prev])
    setEventForm({ title: '', description: '', start_time: '', end_time: '', location: '', recurrence_type: 'none', recurrence_interval: 1, recurrence_end_date: '' })
  }

  const handleCreatePage = async (event: FormEvent) => {
    event.preventDefault()
    if (!pageForm.title.trim()) return
    const payload = {
      title: pageForm.title,
      description: pageForm.description || undefined,
      visibility: pageForm.visibility,
      layout: createDefaultLayout(),
    }
    const page = await authorizedFetch<PageDetail>('/pages/', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
    setPages((prev) => [...prev, page])
    setSelectedPageId(page.id)
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

  // Dashboard page handlers
  const selectedPage = pages.find((p) => p.id === selectedPageId)

  const handleUpdateColumn = (columnId: string, widgets: LayoutWidget[]) => {
    if (!selectedPage) return
    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, widgets } : col
    )
    updatePageLayout(updatedLayout)
  }

  const handleUpdateWidget = (columnId: string, widget: LayoutWidget) => {
    if (!selectedPage) return
    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId
        ? { ...col, widgets: col.widgets.map((w) => (w.id === widget.id ? widget : w)) }
        : col
    )
    updatePageLayout(updatedLayout)
  }

  const handleRemoveWidget = (columnId: string, widgetId: string) => {
    if (!selectedPage) return
    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, widgets: col.widgets.filter((w) => w.id !== widgetId) } : col
    )
    updatePageLayout(updatedLayout)
  }

  const handleAddWidget = (columnId: string, type: string) => {
    if (!selectedPage) return
    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, widgets: [...col.widgets, createWidget(type as WidgetType)] } : col
    )
    updatePageLayout(updatedLayout)
  }

  const handleAddColumn = () => {
    if (!selectedPage) return
    const newColumn = {
      id: randomId(),
      title: `Column ${selectedPage.layout.length + 1}`,
      width: 1,
      widgets: [],
    }
    updatePageLayout([...selectedPage.layout, newColumn])
  }

  const handleRemoveColumn = (columnId: string) => {
    if (!selectedPage) return
    updatePageLayout(selectedPage.layout.filter((col) => col.id !== columnId))
  }

  const handleUpdateColumnTitle = (columnId: string, title: string) => {
    if (!selectedPage) return
    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, title } : col
    )
    updatePageLayout(updatedLayout)
  }

  const updatePageLayout = async (layout: PageDetail['layout']) => {
    if (!selectedPage) return
    const payload = {
      title: selectedPage.title,
      description: selectedPage.description,
      visibility: selectedPage.visibility,
      layout,
    }
    const saved = await authorizedFetch<PageDetail>(`/pages/${selectedPage.id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    })
    setPages((prev) => prev.map((page) => (page.id === saved.id ? saved : page)))
    setAppMessage(`Saved layout for "${saved.title}".`)
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
        return selectedPage && token ? (
          <DashboardGrid
            columns={selectedPage.layout}
            tasks={tasks}
            events={events}
            openwebui={openwebui}
            token={token}
            onUpdateColumn={handleUpdateColumn}
            onUpdateWidget={handleUpdateWidget}
            onRemoveWidget={handleRemoveWidget}
            onAddWidget={handleAddWidget}
            onAddColumn={handleAddColumn}
            onRemoveColumn={handleRemoveColumn}
            onUpdateColumnTitle={handleUpdateColumnTitle}
          />
        ) : (
          <div className="empty-state-section">
            <p className="muted">Use the plus button to create a page and start building your dashboard.</p>
          </div>
        )
      case 'tasks':
        return token ? (
          <TasksPage
            token={token}
            tasks={tasks}
            availableLabels={availableLabels}
            onCreateTask={handleCreateTaskDirect}
            onUpdateTask={handleUpdateTask}
            onDeleteTask={handleDeleteTask}
          />
        ) : (
          <div className="section-placeholder">Please login to access tasks</div>
        )
      case 'calendar':
        return <CalendarSection events={events} />
      case 'chat':
        return token ? <ChatSection token={token} /> : <div className="section-placeholder">Please login to access chat</div>
      case 'image-gen':
        return token ? <ImageGenerationSection token={token} /> : <div className="section-placeholder">Please login to access image generation</div>
      case 'anime':
        return <AnimeSection />
      case 'iot':
        return <IoTSection />
      case 'settings':
        return token ? <SettingsSection token={token} /> : <div className="section-placeholder">Please login to access settings</div>
      case 'admin':
        return token ? <AdminSection token={token} /> : <div className="section-placeholder">Please login to access admin panel</div>
      case 'create':
        return token ? (
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
        ) : (
          <div className="section-placeholder">Please login to access creator tools</div>
        )
      default:
        return null
    }
  }

  return (
    <div className="app-container">
      <MenuBar
        activeSection={activeSection}
        onSectionChange={setActiveSection}
        onLogout={logout}
        username={user?.username}
      />
      <div className="app-main">
        <main className="main-content">
          {renderSection()}
        </main>
      </div>
    </div>
  )
}

export default App
