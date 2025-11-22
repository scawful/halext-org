import { API_BASE_URL } from '../utils/helpers';
import type { 
  User, 
  Task, 
  EventItem, 
  PageDetail, 
  Label, 
  OpenWebUiStatus
} from '../types/models';

class ApiService {
  private get token(): string | null {
    return localStorage.getItem('halext_token');
  }

  private async authorizedFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
    if (!this.token) {
      throw new Error('You need to sign in first');
    }

    const headers = new Headers(options.headers);
    if (!(options.body instanceof FormData) && !headers.has('Content-Type') && options.method && options.method !== 'GET') {
      headers.set('Content-Type', 'application/json');
    }
    headers.set('Authorization', `Bearer ${this.token}`);

    const response = await fetch(`${API_BASE_URL}${path}`, {
      ...options,
      headers,
    });

    if (response.status === 401) {
      // We'll handle logout in the store or interception later
      throw new Error('Session expired. Please sign in again.');
    }

    if (!response.ok) {
      const text = await response.text();
      throw new Error(text || 'Request failed');
    }

    if (response.status === 204) {
      return null as T;
    }

    const text = await response.text();
    return text ? (JSON.parse(text) as T) : (null as T);
  }

  // Auth
  async login(payload: URLSearchParams): Promise<{ access_token: string }> {
    const response = await fetch(`${API_BASE_URL}/token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: payload,
    });

    if (!response.ok) {
      throw new Error('Invalid credentials');
    }
    return response.json();
  }

  async register(payload: any, accessCode: string): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/users/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Halext-Code': accessCode.trim(),
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      throw new Error('Unable to register right now.');
    }
  }

  // Workspace Data
  async getProfile(): Promise<User> {
    return this.authorizedFetch<User>('/users/me/');
  }

  async getTasks(): Promise<Task[]> {
    return this.authorizedFetch<Task[]>('/tasks/');
  }

  async getEvents(): Promise<EventItem[]> {
    return this.authorizedFetch<EventItem[]>('/events/');
  }

  async getPages(): Promise<PageDetail[]> {
    return this.authorizedFetch<PageDetail[]>('/pages/');
  }

  async getOpenWebUIStatus(): Promise<OpenWebUiStatus> {
    return this.authorizedFetch<OpenWebUiStatus>('/integrations/openwebui');
  }

  async getLabels(): Promise<Label[]> {
    return this.authorizedFetch<Label[]>('/labels/');
  }

  // CRUD Operations
  async createTask(payload: any): Promise<Task> {
    return this.authorizedFetch<Task>('/tasks/', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  async updateTask(id: number, payload: any): Promise<Task> {
    return this.authorizedFetch<Task>(`/tasks/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  }

  async deleteTask(id: number): Promise<void> {
    return this.authorizedFetch(`/tasks/${id}`, {
      method: 'DELETE',
      body: null,
    });
  }

  async createEvent(payload: any): Promise<EventItem> {
    return this.authorizedFetch<EventItem>('/events/', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  async createPage(payload: any): Promise<PageDetail> {
    return this.authorizedFetch<PageDetail>('/pages/', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  async updatePage(id: number, payload: any): Promise<PageDetail> {
    return this.authorizedFetch<PageDetail>(`/pages/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  }
}

export const api = new ApiService();
