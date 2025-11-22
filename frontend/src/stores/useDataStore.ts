import { create } from 'zustand';
import { api } from '../services/api';
import { useUIStore } from './useUIStore';
import { useAuthStore } from './useAuthStore';
import type { 
  Task, 
  EventItem, 
  PageDetail, 
  Label, 
  OpenWebUiStatus,
  LayoutWidget,
  WidgetType
} from '../types/models';
import { createDefaultLayout, randomId, createWidget } from '../utils/helpers';

interface DataState {
  tasks: Task[];
  events: EventItem[];
  pages: PageDetail[];
  availableLabels: Label[];
  openwebui: OpenWebUiStatus | null;
  selectedPageId: number | null;

  // Actions
  loadWorkspace: () => Promise<void>;
  createTask: (payload: any) => Promise<void>;
  updateTask: (id: number, updates: any) => Promise<void>;
  deleteTask: (id: number) => Promise<void>;
  createEvent: (payload: any) => Promise<void>;
  createPage: (payload: any) => Promise<void>;
  setSelectedPageId: (id: number | null) => void;
  
  // Page Layout Actions
  updatePageLayout: (layout: PageDetail['layout']) => Promise<void>;
  handleUpdateColumn: (columnId: string, widgets: LayoutWidget[]) => void;
  handleUpdateWidget: (columnId: string, widget: LayoutWidget) => void;
  handleRemoveWidget: (columnId: string, widgetId: string) => void;
  handleAddWidget: (columnId: string, type: string) => void;
  handleAddColumn: () => void;
  handleRemoveColumn: (columnId: string) => void;
  handleUpdateColumnTitle: (columnId: string, title: string) => void;
}

export const useDataStore = create<DataState>((set, get) => ({
  tasks: [],
  events: [],
  pages: [],
  availableLabels: [],
  openwebui: null,
  selectedPageId: null,

  loadWorkspace: async () => {
    const ui = useUIStore.getState();
    const auth = useAuthStore.getState();
    
    if (!auth.token) return;
    
    ui.setLoading(true);
    try {
      const [
        profile,
        tasks,
        events,
        pages,
        openwebui,
        labels,
      ] = await Promise.all([
        api.getProfile(),
        api.getTasks(),
        api.getEvents(),
        api.getPages(),
        api.getOpenWebUIStatus(),
        api.getLabels(),
      ]);

      auth.setUser(profile);
      set({ 
        tasks, 
        events, 
        pages, 
        openwebui, 
        availableLabels: labels 
      });
      
      if (pages.length > 0 && !get().selectedPageId) {
        set({ selectedPageId: pages[0].id });
      }
      ui.setAppMessage('Synced with Cafe servers.');
    } catch (error) {
      ui.setAppMessage((error as Error).message);
    } finally {
      ui.setLoading(false);
    }
  },

  createTask: async (payload) => {
    const task = await api.createTask(payload);
    set((state) => {
      const mergedLabels = [...state.availableLabels];
      task.labels.forEach((label) => {
        if (!mergedLabels.some((existing) => existing.id === label.id)) {
          mergedLabels.push(label);
        }
      });
      return {
        tasks: [task, ...state.tasks],
        availableLabels: mergedLabels
      };
    });
  },

  updateTask: async (id, updates) => {
    const task = await api.updateTask(id, updates);
    set((state) => {
      const mergedLabels = [...state.availableLabels];
      task.labels.forEach((label) => {
        if (!mergedLabels.some((existing) => existing.id === label.id)) {
          mergedLabels.push(label);
        }
      });
      return {
        tasks: state.tasks.map((t) => (t.id === id ? task : t)),
        availableLabels: mergedLabels
      };
    });
  },

  deleteTask: async (id) => {
    await api.deleteTask(id);
    set((state) => ({
      tasks: state.tasks.filter((t) => t.id !== id)
    }));
  },

  createEvent: async (payload) => {
    const event = await api.createEvent(payload);
    set((state) => ({
      events: [event, ...state.events]
    }));
    // Refresh to get all recurring instances if needed
    const events = await api.getEvents();
    set({ events });
  },

  createPage: async (payload) => {
    const page = await api.createPage({
      ...payload,
      layout: createDefaultLayout(),
    });
    set((state) => ({
      pages: [...state.pages, page],
      selectedPageId: page.id
    }));
  },

  setSelectedPageId: (id) => set({ selectedPageId: id }),

  // Layout Actions
  updatePageLayout: async (layout) => {
    const { pages, selectedPageId } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    const payload = {
      title: selectedPage.title,
      description: selectedPage.description,
      visibility: selectedPage.visibility,
      layout,
    };

    const saved = await api.updatePage(selectedPage.id, payload);
    set((state) => ({
      pages: state.pages.map((p) => (p.id === saved.id ? saved : p))
    }));
    useUIStore.getState().setAppMessage(`Saved layout for "${saved.title}".`);
  },

  handleUpdateColumn: (columnId, widgets) => {
    const { pages, selectedPageId, updatePageLayout } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, widgets } : col
    );
    updatePageLayout(updatedLayout);
  },

  handleUpdateWidget: (columnId, widget) => {
    const { pages, selectedPageId, updatePageLayout } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId
        ? { ...col, widgets: col.widgets.map((w) => (w.id === widget.id ? widget : w)) }
        : col
    );
    updatePageLayout(updatedLayout);
  },

  handleRemoveWidget: (columnId, widgetId) => {
    const { pages, selectedPageId, updatePageLayout } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, widgets: col.widgets.filter((w) => w.id !== widgetId) } : col
    );
    updatePageLayout(updatedLayout);
  },

  handleAddWidget: (columnId, type) => {
    const { pages, selectedPageId, updatePageLayout } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, widgets: [...col.widgets, createWidget(type as WidgetType)] } : col
    );
    updatePageLayout(updatedLayout);
  },

  handleAddColumn: () => {
    const { pages, selectedPageId, updatePageLayout } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    const newColumn = {
      id: randomId(),
      title: `Column ${selectedPage.layout.length + 1}`,
      width: 1,
      widgets: [],
    };
    updatePageLayout([...selectedPage.layout, newColumn]);
  },

  handleRemoveColumn: (columnId) => {
    const { pages, selectedPageId, updatePageLayout } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    updatePageLayout(selectedPage.layout.filter((col) => col.id !== columnId));
  },

  handleUpdateColumnTitle: (columnId, title) => {
    const { pages, selectedPageId, updatePageLayout } = get();
    const selectedPage = pages.find(p => p.id === selectedPageId);
    if (!selectedPage) return;

    const updatedLayout = selectedPage.layout.map((col) =>
      col.id === columnId ? { ...col, title } : col
    );
    updatePageLayout(updatedLayout);
  }
}));
