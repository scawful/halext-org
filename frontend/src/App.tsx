import type { FormEvent, KeyboardEvent } from 'react'
import { useCallback, useEffect, useMemo, useState } from 'react'
import './App.css'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'

type Label = {
  id: number
  name: string
  color: string
}

type Task = {
  id: number
  title: string
  description?: string | null
  due_date?: string | null
  completed: boolean
  created_at: string
  labels: Label[]
}

type EventItem = {
  id: number
  title: string
  description?: string | null
  start_time: string
  end_time: string
  location?: string | null
  recurrence_type: string
  recurrence_interval: number
  recurrence_end_date?: string | null
}

type WidgetType = 'tasks' | 'events' | 'notes' | 'gift-list' | 'openwebui'

type LayoutWidget = {
  id: string
  type: WidgetType
  title: string
  config?: Record<string, unknown>
}

type LayoutColumn = {
  id: string
  title: string
  width: number
  widgets: LayoutWidget[]
}

type LayoutPreset = {
  id: number
  name: string
  description?: string | null
  layout: LayoutColumn[]
}

type PageShareInfo = {
  user_id: number
  username: string
  can_edit: boolean
}

type PageDetail = {
  id: number
  title: string
  description?: string | null
  owner_id: number
  visibility: string
  created_at: string
  updated_at: string
  layout: LayoutColumn[]
  shared_with: PageShareInfo[]
}

type ConversationSummary = {
  id: number
  title: string
  owner_id: number
  mode: string
  with_ai: boolean
  created_at: string
  updated_at: string
  participants: string[]
}

type ChatMessage = {
  id: number
  conversation_id: number
  author_id?: number | null
  author_type: 'user' | 'ai'
  model_used?: string | null
  content: string
  created_at: string
}

type User = {
  id: number
  username: string
  email: string
  full_name?: string | null
}

type OpenWebUiStatus = {
  enabled: boolean
  url?: string | null
}

const randomId = () => (crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).slice(2))

const clonePage = (page: PageDetail): PageDetail => ({
  ...page,
  layout: page.layout.map((column) => ({
    ...column,
    widgets: column.widgets.map((widget) => ({
      ...widget,
      config: widget.config ? { ...widget.config } : undefined,
    })),
  })),
  shared_with: page.shared_with.map((share) => ({ ...share })),
})

const createDefaultLayout = (): LayoutColumn[] => [
  {
    id: randomId(),
    title: 'Focus',
    width: 1,
    widgets: [
      { id: randomId(), type: 'tasks', title: 'Tasks', config: { filter: 'all' } },
      { id: randomId(), type: 'events', title: 'Next Events', config: { range: 'week' } },
    ],
  },
  {
    id: randomId(),
    title: 'Personal',
    width: 1,
    widgets: [{ id: randomId(), type: 'gift-list', title: 'Gift Ideas', config: { items: [] } }],
  },
]

const createWidget = (type: WidgetType): LayoutWidget => {
  switch (type) {
    case 'events':
      return { id: randomId(), type, title: 'Events', config: { range: 'week' } }
    case 'notes':
      return { id: randomId(), type, title: 'Notes', config: { content: '' } }
    case 'gift-list':
      return { id: randomId(), type, title: 'Gift List', config: { items: [] } }
    case 'openwebui':
      return { id: randomId(), type, title: 'OpenWebUI', config: {} }
    default:
      return { id: randomId(), type: 'tasks', title: 'Tasks', config: { filter: 'all' } }
  }
}

type WidgetCardProps = {
  columnId: string
  widget: LayoutWidget
  tasks: Task[]
  events: EventItem[]
  openwebui: OpenWebUiStatus | null
  onUpdate: (columnId: string, widget: LayoutWidget) => void
  onRemove: (columnId: string, widgetId: string) => void
}

const WidgetCard = ({ columnId, widget, tasks, events, openwebui, onUpdate, onRemove }: WidgetCardProps) => {
  const [notesContent, setNotesContent] = useState<string>(() => (widget.config?.content as string) ?? '')
  const [giftInput, setGiftInput] = useState('')

  useEffect(() => {
    setNotesContent((widget.config?.content as string) ?? '')
  }, [widget.config?.content])

  const giftItems = Array.isArray(widget.config?.items) ? (widget.config?.items as string[]) : []

  const addGiftItem = () => {
    if (!giftInput.trim()) return
    const updated = { ...widget, config: { ...widget.config, items: [...giftItems, giftInput.trim()] } }
    onUpdate(columnId, updated)
    setGiftInput('')
  }

  const removeGiftItem = (item: string) => {
    const updated = { ...widget, config: { ...widget.config, items: giftItems.filter((entry) => entry !== item) } }
    onUpdate(columnId, updated)
  }

  const persistNotes = () => {
    const updated = { ...widget, config: { ...widget.config, content: notesContent } }
    onUpdate(columnId, updated)
  }

  const renderWidgetBody = () => {
    if (widget.type === 'tasks') {
      return (
        <ul className="widget-list">
          {tasks.length === 0 && <li className="muted">No tasks yet</li>}
          {tasks.slice(0, 5).map((task) => (
            <li key={task.id}>
              <strong>{task.title}</strong>
              {task.due_date && <span className="muted"> · Due {new Date(task.due_date).toLocaleDateString()}</span>}
              {task.labels && task.labels.length > 0 && (
                <div className="label-chip-row">
                  {task.labels.map((label) => (
                    <span key={`${task.id}-${label.id}`} className="label-chip" style={{ borderColor: label.color }}>
                      {label.name}
                    </span>
                  ))}
                </div>
              )}
            </li>
          ))}
        </ul>
      )
    }
    if (widget.type === 'events') {
      return (
        <ul className="widget-list">
          {events.length === 0 && <li className="muted">No events scheduled</li>}
          {events.slice(0, 5).map((event) => (
            <li key={event.id}>
              <strong>{event.title}</strong>
              <span className="muted">
                {' '}
                · {new Date(event.start_time).toLocaleString()} – {new Date(event.end_time).toLocaleTimeString()}
              </span>
            </li>
          ))}
        </ul>
      )
    }
    if (widget.type === 'notes') {
      return (
        <div className="notes-widget">
          <textarea
            value={notesContent}
            onChange={(event) => setNotesContent(event.target.value)}
            onBlur={persistNotes}
            placeholder="Capture lightweight notes or a micro agenda..."
          />
          <span className="muted">Changes save automatically when you leave the field.</span>
        </div>
      )
    }
    if (widget.type === 'gift-list') {
      return (
        <div>
          <ul className="widget-list">
            {giftItems.length === 0 && <li className="muted">Add gift ideas without sharing the surprise.</li>}
            {giftItems.map((item) => (
              <li key={item} className="gift-item">
                <span>{item}</span>
                <button type="button" onClick={() => removeGiftItem(item)}>
                  remove
                </button>
              </li>
            ))}
          </ul>
          <div className="inline-form">
            <input value={giftInput} onChange={(event) => setGiftInput(event.target.value)} placeholder="Gift idea" />
            <button type="button" onClick={addGiftItem}>
              Add
            </button>
          </div>
        </div>
      )
    }
    if (widget.type === 'openwebui') {
      if (!openwebui?.enabled || !openwebui.url) {
        return <p className="muted">OpenWebUI is not running. Start it to unlock this panel.</p>
      }
      return <iframe title="OpenWebUI" src={openwebui.url} />
    }
    return <p className="muted">Widget not configured.</p>
  }

  return (
    <div className="widget-card" key={widget.id}>
      <div className="widget-header">
        <h4>{widget.title}</h4>
        <button type="button" className="link-button" onClick={() => onRemove(columnId, widget.id)}>
          Remove
        </button>
      </div>
      {renderWidgetBody()}
    </div>
  )
}

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
  const [pageDraft, setPageDraft] = useState<PageDetail | null>(null)
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
  const [shareForm, setShareForm] = useState({ username: '', can_edit: false })
  const [conversations, setConversations] = useState<ConversationSummary[]>([])
  const [activeConversationId, setActiveConversationId] = useState<number | null>(null)
  const [conversationMessages, setConversationMessages] = useState<Record<number, ChatMessage[]>>({})
  const [chatInput, setChatInput] = useState('')
  const [newConversationForm, setNewConversationForm] = useState({
    title: '',
    participant_usernames: '',
    with_ai: true,
  })
  const [appMessage, setAppMessage] = useState<string | null>(null)
  const [openwebui, setOpenwebui] = useState<OpenWebUiStatus | null>(null)
  const [availableLabels, setAvailableLabels] = useState<Label[]>([])
  const [layoutPresets, setLayoutPresets] = useState<LayoutPreset[]>([])

  const logout = useCallback(() => {
    localStorage.removeItem('halext_token')
    localStorage.removeItem('halext_access_code')
    setToken(null)
    setUser(null)
    setTasks([])
    setEvents([])
    setPages([])
    setPageDraft(null)
    setConversations([])
    setActiveConversationId(null)
    setConversationMessages({})
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
        conversationsResponse,
        openwebuiResponse,
        labelsResponse,
        layoutPresetResponse,
      ] = await Promise.all([
        authorizedFetch<User>('/users/me/'),
        authorizedFetch<Task[]>('/tasks/'),
        authorizedFetch<EventItem[]>('/events/'),
        authorizedFetch<PageDetail[]>('/pages/'),
        authorizedFetch<ConversationSummary[]>('/conversations/'),
        authorizedFetch<OpenWebUiStatus>('/integrations/openwebui'),
        authorizedFetch<Label[]>('/labels/'),
        authorizedFetch<LayoutPreset[]>('/layout-presets/'),
      ])
      setUser(profile)
      setTasks(tasksResponse)
      setEvents(eventsResponse)
      setPages(pagesResponse)
      setOpenwebui(openwebuiResponse)
      setAvailableLabels(labelsResponse)
      setLayoutPresets(layoutPresetResponse)
      if (pagesResponse.length > 0) {
        setSelectedPageId((current) => current ?? pagesResponse[0].id)
      }
      setConversations(conversationsResponse)
      if (conversationsResponse.length > 0) {
        setActiveConversationId((current) => current ?? conversationsResponse[0].id)
      }
      setAppMessage('Synced with Halext Org servers.')
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

  useEffect(() => {
    if (!selectedPageId) {
      setPageDraft(null)
      return
    }
    const page = pages.find((entry) => entry.id === selectedPageId)
    setPageDraft(page ? clonePage(page) : null)
  }, [selectedPageId, pages])

  const fetchConversationMessages = useCallback(
    async (conversationId: number) => {
      if (!token) return
      const messages = await authorizedFetch<ChatMessage[]>(`/conversations/${conversationId}/messages`)
      setConversationMessages((prev) => ({ ...prev, [conversationId]: messages }))
    },
    [authorizedFetch, token],
  )

  useEffect(() => {
    if (activeConversationId) {
      fetchConversationMessages(activeConversationId)
    }
  }, [activeConversationId, fetchConversationMessages])

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

  const updatePageDraft = (updater: (draft: PageDetail) => PageDetail) => {
    if (!pageDraft) return
    setPageDraft(updater(pageDraft))
  }

  const handleSavePage = async () => {
    if (!pageDraft) return
    const payload = {
      title: pageDraft.title,
      description: pageDraft.description,
      visibility: pageDraft.visibility,
      layout: pageDraft.layout,
    }
    const saved = await authorizedFetch<PageDetail>(`/pages/${pageDraft.id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    })
    setPages((prev) => prev.map((page) => (page.id === saved.id ? saved : page)))
    setPageDraft(clonePage(saved))
    setAppMessage(`Saved layout for "${saved.title}".`)
  }

  const handleSharePage = async (event: FormEvent) => {
    event.preventDefault()
    if (!pageDraft || !shareForm.username.trim()) return
    const shares = await authorizedFetch<PageShareInfo[]>(`/pages/${pageDraft.id}/share`, {
      method: 'POST',
      body: JSON.stringify({ username: shareForm.username.trim(), can_edit: shareForm.can_edit }),
    })
    const updated = { ...pageDraft, shared_with: shares }
    setPageDraft(updated)
    setPages((prev) => prev.map((page) => (page.id === updated.id ? { ...page, shared_with: shares } : page)))
    setShareForm({ username: '', can_edit: false })
  }

  const handleRemoveShare = async (username: string) => {
    if (!pageDraft) return
    await authorizedFetch(`/pages/${pageDraft.id}/share/${encodeURIComponent(username)}`, { method: 'DELETE' })
    const shares = pageDraft.shared_with.filter((share) => share.username !== username)
    setPageDraft({ ...pageDraft, shared_with: shares })
    setPages((prev) => prev.map((page) => (page.id === pageDraft.id ? { ...page, shared_with: shares } : page)))
  }

  const handleAddWidget = (columnId: string, type: WidgetType) => {
    if (!pageDraft) return
    updatePageDraft((draft) => ({
      ...draft,
      layout: draft.layout.map((column) =>
        column.id === columnId ? { ...column, widgets: [...column.widgets, createWidget(type)] } : column,
      ),
    }))
  }

  const handleAddColumn = () => {
    if (!pageDraft) return
    updatePageDraft((draft) => ({
      ...draft,
      layout: [
        ...draft.layout,
        {
          id: randomId(),
          title: `Column ${draft.layout.length + 1}`,
          width: 1,
          widgets: [],
        },
      ],
    }))
  }

  const handleRemoveColumn = (columnId: string) => {
    if (!pageDraft) return
    updatePageDraft((draft) => ({
      ...draft,
      layout: draft.layout.filter((column) => column.id !== columnId),
    }))
  }

  const handleWidgetUpdate = (columnId: string, updatedWidget: LayoutWidget) => {
    if (!pageDraft) return
    updatePageDraft((draft) => ({
      ...draft,
      layout: draft.layout.map((column) =>
        column.id === columnId
          ? {
              ...column,
              widgets: column.widgets.map((widget) => (widget.id === updatedWidget.id ? updatedWidget : widget)),
            }
          : column,
      ),
    }))
  }

  const handleWidgetRemove = (columnId: string, widgetId: string) => {
    if (!pageDraft) return
    updatePageDraft((draft) => ({
      ...draft,
      layout: draft.layout.map((column) =>
        column.id === columnId
          ? { ...column, widgets: column.widgets.filter((widget) => widget.id !== widgetId) }
          : column,
      ),
    }))
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

  const handleConversationCreate = async (event: FormEvent) => {
    event.preventDefault()
    if (!newConversationForm.title.trim()) return
    const participants = newConversationForm.participant_usernames
      .split(',')
      .map((entry) => entry.trim())
      .filter(Boolean)
    const payload = {
      title: newConversationForm.title,
      participant_usernames: participants,
      with_ai: newConversationForm.with_ai,
      mode: participants.length > 1 ? 'group' : 'solo',
    }
    const conversation = await authorizedFetch<ConversationSummary>('/conversations/', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
    setConversations((prev) => [conversation, ...prev])
    setNewConversationForm({ title: '', participant_usernames: '', with_ai: true })
    setActiveConversationId(conversation.id)
    setAppMessage(`Conversation "${conversation.title}" ready.`)
  }

  const handleSendMessage = async (event: FormEvent) => {
    event.preventDefault()
    if (!chatInput.trim() || !activeConversationId) return
    const responses = await authorizedFetch<ChatMessage[]>(`/conversations/${activeConversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify({ content: chatInput }),
    })
    setConversationMessages((prev) => ({
      ...prev,
      [activeConversationId]: [...(prev[activeConversationId] ?? []), ...responses],
    }))
    setChatInput('')
  }

  const activeConversationMessages = useMemo(
    () => (activeConversationId ? conversationMessages[activeConversationId] ?? [] : []),
    [activeConversationId, conversationMessages],
  )

  const handleApplyPreset = async (presetId: number) => {
    if (!pageDraft) return
    try {
      const updated = await authorizedFetch<PageDetail>(`/pages/${pageDraft.id}/apply-preset/${presetId}`, {
        method: 'POST',
      })
      setPageDraft(clonePage(updated))
      setPages((prev) => prev.map((page) => (page.id === updated.id ? updated : page)))
      const presetName = layoutPresets.find((preset) => preset.id === presetId)?.name
      setAppMessage(`Applied layout preset${presetName ? ` "${presetName}"` : ''}.`)
    } catch (error) {
      setAppMessage((error as Error).message)
    }
  }

  if (!token) {
    return (
      <div className="auth-shell">
        <h1>Halext Org</h1>
        <p className="muted">Sign in to coordinate calendars, todos, layouts, and AI chats.</p>
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
            <form onSubmit={handleLogin} className="stack">
              <label>
                Username
                <input name="username" placeholder="Your username" autoComplete="username" required />
              </label>
              <label>
                Password
                <input name="password" type="password" placeholder="Password" autoComplete="current-password" required />
              </label>
              <button type="submit" disabled={isLoading}>
                Sign in
              </button>
            </form>
          ) : (
            <form onSubmit={handleRegister} className="stack">
              <label>
                Full name
                <input name="full_name" placeholder="Full name" autoComplete="name" />
              </label>
              <label>
                Username
                <input name="username" placeholder="Choose a username" autoComplete="username" required />
              </label>
              <label>
                Email
                <input name="email" type="email" placeholder="you@example.com" autoComplete="email" required />
              </label>
              <label>
                Password
                <input name="password" type="password" placeholder="Create a password" autoComplete="new-password" required />
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

  return (
    <div className="app-shell">
      <aside>
        <div className="profile">
          <h2>Welcome back{user?.full_name ? `, ${user.full_name}` : ''}</h2>
          <p className="muted">@{user?.username}</p>
          <button onClick={logout}>Logout</button>
        </div>
        <section>
          <h3>Tasks</h3>
          <form onSubmit={handleCreateTask} className="stack">
            <input
              value={taskForm.title}
              onChange={(event) => setTaskForm((prev) => ({ ...prev, title: event.target.value }))}
              placeholder="Task title"
            />
            <textarea
              value={taskForm.description}
              onChange={(event) => setTaskForm((prev) => ({ ...prev, description: event.target.value }))}
              placeholder="Description"
            />
            <div className="label-manager">
              <div className="label-chip-row">
                {newTaskLabels.map((label) => (
                  <span key={label} className="label-chip">
                    {label}
                    <button type="button" onClick={() => removeTaskLabel(label)}>
                      ×
                    </button>
                  </span>
                ))}
              </div>
              <input
                value={taskLabelInput}
                onChange={(event) => setTaskLabelInput(event.target.value)}
                onKeyDown={handleLabelInputKeyDown}
                placeholder="Add label and press Enter"
              />
              {availableLabels.filter((label) => !newTaskLabels.includes(label.name)).length > 0 && (
                <div className="label-suggestions">
                  {availableLabels
                    .filter((label) => !newTaskLabels.includes(label.name))
                    .slice(0, 5)
                    .map((label) => (
                      <button type="button" key={label.id} className="ghost" onClick={() => addTaskLabel(label.name)}>
                        {label.name}
                      </button>
                    ))}
                </div>
              )}
            </div>
            <input
              type="date"
              value={taskForm.due_date}
              onChange={(event) => setTaskForm((prev) => ({ ...prev, due_date: event.target.value }))}
            />
            <button type="submit">Add task</button>
          </form>
        </section>
        <section>
          <h3>Events</h3>
          <form onSubmit={handleCreateEvent} className="stack">
            <input
              value={eventForm.title}
              onChange={(event) => setEventForm((prev) => ({ ...prev, title: event.target.value }))}
              placeholder="Event title"
            />
            <textarea
              value={eventForm.description}
              onChange={(event) => setEventForm((prev) => ({ ...prev, description: event.target.value }))}
              placeholder="Description"
            />
            <input
              type="datetime-local"
              value={eventForm.start_time}
              onChange={(event) => setEventForm((prev) => ({ ...prev, start_time: event.target.value }))}
            />
            <input
              type="datetime-local"
              value={eventForm.end_time}
              onChange={(event) => setEventForm((prev) => ({ ...prev, end_time: event.target.value }))}
            />
            <input
              value={eventForm.location}
              onChange={(event) => setEventForm((prev) => ({ ...prev, location: event.target.value }))}
              placeholder="Location"
            />
            <div className="recurrence-row">
              <label>
                Repeats
                <select
                  value={eventForm.recurrence_type}
                  onChange={(event) => setEventForm((prev) => ({ ...prev, recurrence_type: event.target.value }))}
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
                      onChange={(event) => setEventForm((prev) => ({ ...prev, recurrence_interval: Number(event.target.value) || 1 }))}
                    />
                  </label>
                  <label>
                    Until
                    <input
                      type="date"
                      value={eventForm.recurrence_end_date}
                      onChange={(event) => setEventForm((prev) => ({ ...prev, recurrence_end_date: event.target.value }))}
                    />
                  </label>
                </>
              )}
            </div>
            <button type="submit">Add event</button>
          </form>
        </section>
        <section>
          <h3>New Page</h3>
          <form onSubmit={handleCreatePage} className="stack">
            <input
              value={pageForm.title}
              onChange={(event) => setPageForm((prev) => ({ ...prev, title: event.target.value }))}
              placeholder="Page title"
            />
            <textarea
              value={pageForm.description}
              onChange={(event) => setPageForm((prev) => ({ ...prev, description: event.target.value }))}
              placeholder="Description"
            />
            <select value={pageForm.visibility} onChange={(event) => setPageForm((prev) => ({ ...prev, visibility: event.target.value }))}>
              <option value="private">Private</option>
              <option value="shared">Shared</option>
            </select>
            <button type="submit">Create page</button>
          </form>
        </section>
      </aside>
      <main>
        <header className="workspace-header">
          <div>
            <h1>Workspace</h1>
            <p className="muted">{appMessage}</p>
          </div>
          {isLoading && <span className="pill">Syncing…</span>}
        </header>
        <section className="pages-section">
          <div className="pages-sidebar">
            <h3>Pages</h3>
            <ul>
              {pages.map((page) => (
                <li key={page.id}>
                  <button className={page.id === selectedPageId ? 'active' : ''} onClick={() => setSelectedPageId(page.id)}>
                    {page.title} {page.visibility === 'private' && <span className="pill">Private</span>}
                  </button>
                </li>
              ))}
            </ul>
          </div>
          <div className="page-editor">
            {pageDraft ? (
              <>
                <div className="page-toolbar">
                  <div>
                    <input
                      value={pageDraft.title}
                      onChange={(event) => updatePageDraft((draft) => ({ ...draft, title: event.target.value }))}
                    />
                    <textarea
                      value={pageDraft.description ?? ''}
                      onChange={(event) => updatePageDraft((draft) => ({ ...draft, description: event.target.value }))}
                      placeholder="Describe what this layout should track."
                    />
                  </div>
                  <div className="inline-form">
                    <label>
                      Visibility
                      <select
                        value={pageDraft.visibility}
                        onChange={(event) => updatePageDraft((draft) => ({ ...draft, visibility: event.target.value }))}
                      >
                        <option value="private">Private</option>
                        <option value="shared">Shared</option>
                      </select>
                    </label>
                    <button onClick={handleSavePage}>Save layout</button>
                  </div>
                </div>
                <div className="layout-grid">
                  {pageDraft.layout.map((column) => (
                    <div key={column.id} className="layout-column">
                      <div className="column-header">
                        <input
                          value={column.title}
                          onChange={(event) =>
                            updatePageDraft((draft) => ({
                              ...draft,
                              layout: draft.layout.map((entry) =>
                                entry.id === column.id ? { ...entry, title: event.target.value } : entry,
                              ),
                            }))
                          }
                        />
                        <button type="button" className="link-button" onClick={() => handleRemoveColumn(column.id)}>
                          Remove column
                        </button>
                      </div>
                      {column.widgets.map((widget) => (
                        <WidgetCard
                          key={widget.id}
                          columnId={column.id}
                          widget={widget}
                          tasks={tasks}
                          events={events}
                          openwebui={openwebui}
                          onUpdate={handleWidgetUpdate}
                          onRemove={handleWidgetRemove}
                        />
                      ))}
                      <div className="inline-form">
                        <select onChange={(event) => handleAddWidget(column.id, event.target.value as WidgetType)} defaultValue="">
                          <option value="" disabled>
                            Add widget
                          </option>
                          <option value="tasks">Tasks</option>
                          <option value="events">Events</option>
                          <option value="notes">Notes</option>
                          <option value="gift-list">Gift List</option>
                          <option value="openwebui">OpenWebUI</option>
                        </select>
                      </div>
                    </div>
                  ))}
                  <button className="ghost" onClick={handleAddColumn}>
                    + Add column
                  </button>
                </div>
                <div className="share-panel">
                  <h4>Sharing</h4>
                  <form onSubmit={handleSharePage} className="inline-form">
                    <input
                      value={shareForm.username}
                      onChange={(event) => setShareForm((prev) => ({ ...prev, username: event.target.value }))}
                      placeholder="Partner username"
                    />
                    <label className="inline">
                      <input
                        type="checkbox"
                        checked={shareForm.can_edit}
                        onChange={(event) => setShareForm((prev) => ({ ...prev, can_edit: event.target.checked }))}
                      />
                      Can edit
                    </label>
                    <button type="submit">Share</button>
                  </form>
                  <ul>
                    {pageDraft.shared_with.map((share) => (
                      <li key={share.user_id}>
                        @{share.username}{' '}
                        {share.can_edit ? <span className="pill">Editor</span> : <span className="pill">Viewer</span>}
                        <button type="button" className="link-button" onClick={() => handleRemoveShare(share.username)}>
                          remove
                        </button>
                      </li>
                    ))}
                    {pageDraft.shared_with.length === 0 && <li className="muted">Not shared yet.</li>}
                  </ul>
                </div>
                <div className="preset-panel">
                  <h4>Layout presets</h4>
                  <div className="preset-grid">
                    {layoutPresets.map((preset) => (
                      <div key={preset.id} className="preset-card">
                        <div>
                          <strong>{preset.name}</strong>
                          {preset.description && <p className="muted">{preset.description}</p>}
                        </div>
                        <button type="button" onClick={() => handleApplyPreset(preset.id)}>
                          Apply
                        </button>
                      </div>
                    ))}
                    {layoutPresets.length === 0 && <p className="muted">No presets yet.</p>}
                  </div>
                </div>
              </>
            ) : (
              <p className="muted">Select or create a page to start configuring your layout.</p>
            )}
          </div>
        </section>
        <section className="chat-section">
          <div className="chat-list">
            <h3>Conversations</h3>
            <ul>
              {conversations.map((conversation) => (
                <li key={conversation.id}>
                  <button className={conversation.id === activeConversationId ? 'active' : ''} onClick={() => setActiveConversationId(conversation.id)}>
                    {conversation.title}
                    {conversation.with_ai && <span className="pill">AI</span>}
                  </button>
                </li>
              ))}
            </ul>
            <form onSubmit={handleConversationCreate} className="stack">
              <input
                value={newConversationForm.title}
                onChange={(event) => setNewConversationForm((prev) => ({ ...prev, title: event.target.value }))}
                placeholder="Conversation name"
              />
              <input
                value={newConversationForm.participant_usernames}
                onChange={(event) => setNewConversationForm((prev) => ({ ...prev, participant_usernames: event.target.value }))}
                placeholder="Participants (usernames, comma separated)"
              />
              <label className="inline">
                <input
                  type="checkbox"
                  checked={newConversationForm.with_ai}
                  onChange={(event) => setNewConversationForm((prev) => ({ ...prev, with_ai: event.target.checked }))}
                />
                Include AI responder
              </label>
              <button type="submit">Create conversation</button>
            </form>
          </div>
          <div className="chat-window">
            {activeConversationId ? (
              <>
                <div className="chat-messages">
                  {activeConversationMessages.map((message) => (
                    <div key={message.id} className={`chat-message ${message.author_type}`}>
                      <div>
                        <strong>{message.author_type === 'ai' ? 'Halext AI' : 'You'}</strong>
                        <span className="muted">{new Date(message.created_at).toLocaleTimeString()}</span>
                      </div>
                      <p>{message.content}</p>
                    </div>
                  ))}
                </div>
                <form onSubmit={handleSendMessage} className="inline-form">
                  <input value={chatInput} onChange={(event) => setChatInput(event.target.value)} placeholder="Send a message" />
                  <button type="submit">Send</button>
                </form>
              </>
            ) : (
              <p className="muted">Select a conversation or start a new one.</p>
            )}
          </div>
        </section>
      </main>
    </div>
  )
}

export default App
