# Cross-Platform Feature Parity Matrix

This document tracks feature parity between iOS and Web frontends,
ensuring both platforms maintain consistent functionality against
the shared backend API.

## Overview

The halext-org application consists of:
- **Backend**: FastAPI Python application (`/backend`)
- **iOS Client**: SwiftUI application (`/ios`)
- **Web Client**: React/TypeScript application (`/frontend`)

Both frontends communicate with the same backend API, requiring
consistent data models and feature implementations.

---

## Feature Matrix

### Legend
- `[x]` - Fully implemented and tested
- `[~]` - Partial implementation
- `[ ]` - Not implemented
- `N/A` - Not applicable for this platform

---

## 1. Smart Generator (AI-Powered Task/Event Generation)

Natural language processing to generate structured tasks, events,
and smart lists from user prompts.

| Feature | Backend API | iOS | Web | Notes |
|---------|-------------|-----|-----|-------|
| Generate tasks from NL | `[x]` | `[x]` | `[~]` | Web needs UI |
| Generate events from NL | `[x]` | `[x]` | `[~]` | Web needs UI |
| Generate smart lists | `[x]` | `[x]` | `[ ]` | Web not started |
| Model selection | `[x]` | `[x]` | `[ ]` | |
| Context awareness | `[x]` | `[x]` | `[ ]` | Existing tasks, events |

### API Endpoint
```
POST /api/ai/generate-tasks
```

### Request Schema
```json
{
  "prompt": "string (required)",
  "context": {
    "timezone": "string (required)",
    "current_date": "ISO8601 datetime (required)",
    "existing_task_titles": ["string"],
    "upcoming_event_dates": ["ISO8601 datetime"]
  },
  "model": "string (optional)"
}
```

### Response Schema
```json
{
  "tasks": [{
    "title": "string",
    "description": "string",
    "due_date": "ISO8601 datetime | null",
    "priority": "high | medium | low",
    "labels": ["string"],
    "estimated_minutes": "integer | null",
    "subtasks": ["string"],
    "reasoning": "string"
  }],
  "events": [{
    "title": "string",
    "description": "string",
    "start_time": "ISO8601 datetime",
    "end_time": "ISO8601 datetime",
    "location": "string | null",
    "recurrence_type": "none | daily | weekly | monthly",
    "reasoning": "string"
  }],
  "smart_lists": [{
    "name": "string",
    "description": "string",
    "category": "project | checklist | reference | goals",
    "items": ["string"],
    "reasoning": "string"
  }],
  "metadata": {
    "original_prompt": "string",
    "model": "string",
    "summary": "string"
  }
}
```

### iOS Model Reference
- File: `ios/Cafe/Core/Models/Models.swift`
- Request: Uses `AIChatRequest` with context
- Response: Custom handling in view model

### Web Model Reference
- File: `frontend/src/types/models.ts`
- Status: Needs dedicated types for smart generation

---

## 2. Recipe Feature

AI-powered recipe generation, meal planning, and ingredient management.

| Feature | Backend API | iOS | Web | Notes |
|---------|-------------|-----|-----|-------|
| Recipe generation | `[x]` | `[x]` | `[ ]` | |
| Meal plan generation | `[x]` | `[x]` | `[ ]` | |
| Ingredient substitution | `[x]` | `[x]` | `[ ]` | |
| Ingredient analysis | `[x]` | `[x]` | `[ ]` | |
| Save recipes | `[x]` | `[x]` | `[ ]` | |
| Recipe collections | `[x]` | `[x]` | `[ ]` | |

### API Endpoints
```
POST /api/ai/recipes/generate
POST /api/ai/recipes/meal-plan
POST /api/ai/recipes/substitutions
POST /api/ai/recipes/analyze-ingredients
```

### Recipe Schema
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "ingredients": [{
    "id": "string",
    "name": "string",
    "amount": "string",
    "unit": "string | null",
    "notes": "string | null",
    "is_optional": "boolean"
  }],
  "instructions": [{
    "id": "string",
    "step_number": "integer",
    "instruction": "string",
    "time_minutes": "integer | null",
    "image_url": "string | null",
    "timer_name": "string | null"
  }],
  "prep_time_minutes": "integer",
  "cook_time_minutes": "integer",
  "total_time_minutes": "integer",
  "servings": "integer",
  "difficulty": "beginner | intermediate | advanced | expert",
  "cuisine": "string | null",
  "image_url": "string | null",
  "nutrition": {
    "calories": "integer | null",
    "protein": "float | null",
    "carbohydrates": "float | null",
    "fat": "float | null",
    "fiber": "float | null",
    "sugar": "float | null",
    "sodium": "float | null"
  },
  "tags": ["string"],
  "matched_ingredients": ["string"],
  "missing_ingredients": ["string"],
  "match_score": "float"
}
```

### iOS Model Reference
- File: `ios/Cafe/Core/Models/RecipeModels.swift`
- Key Types: `Recipe`, `RecipeIngredient`, `CookingStep`, `NutritionInfo`

### Web Model Reference
- File: `frontend/src/types/models.ts`
- Key Types: `Recipe`, `RecipeIngredient`, `RecipeInstruction`, `RecipeNutrition`

---

## 3. Finance/Budget Tracking

Financial management including accounts, transactions, and budgets.

| Feature | Backend API | iOS | Web | Notes |
|---------|-------------|-----|-----|-------|
| List accounts | `[x]` | `[x]` | `[~]` | |
| Create/update accounts | `[x]` | `[x]` | `[~]` | |
| Delete accounts | `[x]` | `[x]` | `[~]` | |
| List transactions | `[x]` | `[x]` | `[~]` | |
| Create transactions | `[x]` | `[x]` | `[~]` | |
| List budgets | `[x]` | `[x]` | `[~]` | |
| Create/update budgets | `[x]` | `[x]` | `[~]` | |
| Delete budgets | `[x]` | `[x]` | `[~]` | |
| Budget progress | `[x]` | `[x]` | `[ ]` | |
| Budget progress summary | `[x]` | `[x]` | `[ ]` | |
| Financial summary | `[x]` | `[x]` | `[~]` | |
| Plaid integration | `[~]` | `[~]` | `[ ]` | Mock only |

### API Endpoints
```
GET    /api/finance/accounts
POST   /api/finance/accounts
GET    /api/finance/accounts/{id}
PUT    /api/finance/accounts/{id}
DELETE /api/finance/accounts/{id}

GET    /api/finance/transactions
POST   /api/finance/transactions

GET    /api/finance/budgets
POST   /api/finance/budgets
PATCH  /api/finance/budgets/{id}
DELETE /api/finance/budgets/{id}

GET    /api/finance/budgets/progress
GET    /api/finance/budgets/{id}/progress
GET    /api/finance/budgets/progress/summary
POST   /api/finance/budgets/{id}/sync
POST   /api/finance/budgets/sync-all

GET    /api/finance/summary
```

### Account Schema
```json
{
  "id": "integer",
  "owner_id": "integer",
  "account_name": "string",
  "account_type": "checking | savings | credit | investment | loan | other",
  "institution_name": "string | null",
  "account_number": "string | null",
  "balance": "float",
  "currency": "string",
  "is_active": "boolean",
  "last_synced": "ISO8601 datetime | null",
  "theme_emoji": "string | null",
  "accent_color": "string | null",
  "created_at": "ISO8601 datetime",
  "updated_at": "ISO8601 datetime"
}
```

### Transaction Schema
```json
{
  "id": "integer",
  "account_id": "integer",
  "owner_id": "integer",
  "amount": "float",
  "description": "string",
  "category": "income | groceries | dining | transportation | ...",
  "transaction_type": "debit | credit",
  "transaction_date": "ISO8601 datetime | null",
  "merchant": "string | null",
  "notes": "string | null",
  "tags": ["string"],
  "mood_icon": "string | null",
  "created_at": "ISO8601 datetime"
}
```

### Budget Schema
```json
{
  "id": "integer",
  "owner_id": "integer",
  "name": "string",
  "category": "string",
  "limit_amount": "float",
  "spent_amount": "float",
  "period": "weekly | monthly | quarterly | yearly",
  "emoji": "string | null",
  "color_hex": "string | null",
  "start_date": "ISO8601 datetime | null",
  "end_date": "ISO8601 datetime | null",
  "is_active": "boolean",
  "goal_amount": "float | null",
  "rollover_enabled": "boolean",
  "alert_threshold": "float",
  "created_at": "ISO8601 datetime",
  "updated_at": "ISO8601 datetime"
}
```

### iOS Model Reference
- File: `ios/Cafe/Core/Models/FinanceModels.swift`
- Key Types: `BankAccount`, `Transaction`, `Budget`, `BudgetProgress`, `FinancialSummary`

### Web Model Reference
- File: `frontend/src/types/models.ts`
- Status: Needs dedicated finance types

---

## 4. Presence/Status System

Real-time user presence and status tracking.

| Feature | Backend API | iOS | Web | Notes |
|---------|-------------|-----|-----|-------|
| Update own presence | `[x]` | `[x]` | `[~]` | |
| Get partner presence | `[x]` | `[x]` | `[~]` | |
| WebSocket updates | `[x]` | `[x]` | `[~]` | |
| Status messages | `[x]` | `[x]` | `[~]` | |
| Activity tracking | `[x]` | `[x]` | `[ ]` | |

### API Endpoints
```
POST /api/users/presence
GET  /api/users/{username}/presence
WS   /ws/presence
```

### Presence Update Schema
```json
{
  "is_online": "boolean | null",
  "status": "online | away | busy | offline",
  "current_activity": "string | null",
  "status_message": "string | null"
}
```

### Partner Presence Schema
```json
{
  "username": "string",
  "is_online": "boolean",
  "status": "online | away | busy | offline",
  "current_activity": "string | null",
  "status_message": "string | null",
  "last_seen": "ISO8601 datetime | null"
}
```

### iOS Model Reference
- File: `ios/Cafe/Core/Models/Models.swift`
- Key Types: Part of core models (PartnerPresence assumed)

### Web Model Reference
- File: `frontend/src/types/models.ts`
- Status: Basic types exist

---

## 5. Dashboard Customization

Configurable dashboard with widgets and layouts.

| Feature | Backend API | iOS | Web | Notes |
|---------|-------------|-----|-----|-------|
| Layout presets | `[x]` | `[x]` | `[x]` | |
| Custom layouts | `[x]` | `[x]` | `[x]` | |
| Widget configuration | `[x]` | `[x]` | `[x]` | |
| Save layouts | `[x]` | `[x]` | `[x]` | |
| Card size options | `[x]` | `[x]` | `[~]` | |
| Time-based visibility | `[~]` | `[x]` | `[ ]` | iOS only |

### API Endpoints
```
GET  /api/layout-presets/
POST /api/layout-presets/
PUT  /api/layout-presets/{id}
DELETE /api/layout-presets/{id}
GET  /api/pages/
POST /api/pages/
PUT  /api/pages/{id}
POST /api/pages/{page_id}/apply-preset/{preset_id}
```

### Layout Column Schema
```json
{
  "id": "string",
  "title": "string",
  "width": "integer",
  "widgets": [{
    "id": "string",
    "type": "string",
    "title": "string",
    "config": "object | null"
  }]
}
```

### iOS Widget Types
From `DashboardModels.swift`:
- welcome, aiGenerator, todayTasks, upcomingTasks
- overdueTasks, tasksStats, calendar, upcomingEvents
- quickActions, weather, recentActivity, notes
- aiSuggestions, socialActivity, mealPlanning
- iosFeatures, allApps, customList

### Web Widget Types
From `models.ts`:
- tasks, events, notes, gift-list, openwebui

### iOS Model Reference
- File: `ios/Cafe/Features/Core/Dashboard/Models/DashboardModels.swift`
- Key Types: `DashboardCard`, `CardConfiguration`, `DashboardLayout`, `CardSize`

### Web Model Reference
- File: `frontend/src/types/models.ts`
- Key Types: `LayoutWidget`, `LayoutColumn`, `LayoutPreset`, `WidgetType`

---

## Enum Value Reference

### Difficulty Levels
Used in: Recipes
```
beginner, intermediate, advanced, expert
```

### Account Types
Used in: Finance
```
checking, savings, credit, investment, loan, other
```

### Transaction Categories
Used in: Finance
```
income, groceries, dining, transportation, utilities,
entertainment, healthcare, shopping, housing, insurance,
education, travel, transfer, other
```

### Budget Periods
Used in: Finance
```
weekly, monthly, quarterly, yearly
```

### Presence Status
Used in: Presence/Status
```
online, away, busy, offline
```

### Recurrence Types
Used in: Events, Smart Generation
```
none, daily, weekly, monthly
```

### Priority Levels
Used in: Tasks, Smart Generation
```
high, medium, low
```

---

## Testing

### Running Parity Tests
```bash
cd backend
pytest tests/test_cross_platform_parity.py -v
```

### Test Categories
1. **Schema Validation** - Verify API responses match documented schemas
2. **Enum Consistency** - Verify enum values match across platforms
3. **Contract Tests** - Verify authentication and error handling
4. **Model Compatibility** - Verify data structures are compatible

---

## Adding New Features

When adding a new feature that should be available on both platforms:

1. **Backend First**
   - Add API endpoint in appropriate router
   - Add Pydantic schemas in `schemas.py`
   - Add tests in `tests/test_cross_platform_parity.py`

2. **Document the Contract**
   - Add section to this document
   - Document request/response schemas
   - Document any enum values

3. **iOS Implementation**
   - Add Swift models to appropriate Models file
   - Implement CodingKeys for snake_case conversion
   - Add to iOS feature matrix in this document

4. **Web Implementation**
   - Add TypeScript types to `models.ts`
   - Implement API service
   - Add to Web feature matrix in this document

5. **Verification**
   - Run parity tests
   - Manual testing on both platforms
   - Update feature matrix status

---

## Changelog

### 2025-11-22
- Initial feature matrix created
- Added parity validation tests
- Documented 5 core features:
  - Smart Generator
  - Recipe Feature
  - Finance/Budget Tracking
  - Presence/Status System
  - Dashboard Customization
