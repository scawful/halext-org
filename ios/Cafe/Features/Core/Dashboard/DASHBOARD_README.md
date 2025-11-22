# Configurable Dashboard System

A fully customizable, widget-based dashboard for the Cafe iOS app with drag & drop support, layout presets, and persistent configurations.

## Features

### 1. Drag & Drop Layout
- Reorder cards by dragging them to new positions
- Real-time visual feedback during drag operations
- Automatic position recalculation

### 2. Widget-Style Cards
The dashboard supports multiple card types:

#### Task Cards
- **Today's Tasks**: Tasks due today
- **Upcoming Tasks**: Tasks for the next 7 days
- **Overdue Tasks**: Past due tasks with alert styling
- **Task Statistics**: Completion stats and metrics

#### Calendar & Events
- **Calendar**: Mini calendar view
- **Upcoming Events**: Next 7 days of events

#### Productivity
- **AI Generator**: Quick access to AI task generator
- **Quick Actions**: Common actions grid
- **Notes**: Quick note-taking widget

#### Information
- **Weather**: Current weather conditions
- **Recent Activity**: Recent task/event updates
- **AI Suggestions**: Smart suggestions based on patterns

#### Social
- **Social Activity**: Team member activity feed

#### Other
- **Welcome Header**: Personalized greeting
- **Meal Planning**: Recipe ideas and meal plans
- **iOS Features**: Discover iOS features
- **All Apps**: App grid navigator
- **Custom List**: User-defined task lists

### 3. Customization UI

#### Edit Mode
Tap the menu button (⋯) → "Edit Layout" to enter edit mode:
- Configure button (gear icon) appears on cards
- Delete button (X) appears on cards
- Drag cards to reorder

#### Customize Cards Screen
Access via menu → "Customize Cards":
- Add new cards from picker
- Reorder cards with drag handles
- Swipe to delete cards
- Duplicate existing cards
- Apply preset layouts

### 4. Card Configuration
Each card has individual settings:

#### General Settings
- **Show Card**: Toggle card visibility
- **Size**: Small, Medium, or Large
- **Show Header**: Display/hide card title
- **Auto-hide When Empty**: Hide when no data

#### Task Card Settings
- **Max Tasks**: Number of tasks to display (1-20)
- **Show Completed**: Include completed tasks

#### Event Card Settings
- **Max Events**: Number of events to show (1-10)
- **Days Ahead**: How many days to look ahead (1-30)

#### Time-based Display
- **Show Only at Specific Times**: Display card during certain hours
- Perfect for showing different cards at different times of day

### 5. Layout Presets

#### Built-in Presets
1. **Default**: Balanced view with all features
2. **Focus**: Minimal layout for productivity
3. **Overview**: Comprehensive dashboard
4. **Social**: Team collaboration focused

#### Custom Layouts
- Save current layout with a custom name
- Switch between saved layouts
- Delete custom layouts

### 6. Smart Features

#### Auto-hide Empty Cards
Cards can automatically hide when they have no content:
- Today's Tasks hides when no tasks today
- Overdue Tasks hides when caught up
- Events hide when no upcoming events

#### Time-based Cards
Show different cards at different times:
- Morning: Calendar and Today's Tasks
- Afternoon: AI Suggestions and Quick Actions
- Evening: Meal Planning and Notes

#### Suggested Cards
Future enhancement: AI-powered card suggestions based on:
- Usage patterns
- Time of day
- Day of week
- Task completion rates

## Architecture

### Models

#### `DashboardCard`
```swift
struct DashboardCard: Identifiable, Codable {
    let id: UUID
    let type: DashboardCardType
    var size: CardSize
    var position: Int
    var isVisible: Bool
    var configuration: CardConfiguration
}
```

#### `DashboardLayout`
```swift
struct DashboardLayout: Identifiable, Codable {
    let id: UUID
    var name: String
    var cards: [DashboardCard]
    var isDefault: Bool
    var createdAt: Date
}
```

#### `CardConfiguration`
```swift
struct CardConfiguration: Codable {
    var showHeader: Bool
    var autoHideWhenEmpty: Bool
    var maxTasksToShow: Int
    var maxEventsToShow: Int
    var calendarDaysAhead: Int
    var customListTitle: String?
    var showOnlyAtTime: TimeRange?
    // ... more settings
}
```

### Views

#### `DashboardView`
Main dashboard view with card rendering and customization controls.

#### `DashboardCardView`
Reusable card wrapper with edit mode controls.

#### `CardContentView`
Content renderer that switches between card types.

#### `DashboardCustomizationView`
Full-screen customization interface with:
- Card list with drag to reorder
- Add card picker
- Preset layouts
- Card management

#### `CardConfigurationView`
Individual card settings sheet.

#### `LayoutPresetsView`
Layout preset picker and custom layout management.

### Managers

#### `DashboardLayoutManager`
Singleton manager for layout persistence and manipulation:
- UserDefaults-based storage
- Layout CRUD operations
- Card visibility filtering
- Smart hiding logic

### ViewModels

#### `DashboardViewModel`
Data provider for dashboard cards:
- Task/Event fetching
- Statistics calculation
- Card data helpers
- Integration with DashboardLayoutManager

## Usage

### Basic Setup
The dashboard is automatically configured on first launch with the default layout.

### Adding a Card
1. Tap menu (⋯) → "Customize Cards"
2. Tap "Add Card"
3. Select card type from picker
4. Configure card settings

### Reordering Cards
**Method 1: Edit Mode**
1. Tap menu (⋯) → "Edit Layout"
2. Drag cards to new positions
3. Tap "Done Editing"

**Method 2: Customization Screen**
1. Tap menu (⋯) → "Customize Cards"
2. Enter edit mode (Edit button)
3. Drag cards using handles
4. Tap "Done"

### Configuring a Card
1. Enter edit mode
2. Tap gear icon on card
3. Adjust settings
4. Tap "Done"

### Applying a Preset
1. Tap menu (⋯) → "Layout Presets"
2. Select preset name
3. Layout applies immediately

### Saving Custom Layout
1. Configure cards as desired
2. Tap menu (⋯) → "Customize Cards"
3. Scroll to bottom → "Save Current Layout"
4. Enter layout name
5. Tap "Save"

## Persistence

### Storage
- Current layout: `UserDefaults` key `dashboard.currentLayout`
- Saved layouts: `UserDefaults` key `dashboard.savedLayouts`
- Data format: JSON-encoded models

### Syncing (Future)
CloudKit integration planned for:
- Cross-device layout sync
- Shared layouts between team members
- Layout templates marketplace

## File Structure

```
Dashboard/
├── README.md                          # This file
├── DashboardView.swift               # Main dashboard view
├── DashboardViewModel.swift          # Dashboard data & logic
├── Models/
│   └── DashboardModels.swift        # Card, Layout, Config models
├── Cards/
│   ├── DashboardCardView.swift      # Card wrapper component
│   └── CardContentView.swift        # Card content renderer
├── Views/
│   ├── DashboardCustomizationView.swift  # Customization screen
│   ├── CardConfigurationView.swift      # Card settings sheet
│   ├── LayoutPresetsView.swift         # Preset picker
│   └── ConfigurableDashboardView.swift # Alternate implementation
└── Managers/
    └── DashboardLayoutManager.swift # Layout persistence & logic
```

## Future Enhancements

### Smart Widgets
- [ ] AI-powered card suggestions
- [ ] Automatic card prioritization
- [ ] Context-aware card visibility

### Advanced Customization
- [ ] Card themes and colors
- [ ] Custom card creation
- [ ] Widget size flexibility (1x1, 2x1, 2x2 grid)

### Data & Sync
- [ ] CloudKit sync
- [ ] Export/import layouts
- [ ] Share layouts with team

### Analytics
- [ ] Card usage tracking
- [ ] Optimization suggestions
- [ ] A/B testing for layouts

### Accessibility
- [ ] VoiceOver improvements
- [ ] High contrast themes
- [ ] Larger text support

## Best Practices

### Card Design
1. Keep cards focused on single purpose
2. Use appropriate size for content
3. Enable auto-hide for empty states
4. Provide meaningful empty states

### Layout Design
1. Place frequently used cards at top
2. Group related cards together
3. Use time-based visibility for context
4. Save layouts for different contexts

### Performance
1. Cards lazy load their content
2. Empty cards are filtered out
3. Only visible cards render
4. Efficient drag & drop handling

## Testing

### Manual Testing Checklist
- [ ] Add all card types
- [ ] Drag to reorder cards
- [ ] Configure each card type
- [ ] Apply all presets
- [ ] Save custom layout
- [ ] Delete cards
- [ ] Test time-based visibility
- [ ] Test auto-hide behavior
- [ ] Switch between layouts
- [ ] Reset to default

### Edge Cases
- [ ] Empty dashboard (no cards)
- [ ] Single card
- [ ] All cards hidden
- [ ] Very long card list
- [ ] Duplicate card types
- [ ] Rapid layout switches

## Troubleshooting

### Cards Not Appearing
1. Check card visibility setting
2. Verify time-based display settings
3. Check auto-hide configuration
4. Ensure data is loading

### Drag & Drop Not Working
1. Enter edit mode first
2. Check if card has ID
3. Verify drop delegate setup

### Layout Not Persisting
1. Check UserDefaults access
2. Verify JSON encoding
3. Check for encoding errors in logs

### Configuration Not Saving
1. Ensure binding is correct
2. Verify manager is saving
3. Check configuration model

## Credits

Built for Cafe iOS app with love by the Halext team.
Powered by SwiftUI, Observation framework, and modern iOS design patterns.
