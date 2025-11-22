import { create } from 'zustand';
import { api } from '../services/api';
import { useUIStore } from './useUIStore';
import type { User } from '../types/models';

interface AuthState {
  token: string | null;
  user: User | null;
  accessCode: string;
  authError: string | null;
  authMode: 'login' | 'register';

  // Actions
  setToken: (token: string | null) => void;
  setUser: (user: User | null) => void;
  setAccessCode: (code: string) => void;
  setAuthMode: (mode: 'login' | 'register') => void;
  login: (payload: URLSearchParams) => Promise<void>;
  register: (payload: any) => Promise<void>;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  token: localStorage.getItem('halext_token'),
  user: null,
  accessCode: localStorage.getItem('halext_access_code') ?? '',
  authError: null,
  authMode: 'login',

  setToken: (token) => {
    if (token) {
      localStorage.setItem('halext_token', token);
    } else {
      localStorage.removeItem('halext_token');
    }
    set({ token });
  },

  setUser: (user) => set({ user }),
  
  setAccessCode: (accessCode) => {
    if (accessCode) {
      localStorage.setItem('halext_access_code', accessCode);
    } else {
      localStorage.removeItem('halext_access_code');
    }
    set({ accessCode });
  },

  setAuthMode: (mode) => set({ authMode: mode, authError: null }),

  login: async (payload) => {
    const ui = useUIStore.getState();
    ui.setLoading(true);
    set({ authError: null });
    
    try {
      const data = await api.login(payload);
      get().setToken(data.access_token);
    } catch (error) {
      set({ authError: (error as Error).message });
      throw error;
    } finally {
      ui.setLoading(false);
    }
  },

  register: async (payload) => {
    const ui = useUIStore.getState();
    ui.setLoading(true);
    set({ authError: null });

    try {
      await api.register(payload, get().accessCode);
      set({ authMode: 'login' });
      ui.setAppMessage('Account ready! Sign in to continue.');
    } catch (error) {
      set({ authError: (error as Error).message });
      throw error;
    } finally {
      ui.setLoading(false);
    }
  },

  logout: () => {
    localStorage.removeItem('halext_token');
    localStorage.removeItem('halext_access_code');
    set({ 
      token: null, 
      user: null 
    });
    // Note: Data store clearing will be handled by the component or a reset action
  },
}));
