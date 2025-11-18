# Halext Org - User Guide

Welcome to Halext Org! This guide will help you get the most out of your productivity suite.

## Table of Contents

- [Getting Started](#getting-started)
- [Web App](#web-app)
  - [Dashboard & Pages](#dashboard--pages)
  - [Tasks](#tasks)
  - [Calendar & Events](#calendar--events)
  - [AI Features](#ai-features)
  - [Customization](#customization)
- [iOS App](#ios-app)
  - [Installation](#installation)
  - [Core Features](#core-features)
  - [Sync](#sync)
- [Tips & Tricks](#tips--tricks)
- [Troubleshooting](#troubleshooting)

---

## Getting Started

### First Time Setup

1. **Create Account**:
   - Visit https://org.halext.org (or http://localhost:5173 for local dev)
   - Click "Register"
   - Enter username, email, and password
   - (Production only) Enter access code if required

2. **Explore Demo Content**:
   - New accounts come with example tasks, events, and pages
   - These help you understand the UI
   - Feel free to delete or modify them!

3. **Login**:
   - Enter your credentials
   - Click "Sign In"
   - You're in!

### Quick Tour

When you first login, you'll see:
- **Dashboard**: Your customizable workspace with widgets
- **Menu Bar**: Navigate between different sections
- **Sidebar**: Quick access to pages and tools

---

## Web App

### Dashboard & Pages

**What are Pages?**
Pages are customizable workspaces that contain widgets. Think of them as different desktops for different contexts (work, personal, projects, etc.).

**Creating a Page**:
1. Click the "+" button in sidebar
2. Enter page title and description
3. Choose visibility (private/public)
4. Click "Create Page"

**Managing Pages**:
- **Switch Pages**: Click page name in sidebar
- **Edit Page**: Click edit icon next to page name
- **Delete Page**: Click delete icon (careful!)
- **Share Page**: Click share icon to collaborate

**Working with Columns**:
- **Add Column**: Click "+ Add Column" button
- **Rename Column**: Click on column title to edit
- **Delete Column**: Click × icon on column
- **Reorder**: Drag column headers

**Adding Widgets**:
1. Click "+ Add Widget" in any column
2. Choose widget type:
   - **Tasks**: Your todo list
   - **Events**: Upcoming calendar events
   - **Notes**: Quick notes with markdown support
   - **Gift List**: Track gift ideas for people
   - **OpenWebUI**: AI chat interface (if configured)
3. Widget appears in column

**Customizing Widgets**:
- **Reorder**: Drag widget by its header
- **Move Between Columns**: Drag to different column
- **Edit**: Click on widget content
- **Remove**: Click × on widget

### Tasks

**Creating Tasks**:
1. Go to Dashboard or Tasks section
2. Click "Add Task" or use task widget
3. Fill in:
   - **Title** (required): What needs to be done
   - **Description** (optional): Details and notes
   - **Due Date** (optional): Deadline
   - **Labels** (optional): Categorize with tags
4. Click "Create Task"

**Using AI Task Assistant**:
1. When creating/editing a task
2. Click "Get AI Suggestions"
3. AI provides:
   - ✅ Subtask breakdown
   - 🏷️ Label suggestions
   - ⏱️ Time estimates
   - 🎯 Priority recommendations
4. Review and apply suggestions

**Managing Tasks**:
- **Complete**: Click checkbox
- **Edit**: Click on task
- **Delete**: Click delete button
- **Filter**: Use label filters in task widget

**Labels**:
- Color-coded categories
- Create new labels on the fly
- Click label to filter tasks
- Suggested by AI for new tasks

### Calendar & Events

**Adding Events**:
1. Navigate to Calendar section
2. Click "Add Event"
3. Fill in:
   - **Title**: Event name
   - **Description**: Details
   - **Start/End Time**: When it happens
   - **Location**: Where (optional)
   - **Recurrence**: Repeat pattern (optional)
4. Click "Create Event"

**Recurring Events**:
- Choose recurrence type: None, Daily, Weekly, Monthly
- Set interval (e.g., every 2 weeks)
- Set end date (optional)
- Example: "Daily standup, every weekday, for 3 months"

**AI Event Analysis**:
When creating events, AI can:
- **Detect Conflicts**: Warns about overlapping events
- **Suggest Times**: Recommends optimal time slots
- **Generate Summary**: Creates event description
- **Preparation Steps**: Lists what to prepare

**Calendar Views**:
- **List View**: All events in chronological order
- **Day View**: Today's schedule
- **Week View**: 7-day overview
- **Month View**: Monthly calendar (coming soon)

### AI Features

**AI Chat**:
1. Click "AI Chat" in menu bar
2. Type your message
3. Press Enter or click Send
4. AI responds with streaming text
5. Continue conversation with context

**Use Cases**:
- "Help me prioritize my tasks for today"
- "Summarize my meeting notes"
- "Create a plan for learning React"
- "What should I prepare for tomorrow's presentation?"

**AI Task Suggestions**:
- Automatically breaks down complex tasks
- Estimates completion time
- Suggests priority level with reasoning
- Recommends relevant labels
- Creates actionable subtasks

**AI Note Features**:
- Summarize long notes
- Extract action items
- Generate tags
- Improve formatting

**Streaming Responses**:
- AI types in real-time
- See responses as they're generated
- Cancel if needed
- Faster perceived response time

### Customization

**Dashboard Layouts**:
- Drag widgets to reorder
- Create multiple columns
- Adjust column widths
- Save custom arrangements

**Themes** (coming soon):
- Light mode
- Dark mode (current default)
- Custom colors
- Accessibility options

**Keyboard Shortcuts** (coming soon):
- `Cmd/Ctrl + N`: New task
- `Cmd/Ctrl + K`: Command palette
- `/`: Focus search
- `Esc`: Close dialogs

**Notifications** (coming soon):
- Task reminders
- Event notifications
- Sync status
- AI chat mentions

---

## iOS App

### Installation

**Beta Testing (TestFlight)**:
1. Install TestFlight from App Store
2. Check email for invitation
3. Tap "View in TestFlight"
4. Install Halext Org
5. Open app and login

**First Launch**:
- App syncs your data from web
- May take a few seconds
- All your tasks, events, and pages appear
- Changes sync automatically

### Core Features

**Dashboard**:
- Same customizable layout as web
- Swipe between pages
- Tap widgets to expand
- Pull to refresh

**Tasks**:
- **Create**: Tap + button
- **Complete**: Swipe right or tap checkbox
- **Edit**: Tap task
- **Delete**: Swipe left
- **Filter**: Use search and label filters

**Calendar**:
- Native iOS calendar integration
- Swipe between months
- Tap date to add event
- Event details slide up

**AI Chat**:
- Full-screen chat interface
- Voice input (Siri integration)
- Share to chat from other apps
- Streaming responses

**Offline Mode**:
- Works without internet
- Changes saved locally
- Syncs when online
- Queue shows pending sync items

### Sync

**How Sync Works**:
1. **Automatic**: Every 5 minutes when app is open
2. **Pull-to-Refresh**: Manually sync anytime
3. **Background**: Updates when app reopens
4. **Conflict Resolution**: Server wins for conflicts

**Sync Indicator**:
- 🔄 Syncing...
- ✓ Synced (timestamp)
- ⚠️ Sync pending
- ❌ Sync error (tap to retry)

**Managing Sync**:
- Settings > Sync
- View sync status
- Manual sync button
- Clear local cache
- Re-sync all data

**Offline Support**:
- All data cached locally
- Create/edit offline
- Changes queued for upload
- Automatic sync when online

---

## Tips & Tricks

### Productivity Workflows

**Morning Routine**:
1. Check today's events in calendar
2. Review tasks due today
3. Ask AI to prioritize tasks
4. Schedule focused work time
5. Set reminders for important items

**Weekly Planning**:
1. Create "Weekly Plan" page
2. Add tasks widget filtered by week
3. Add calendar widget for next 7 days
4. Use AI to analyze workload
5. Adjust priorities and due dates

**Project Management**:
1. Create page per project
2. Add column for each project phase
3. Use labels to categorize tasks
4. Track time estimates vs actuals
5. AI helps break down large tasks

**Collaboration**:
1. Share pages with team/partner
2. Assign tasks with labels
3. Comment in task descriptions
4. Track shared gift lists
5. Sync calendars for coordination

### Power User Features

**Markdown in Notes**:
```markdown
# Heading 1
## Heading 2

**Bold text**
*Italic text*

- Bullet point
1. Numbered list

[Link](https://example.com)
`code`
```

**Quick Task Entry**:
- Type task title
- Press Tab → add description
- Press Tab → set due date
- Press Enter → create task

**Label Organization**:
- Use consistent naming: `work-project-name`
- Color code by category
- Limit to 5-7 core labels
- Archive completed labels

**AI Prompt Templates**:
- "Break down [task] into steps"
- "Estimate time for [task]"
- "What's urgent vs important?"
- "Prepare for [event]"
- "Summarize [notes]"

### Best Practices

**Task Management**:
- ✅ Keep titles concise and actionable
- ✅ Add context in descriptions
- ✅ Set realistic due dates
- ✅ Review and update regularly
- ❌ Don't create too many tasks
- ❌ Don't over-categorize with labels

**Calendar Usage**:
- ✅ Block focus time
- ✅ Add location for in-person events
- ✅ Set reminders (15 min, 1 hour before)
- ✅ Use recurring events for routines
- ❌ Don't overschedule
- ❌ Don't forget buffer time

**Dashboard Organization**:
- ✅ Keep most-used widgets visible
- ✅ Group related widgets in columns
- ✅ Create pages for different contexts
- ✅ Clean up widgets you don't use
- ❌ Don't create too many pages
- ❌ Don't add duplicate widgets

**AI Usage**:
- ✅ Be specific in prompts
- ✅ Provide context
- ✅ Iterate on responses
- ✅ Verify AI suggestions
- ❌ Don't blindly trust output
- ❌ Don't share sensitive info

---

## Troubleshooting

### Common Issues

**Can't Login**:
- ✓ Check username/password spelling
- ✓ Verify internet connection
- ✓ Clear browser cache
- ✓ Try different browser
- ✓ Reset password if forgotten

**Tasks Not Appearing**:
- ✓ Check filter settings
- ✓ Verify you're on correct page
- ✓ Refresh page
- ✓ Check if task is completed
- ✓ Look in different widgets

**Widgets Not Loading**:
- ✓ Refresh page (Cmd/Ctrl + R)
- ✓ Check internet connection
- ✓ Clear browser cache
- ✓ Try incognito/private mode
- ✓ Check browser console for errors

**AI Chat Not Responding**:
- ✓ Verify backend is running
- ✓ Check AI provider configuration
- ✓ Look for error messages
- ✓ Try simpler prompt
- ✓ Refresh page and retry

**Sync Issues (iOS)**:
- ✓ Check internet connection
- ✓ Force close and reopen app
- ✓ Pull to refresh
- ✓ Check sync status in settings
- ✓ Re-login if needed

**OpenWebUI Not Loading**:
- ✓ Verify OpenWebUI is running
- ✓ Check configuration in backend .env
- ✓ Try opening in new tab
- ✓ Check network connection
- ✓ Restart backend server

### Performance Issues

**Slow Loading**:
- Clear browser cache
- Close unused tabs
- Disable browser extensions
- Check CPU/memory usage
- Reduce number of widgets

**High Memory Usage**:
- Close unnecessary apps
- Restart browser
- Limit open pages
- Remove unused widgets
- Clear old data

**iOS App Lag**:
- Force close app
- Restart iPhone
- Clear app cache (Settings > Halext Org)
- Offload and reinstall app
- Update to latest version

### Getting Help

**Resources**:
- 📚 User Guide: This document
- 💻 GitHub: https://github.com/scawful/halext-org
- 🐛 Report Issues: GitHub Issues
- 📧 Email: support@halext.org (if available)

**Before Reporting Bugs**:
1. Check this guide
2. Search existing issues
3. Try basic troubleshooting
4. Note what you were doing
5. Include error messages
6. Specify browser/iOS version

**Bug Report Template**:
```
**Description**: Brief summary

**Steps to Reproduce**:
1. Go to...
2. Click on...
3. See error

**Expected**: What should happen
**Actual**: What actually happened
**Screenshots**: Attach if helpful
**Environment**:
- Platform: Web/iOS
- Browser/iOS version:
- Account type: Dev/Production
```

---

## Keyboard Shortcuts (Web)

### Coming Soon

These shortcuts are planned for future releases:

**Global**:
- `Cmd/Ctrl + K`: Command palette
- `Cmd/Ctrl + /`: Toggle help
- `/`: Focus search
- `Esc`: Close dialogs

**Navigation**:
- `G then D`: Go to Dashboard
- `G then T`: Go to Tasks
- `G then C`: Go to Calendar
- `G then A`: Go to AI Chat

**Tasks**:
- `N`: New task
- `E`: Edit selected task
- `Space`: Toggle complete
- `Delete`: Delete task
- `L`: Add label

**Quick Actions**:
- `Cmd/Ctrl + Enter`: Submit form
- `Cmd/Ctrl + S`: Save (auto-saves)
- `Cmd/Ctrl + Z`: Undo
- `Cmd/Ctrl + Shift + Z`: Redo

---

## FAQ

**Q: Is my data private?**
A: Yes! Your data is encrypted in transit (HTTPS) and at rest. Only you and people you explicitly share with can see your data.

**Q: Can I use offline?**
A: Web app requires internet. iOS app works offline with sync when online.

**Q: How much does it cost?**
A: Currently free during beta. Future pricing TBD.

**Q: Can I export my data?**
A: Export feature coming soon. Your data is always accessible via API.

**Q: How do I delete my account?**
A: Contact support or use Settings > Account > Delete Account (coming soon).

**Q: Is there a desktop app?**
A: Web app works on desktop. Native macOS app planned for future.

**Q: Can I use my own AI model?**
A: Yes! Configure Ollama or OpenWebUI in backend settings.

**Q: How many tasks/events can I create?**
A: No limit during beta. Reasonable limits may apply in future.

**Q: Can I collaborate with others?**
A: Yes! Share pages and assign tasks (more collaboration features coming).

**Q: Is there an Android app?**
A: Not yet, but planned for future if there's demand.

---

## What's New

### Latest Updates

**v0.3.0 - AI Integration** (Current):
- ✨ AI-powered chat assistant
- 🤖 Task suggestions and breakdown
- 📊 Event analysis and conflict detection
- 🔗 OpenWebUI integration
- 🔄 SSO for seamless AI access

**v0.2.0 - Customization**:
- 🎨 Drag-and-drop widgets
- 📱 Responsive design
- 🔧 Customizable layouts
- 🎯 Multi-page support

**v0.1.0 - Initial Release**:
- ✅ Task management
- 📅 Calendar and events
- 📝 Notes and gift lists
- 🔐 Authentication

### Coming Soon

**Next Release (v0.4.0)**:
- 🌙 Dark/light theme toggle
- ⌨️ Keyboard shortcuts
- 🔔 Push notifications
- 📱 iOS app (beta)
- 🎨 Custom themes

**Future Plans**:
- 📊 Analytics and insights
- 🔗 Third-party integrations
- 🤝 Advanced collaboration
- 📱 Android app
- 💻 Desktop apps (Mac/Windows)

---

## Support & Feedback

We love hearing from you!

**Feedback**:
- Feature requests welcome
- UI/UX suggestions appreciated
- Bug reports help us improve

**Contributing**:
- Code contributions via GitHub
- Documentation improvements
- Translation help
- Beta testing

**Stay Updated**:
- GitHub releases
- Email newsletters (opt-in)
- In-app notifications

---

*Last updated: November 2025*
*Version: 0.3.0*
