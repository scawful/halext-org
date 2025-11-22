# Frontend Refactoring - State Management & Architecture

## Summary
Implemented a comprehensive refactoring of the frontend state management system, moving from a monolithic "God Component" (`App.tsx`) pattern to a modular store-based architecture using **Zustand**.

## Key Changes

### 1. **Zustand Stores**
Created three distinct stores to manage application state:
- **`useAuthStore`**: Handles authentication state (token, user profile), login/register logic, and access codes.
- **`useDataStore`**: Manages workspace data (tasks, events, pages, labels) and Dashboard layout manipulations.
- **`useUIStore`**: Controls global UI state (loading indicators, active navigation section, overlays).

### 2. **API Service Layer**
- Extracted all `fetch` logic from `App.tsx` into a dedicated **`src/services/api.ts`** class.
- Provides typed methods for all backend endpoints.
- Centralized error handling and token management.

### 3. **Component Decoupling**
- **`App.tsx`**: Reduced from ~480 lines to ~250 lines. Now focuses solely on routing, layout structure, and form inputs for creation panels.
- **`MenuBar.tsx`**: No longer receives props. Connects directly to stores for navigation state and search data.
- **`DashboardGrid.tsx`**: Decoupled from parent state. Connects to `useDataStore` for layout data and manipulation actions.

### 4. **Type Safety**
- Consolidated shared types (like `MenuSection`) into `src/types/models.ts` to prevent circular dependencies.
- Improved type imports across the codebase.

## Benefits
- **Reduced Prop Drilling**: Components access the data they need directly.
- **Better Performance**: Components only re-render when their specific slice of state changes.
- **Maintainability**: Business logic is separated from UI components.
- **Scalability**: Easier to add new features without cluttering the root component.

## Files Changed
- `src/App.tsx` (Major refactor)
- `src/components/layout/MenuBar.tsx` (Refactor)
- `src/components/layout/DashboardGrid.tsx` (Refactor)
- `src/services/api.ts` (New)
- `src/stores/*` (New)
- `src/types/models.ts` (Updated)
