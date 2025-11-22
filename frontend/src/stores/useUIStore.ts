import { create } from 'zustand';
import type { MenuSection } from '../types/models';

interface UIState {
  isLoading: boolean;
  appMessage: string | null;
  activeSection: MenuSection;
  isCreateOverlayOpen: boolean;
  isSmartGenOpen: boolean;
  
  // Actions
  setLoading: (loading: boolean) => void;
  setAppMessage: (message: string | null) => void;
  setActiveSection: (section: MenuSection) => void;
  setCreateOverlayOpen: (open: boolean) => void;
  setSmartGenOpen: (open: boolean) => void;
}

export const useUIStore = create<UIState>((set) => ({
  isLoading: false,
  appMessage: null,
  activeSection: 'dashboard',
  isCreateOverlayOpen: false,
  isSmartGenOpen: false,

  setLoading: (loading) => set({ isLoading: loading }),
  setAppMessage: (message) => set({ appMessage: message }),
  setActiveSection: (section) => set({ activeSection: section }),
  setCreateOverlayOpen: (open) => set({ isCreateOverlayOpen: open }),
  setSmartGenOpen: (open) => set({ isSmartGenOpen: open }),
}));
