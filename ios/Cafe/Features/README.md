# Cafe App Features Architecture

This directory contains the feature modules for the Cafe iOS app, organized by functional domain.

## 📂 Core (The Productivity Engine)
*   **Dashboard**: Main entry point, widgets, and layout management.
*   **Tasks**: Task management, creation, and list views.
*   **Calendar**: Events, scheduling, and timeline views.
*   **SmartLists**: Filtering logic and custom list views.
*   **Templates**: Reusable task structures and AI generation from history.

## 📂 Connect (Communication & Collaboration)
*   **Messages**: Unified chat interface for AI agents and human contacts.
    *   *LegacyChat*: Deprecated AI-only chat (migrated to Messages).
*   **Social**: Social Circles (Backend-driven) and legacy CloudKit shared tasks.
*   **Goals**: Shared goals and milestones (Backend aligned).
*   **Memories**: Shared timeline and media (Backend aligned).

## 📂 Lifestyle (Domain Modules)
*   **Finance**: Budget tracking, accounts, and Plaid integration.
*   **Recipes**: Meal planning, ingredient tracking, and AI recipe generation.
*   **Pages**: Rich text documents, notes, and AI context sources.
*   **SharedFiles**: File management and iCloud sync.

## 📂 Intelligence (Cross-Cutting AI)
*   **AI**: Shared AI components, Agent Hub, and generative features.
    *   *Note: Feature-specific AI (like Recipe Gen) resides in its respective feature folder.*

## 📂 System (App Infrastructure)
*   **Auth**: Login, registration, and biometric security.
*   **Settings**: App configuration, theming, and preferences.
*   **Admin**: Server management, user administration, and system stats.
*   **Help**: Documentation, onboarding, and support resources.
*   **More**: Navigation routing and feature discovery.

## Alignment with Backend API
This structure aligns with the backend services defined in `IOS_BACKEND_API_SUPPORT.md`:
- `Connect/` maps to `/messages`, `/social`, `/goals`, `/memories`
- `Lifestyle/Finance` maps to `/finance`
- `System/Admin` maps to `/admin`
