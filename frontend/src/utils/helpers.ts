import type { LayoutColumn, LayoutWidget, WidgetType } from '../types/models'

export const randomId = () =>
  crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).slice(2)

export const createDefaultLayout = (): LayoutColumn[] => [
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

export const createWidget = (type: WidgetType): LayoutWidget => {
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

export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  (typeof window !== 'undefined' ? `${window.location.origin}/api` : 'http://127.0.0.1:8000')
