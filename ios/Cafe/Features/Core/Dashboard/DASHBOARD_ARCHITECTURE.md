# Dashboard Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         DashboardView                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ Toolbar Menu                                              │  │
│  │  • Edit Layout Toggle                                     │  │
│  │  • Customize Cards                                        │  │
│  │  • Layout Presets                                         │  │
│  │  • Reset to Default                                       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ LazyVStack (Card Container)                               │  │
│  │                                                            │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │ DashboardCardView (Wrapper)                         │  │  │
│  │  │  • Edit Mode Controls                                │  │  │
│  │  │  • Drag/Drop Support                                 │  │  │
│  │  │                                                       │  │  │
│  │  │  ┌───────────────────────────────────────────────┐  │  │  │
│  │  │  │ CardContentView (Content Renderer)            │  │  │  │
│  │  │  │  • Switches on card.type                       │  │  │  │
│  │  │  │  • Renders specific card                       │  │  │  │
│  │  │  └───────────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │  ... (more cards)                                          │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ owns
                            ▼
            ┌───────────────────────────────┐
            │   DashboardViewModel          │
            │  • tasks: [Task]              │
            │  • events: [Event]            │
            │  • stats (computed)           │
            │  • layoutManager              │
            │  • shouldShowCard()           │
            │  • isCardEmpty()              │
            └───────────────────────────────┘
                    │               │
                    │               │ references
          fetches   │               │
            data    │               ▼
                    │   ┌────────────────────────────────┐
                    │   │ DashboardLayoutManager         │
                    │   │  • currentLayout               │
                    │   │  • savedLayouts                │
                    │   │  • addCard()                   │
                    │   │  • removeCard()                │
                    │   │  • updateCard()                │
                    │   │  • moveCard()                  │
                    │   │  • visibleCards()              │
                    │   │  • applyPreset()               │
                    │   └────────────────────────────────┘
                    │                   │
                    │                   │ persists to
                    ▼                   ▼
        ┌──────────────────┐   ┌────────────────┐
        │   SyncManager    │   │  UserDefaults  │
        │  • loadTasks()   │   │  • layouts     │
        │  • loadEvents()  │   │  • presets     │
        └──────────────────┘   └────────────────┘
```

## Data Models

```
┌─────────────────────────────────────────────────────────────┐
│                     DashboardLayout                          │
│  • id: UUID                                                  │
│  • name: String                                              │
│  • cards: [DashboardCard]                                    │
│  • isDefault: Bool                                           │
│  • createdAt: Date                                           │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ contains
                        ▼
        ┌───────────────────────────────────┐
        │      DashboardCard                │
        │  • id: UUID                       │
        │  • type: DashboardCardType        │
        │  • size: CardSize                 │
        │  • position: Int                  │
        │  • isVisible: Bool                │
        │  • configuration: CardConfiguration│
        └───────────────────────────────────┘
                │                   │
                │                   │ contains
      has type  │                   │
                ▼                   ▼
    ┌─────────────────────┐   ┌──────────────────────────┐
    │ DashboardCardType   │   │  CardConfiguration       │
    │  • welcome          │   │  • showHeader            │
    │  • aiGenerator      │   │  • autoHideWhenEmpty     │
    │  • todayTasks       │   │  • maxTasksToShow        │
    │  • overdueTasks     │   │  • maxEventsToShow       │
    │  • tasksStats       │   │  • calendarDaysAhead     │
    │  • calendar         │   │  • customListTitle       │
    │  • upcomingEvents   │   │  • showOnlyAtTime        │
    │  • quickActions     │   │  • taskFilterProjectId   │
    │  • weather          │   │  • taskFilterLabelIds    │
    │  • recentActivity   │   │  • showCompletedTasks    │
    │  • notes            │   └──────────────────────────┘
    │  • aiSuggestions    │
    │  • socialActivity   │
    │  • mealPlanning     │
    │  • iosFeatures      │
    │  • allApps          │
    │  • customList       │
    └─────────────────────┘
            │
            │ has
            ▼
    ┌──────────────┐
    │  CardSize    │
    │  • small     │
    │  • medium    │
    │  • large     │
    └──────────────┘
```

## View Hierarchy

```
NavigationStack
 └── DashboardView
      ├── ScrollView
      │    └── LazyVStack
      │         └── ForEach(visibleCards)
      │              └── DashboardCardView
      │                   ├── CardContentView (renders content)
      │                   └── Edit Controls (conditional)
      │
      ├── Sheets (conditional)
      │    ├── SmartGeneratorView
      │    └── DashboardCustomizationView
      │
      └── Toolbar
           └── Menu
                ├── Edit Layout
                ├── Customize Cards
                ├── Layout Presets
                └── Reset
```

## Customization Flow

```
┌────────────────┐
│ User taps menu │
└────────┬───────┘
         │
         ▼
┌─────────────────────────┐
│ Selects "Customize"     │
└────────┬────────────────┘
         │
         ▼
┌───────────────────────────────────────────┐
│ DashboardCustomizationView                │
│  ┌─────────────────────────────────────┐  │
│  │ Card List (with drag handles)       │  │
│  │  • Swipe to delete                  │  │
│  │  • Drag to reorder                  │  │
│  │  • Context menu (configure/delete)  │  │
│  └─────────────────────────────────────┘  │
│                                            │
│  ┌─────────────────────────────────────┐  │
│  │ "Add Card" button                   │  │
│  └────────┬────────────────────────────┘  │
└───────────┼────────────────────────────────┘
            │
            ▼
    ┌────────────────────┐
    │ CardPickerView     │
    │  • By Category     │
    │  • Tap to add      │
    └────────────────────┘
```

## Card Rendering Flow

```
┌─────────────────────────────────┐
│ DashboardView.visibleCards      │
│  1. Get all cards from layout   │
│  2. Filter by visibility         │
│  3. Filter by time               │
│  4. Filter by auto-hide          │
│  5. Sort by position             │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ ForEach(visibleCards)           │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ DashboardCardView(card)                 │
│  • Wraps content                        │
│  • Shows edit controls if editing       │
│  • Handles drag/drop                    │
└────────┬────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│ CardContentView(card, viewModel)         │
│  • Switches on card.type                 │
│  • Renders appropriate view              │
│  • Passes data from viewModel            │
└──────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────┐
│ Specific Card View                       │
│  • TodayTasksCardContent                 │
│  • UpcomingEventsCardContent             │
│  • WeatherCardContent                    │
│  • etc.                                  │
└──────────────────────────────────────────┘
```

## Edit Mode Flow

```
┌────────────────────┐
│ User taps "Edit"   │
└────────┬───────────┘
         │
         ▼
┌────────────────────────────────┐
│ isEditMode = true              │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────────────┐
│ Cards show edit controls               │
│  ┌──────────────────────────────────┐  │
│  │ ┌────┐  Card Content   ┌────┐   │  │
│  │ │ ⚙️ │                 │ ❌  │   │  │
│  │ └────┘                 └────┘   │  │
│  └──────────────────────────────────┘  │
└───┬────────────────┬───────────────────┘
    │                │
    │ tap gear       │ tap X
    ▼                ▼
┌─────────────┐  ┌──────────────┐
│ Configure   │  │ Remove card  │
│ Card        │  │ (animated)   │
└─────────────┘  └──────────────┘
```

## Persistence Flow

```
┌───────────────────────┐
│ User modifies layout  │
└──────────┬────────────┘
           │
           ▼
┌──────────────────────────────────┐
│ DashboardLayoutManager           │
│  • addCard()                     │
│  • removeCard()                  │
│  • updateCard()                  │
│  • moveCard()                    │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│ saveCurrentLayout()              │
│  1. Encode layout to JSON        │
│  2. Save to UserDefaults         │
└──────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│ UserDefaults                     │
│  key: "dashboard.currentLayout"  │
│  value: JSON string              │
└──────────────────────────────────┘
```

## Preset Application Flow

```
┌──────────────────────┐
│ User selects preset  │
└──────────┬───────────┘
           │
           ▼
┌────────────────────────────────┐
│ DashboardLayoutManager         │
│  applyPreset(preset)           │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────────┐
│ 1. Copy preset cards               │
│ 2. Generate new UUIDs              │
│ 3. Set as currentLayout            │
│ 4. Save to UserDefaults            │
└──────────┬─────────────────────────┘
           │
           ▼
┌────────────────────────────────────┐
│ UI updates automatically           │
│  (via @Observable)                 │
└────────────────────────────────────┘
```

## Drag & Drop Flow

```
┌──────────────────────┐
│ User starts drag     │
└──────────┬───────────┘
           │
           ▼
┌────────────────────────────────┐
│ onDrag triggered               │
│  • Set draggedCard             │
│  • Create NSItemProvider       │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────┐
│ User drags over another card   │
└──────────┬─────────────────────┘
           │
           ▼
┌────────────────────────────────────┐
│ CardDropDelegate.dropEntered       │
│  1. Find source & destination      │
│  2. Update positions               │
│  3. Animate reorder                │
└──────────┬─────────────────────────┘
           │
           ▼
┌────────────────────────────────────┐
│ User releases                      │
└──────────┬─────────────────────────┘
           │
           ▼
┌────────────────────────────────────┐
│ CardDropDelegate.performDrop       │
│  • Clear draggedCard               │
│  • Save to persistence             │
└────────────────────────────────────┘
```

## State Management

```
┌─────────────────────────────────────────┐
│ @Observable Classes                     │
│                                          │
│  DashboardViewModel                     │
│   • Automatically tracks changes        │
│   • Views auto-update                   │
│                                          │
│  DashboardLayoutManager                 │
│   • Singleton instance                  │
│   • Shared across views                 │
│   • Auto-publishes updates              │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ @State Variables (View-local)           │
│                                          │
│  • isEditMode: Bool                     │
│  • showingCustomization: Bool           │
│  • draggedCard: DashboardCard?          │
│  • showAIGenerator: Bool                │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Bindings                                │
│                                          │
│  DashboardCustomizationView             │
│   @Binding var layout: DashboardLayout  │
│                                          │
│  CardConfigurationView                  │
│   @Binding var card: DashboardCard      │
└─────────────────────────────────────────┘
```

## Component Relationships

```
DashboardView
  ├─ uses → DashboardViewModel
  │           └─ references → DashboardLayoutManager
  │
  ├─ contains → DashboardCardView (multiple)
  │              └─ contains → CardContentView
  │                            └─ renders → Specific Card Content
  │
  ├─ presents → DashboardCustomizationView
  │              ├─ presents → CardPickerView
  │              └─ presents → CardConfigurationView
  │
  └─ uses → DashboardLayoutManager
             └─ persists to → UserDefaults
```

## Key Interactions

```
User Action              → System Response
─────────────────────────────────────────────
Tap "Edit Layout"       → Show edit controls
Tap gear icon           → Open card config sheet
Tap X icon              → Remove card (animated)
Tap "Add Card"          → Show card picker
Select card from picker → Add to layout
Drag card               → Visual feedback + reorder
Tap "Apply Preset"      → Replace all cards
Tap "Save Layout"       → Store in saved layouts
Pull to refresh         → Reload data
```

## Design Patterns Used

1. **MVVM**: View-ViewModel separation
2. **Singleton**: Shared layout manager
3. **Observer**: @Observable for reactive updates
4. **Strategy**: Card type rendering
5. **Factory**: Preset layout creation
6. **Repository**: Layout persistence
7. **Delegate**: Drag & drop handling
8. **Composition**: Card wrapper + content

## Performance Optimizations

```
LazyVStack
  └─ Only renders visible cards
     └─ Cards load content on demand
        └─ Empty cards can auto-hide
           └─ Filtered before rendering
              └─ Minimal re-renders
```

---

This architecture provides:
- ✅ Separation of concerns
- ✅ Reusable components
- ✅ Testable code
- ✅ Scalable design
- ✅ Maintainable structure
