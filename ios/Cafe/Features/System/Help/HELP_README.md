# Help Feature

Comprehensive in-app help and support system for the Cafe iOS app.

## Overview

The Help feature provides users with complete documentation, guides, FAQs, and troubleshooting information directly within the app. It includes:

- **Feature Status Dashboard**: Visual indicators for all app features showing their current status (Ready, In Progress, or Planned)
- **Getting Started Guides**: Step-by-step tutorials for common tasks
- **FAQ Section**: Answers to frequently asked questions with expandable content
- **Troubleshooting**: Solutions to common problems and issues
- **About Section**: App version, credits, links, and technology information

## File Structure

```
Features/Help/
├── HelpView.swift         # Main help view with all sections
└── README.md             # This file
```

## Navigation Access

The Help view is accessible from multiple locations:

1. **More Tab**: Featured banner at the top of the More view
2. **More Tab Grid**: Help card in the System category
3. **Settings**: Dedicated "Help & Support" section

## Features

### 1. Feature Status Section

Shows all app features organized by category with status indicators:

- ✅ **Ready**: Feature is fully implemented and available
- 🚧 **In Progress**: Feature is being developed
- 📋 **Planned**: Feature is planned for future release

Categories include:
- Core Features (Tasks, Calendar, AI Chat, Smart Generator)
- Productivity (Templates, Smart Lists, Pages, Recipes)
- iOS Integration (Widgets, Siri, Live Activities, etc.)
- Communication (Messages, Group Conversations)
- Customization (Themes, Gestures, Biometric Lock)
- Finance (Budget Tracking)
- Admin Features (User Management, AI Clients, Content)

### 2. Getting Started Guides

Interactive, collapsible step-by-step guides for:

- Creating your first task
- Using voice input
- Setting up calendar events
- Using AI features (Chat Assistant & Smart Task Generator)
- Document scanning

Each guide includes:
- Numbered steps with clear instructions
- Visual icons for easy identification
- Pro tips with helpful hints

### 3. FAQ Section

Common questions organized as expandable items:

- How to sync data across devices
- Offline functionality
- Widget setup
- Siri shortcuts configuration
- Live Activities explanation
- Theme customization
- Task sharing capabilities
- Focus Filters usage
- Privacy and security information

### 4. Troubleshooting Section

Solutions to common issues:

- Widgets not updating
- Voice input problems
- Notification issues
- Siri shortcuts not responding
- Sync problems
- Face ID / Touch ID issues
- Handoff connectivity
- Performance problems

Each troubleshooting item shows:
- The problem description
- Step-by-step solution
- Alternative approaches when applicable

### 5. About Section

App information including:

- App version and build number
- Credits and description
- Privacy Policy link
- Terms of Service link
- Support & Feedback contact
- Website link
- Technology badges (SwiftUI, Vision, Speech, WidgetKit, etc.)
- Copyright information

## Design Patterns

### UI Components

The Help view uses several reusable components:

- **QuickLinkCard**: Navigation cards for quick access
- **FeatureStatusCategory**: Collapsible sections for feature lists
- **FeatureStatusRow**: Individual feature with icon, description, and status badge
- **GettingStartedCard**: Expandable tutorial cards
- **StepRow**: Numbered instruction steps
- **TipBox**: Highlighted tips and pro advice
- **FAQItem**: Expandable question/answer pairs
- **TroubleshootingItem**: Problem/solution pairs with icons
- **AboutLinkButton**: External links with icons
- **TechnologyBadge**: Pill-shaped badges for technologies

### State Management

- `@Environment(ThemeManager.self)`: Access to app theming
- `@State private var searchText`: Search functionality
- `@State private var expandedSections`: Track which sections are expanded

### Navigation

Uses NavigationStack with programmatic navigation destinations for:
- iOS Features detail view
- Advanced Features view
- Settings view
- External links (web and email)

### Search Functionality

The view includes a search bar that filters visible sections based on keywords. Sections are shown when:
- Search text is empty (show all)
- Section keywords match the search query

## Theming

The view fully integrates with the app's theme system:

- Uses `themeManager.textColor` for primary text
- Uses `themeManager.secondaryTextColor` for secondary text
- Uses `themeManager.cardBackgroundColor` for cards
- Uses `themeManager.backgroundColor` for background
- Maintains consistent spacing and styling with the rest of the app

## Future Enhancements

Potential additions:

1. **Video Tutorials**: Embedded video guides for complex features
2. **Interactive Walkthroughs**: First-time user onboarding flow
3. **Contextual Help**: Deep links to relevant help sections from other views
4. **Search Improvements**: Full-text search across all help content
5. **Feedback Integration**: In-app feedback form submission
6. **Version-Specific Tips**: Show what's new based on app version
7. **Accessibility Guide**: Dedicated section for accessibility features
8. **Keyboard Shortcuts**: Documentation for iPad keyboard shortcuts
9. **Tips of the Day**: Rotating helpful tips on the dashboard

## Maintenance

When adding new features to the app:

1. Update the **Feature Status Section** with the new feature
2. Add to the appropriate category (Core, Productivity, iOS Integration, etc.)
3. Set the correct status (Ready, In Progress, or Planned)
4. If it's a major feature, consider adding a **Getting Started Guide**
5. Add relevant **FAQ entries** for common questions
6. Include **Troubleshooting** entries for known issues

## Testing Checklist

- [ ] All navigation links work correctly
- [ ] Search filters sections appropriately
- [ ] Expandable sections animate smoothly
- [ ] External links open correctly (Privacy, Terms, Support, Website)
- [ ] Version and build numbers display correctly
- [ ] All icons render properly
- [ ] Theme changes are reflected immediately
- [ ] Content is accessible with VoiceOver
- [ ] Layout works on iPhone and iPad
- [ ] Portrait and landscape orientations work correctly

## Credits

Developed as part of the Cafe iOS app to provide comprehensive in-app documentation and support for users.
