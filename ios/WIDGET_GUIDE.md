# WidgetKit Implementation Guide

Step-by-step guide to add Home Screen and Lock Screen widgets to the Cafe iOS app.

---

## 📋 Prerequisites

- Xcode 15.0+
- iOS 17.0+ target
- Active Apple Developer account (for testing on device)

---

## 🎯 Widgets to Implement

### 1. **Today's Tasks Widget**
- Shows tasks due today
- Small, Medium, and Large sizes
- Updates every 15 minutes
- Deep link to Tasks tab

### 2. **Calendar Widget**
- Month view with event indicators
- Shows current date prominently
- Medium and Large sizes
- Deep link to Calendar tab

### 3. **Quick Add Widget**
- Button widget for iOS 17+
- Taps open app to New Task
- Small size only
- Instant interaction

### 4. **Lock Screen Widgets** (iOS 16+)
- Circular: Task count
- Rectangular: Next event
- Inline: Tasks remaining

---

## 🛠️ Step 1: Create Widget Extension

### In Xcode:

1. **File → New → Target**
2. Select **Widget Extension**
3. Product Name: `CafeWidgets`
4. Include Configuration Intent: ✅ Yes
5. Click **Finish**
6. **Activate** the scheme when prompted

### File Structure Created:
```
CafeWidgets/
├── CafeWidgets.swift          # Widget bundle
├── TodaysTasksWidget.swift    # (you'll create)
├── CalendarWidget.swift       # (you'll create)
├── Assets.xcassets
└── Info.plist
```

---

## 📝 Step 2: Create Today's Tasks Widget

### File: `CafeWidgets/TodaysTasksWidget.swift`

```swift
import WidgetKit
import SwiftUI

// MARK: - Today's Tasks Widget

struct TodaysTasksWidget: Widget {
    let kind: String = "TodaysTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaysTasksProvider()) { entry in
            TodaysTasksEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Tasks")
        .description("View your tasks for today")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct TodaysTasksProvider: TimelineProvider {
    typealias Entry = TodaysTasksEntry

    func placeholder(in context: Context) -> TodaysTasksEntry {
        TodaysTasksEntry(date: Date(), tasks: [
            SimpleTask(id: 1, title: "Example Task", completed: false, dueDate: Date())
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaysTasksEntry) -> Void) {
        let entry = TodaysTasksEntry(date: Date(), tasks: [])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaysTasksEntry>) -> Void) {
        Task {
            var tasks: [SimpleTask] = []

            // Fetch tasks from API
            do {
                let fetchedTasks = try await APIClient.shared.getTasks()
                let calendar = Calendar.current
                let now = Date()
                let startOfToday = calendar.startOfDay(for: now)
                let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

                tasks = fetchedTasks
                    .filter { !$0.completed && ($0.dueDate ?? now) >= startOfToday && ($0.dueDate ?? now) < endOfToday }
                    .prefix(5)
                    .map { SimpleTask(id: $0.id, title: $0.title, completed: $0.completed, dueDate: $0.dueDate) }
            } catch {
                print("Widget failed to fetch tasks: \(error)")
            }

            let entry = TodaysTasksEntry(date: Date(), tasks: tasks)

            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - Entry

struct TodaysTasksEntry: TimelineEntry {
    let date: Date
    let tasks: [SimpleTask]
}

struct SimpleTask: Identifiable, Codable {
    let id: Int
    let title: String
    let completed: Bool
    let dueDate: Date?
}

// MARK: - Entry View

struct TodaysTasksEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TodaysTasksEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallTasksWidget(tasks: entry.tasks)
        case .systemMedium:
            MediumTasksWidget(tasks: entry.tasks)
        case .systemLarge:
            LargeTasksWidget(tasks: entry.tasks)
        default:
            SmallTasksWidget(tasks: entry.tasks)
        }
    }
}

// MARK: - Small Widget

struct SmallTasksWidget: View {
    let tasks: [SimpleTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Today")
                    .font(.headline)
                Spacer()
            }

            if tasks.isEmpty {
                Spacer()
                Text("No tasks")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                Text("\(tasks.count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)

                Text(tasks.count == 1 ? "task" : "tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget

struct MediumTasksWidget: View {
    let tasks: [SimpleTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            if tasks.isEmpty {
                Text("No tasks for today")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(tasks.prefix(3)) { task in
                    HStack(spacing: 8) {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget

struct LargeTasksWidget: View {
    let tasks: [SimpleTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Today's Tasks")
                    .font(.title2)
                    .bold()
                Spacer()
                Text("\(tasks.count)")
                    .font(.title)
                    .foregroundColor(.blue)
            }

            Divider()

            if tasks.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("All done!")
                        .font(.title3)
                        .bold()
                    Text("No tasks for today")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(tasks) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "circle")
                            .font(.body)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.body)
                                .lineLimit(2)

                            if let dueDate = task.dueDate {
                                Text(dueDate, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TodaysTasksWidget()
} timeline: {
    TodaysTasksEntry(date: .now, tasks: [
        SimpleTask(id: 1, title: "Buy groceries", completed: false, dueDate: Date()),
        SimpleTask(id: 2, title: "Team meeting", completed: false, dueDate: Date())
    ])
}
```

---

## 📅 Step 3: Create Calendar Widget

### File: `CafeWidgets/CalendarWidget.swift`

```swift
import WidgetKit
import SwiftUI

// MARK: - Calendar Widget

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calendar")
        .description("View this month's events")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Provider

struct CalendarProvider: TimelineProvider {
    typealias Entry = CalendarEntry

    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: Date(), events: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarEntry) -> Void) {
        completion(CalendarEntry(date: Date(), events: []))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarEntry>) -> Void) {
        Task {
            var events: [SimpleEvent] = []

            do {
                let fetchedEvents = try await APIClient.shared.getEvents()
                let now = Date()
                let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!

                events = fetchedEvents
                    .filter { $0.startTime >= now && $0.startTime <= weekFromNow }
                    .sorted { $0.startTime < $1.startTime }
                    .prefix(5)
                    .map { SimpleEvent(id: $0.id, title: $0.title, startTime: $0.startTime) }
            } catch {
                print("Widget failed to fetch events: \(error)")
            }

            let entry = CalendarEntry(date: Date(), events: events)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct CalendarEntry: TimelineEntry {
    let date: Date
    let events: [SimpleEvent]
}

struct SimpleEvent: Identifiable, Codable {
    let id: Int
    let title: String
    let startTime: Date
}

// MARK: - Entry View

struct CalendarEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text(entry.date, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
            }

            if entry.events.isEmpty {
                Text("No upcoming events")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(entry.events.prefix(family == .systemMedium ? 2 : 5)) { event in
                    HStack(spacing: 8) {
                        VStack {
                            Text(event.startTime, format: .dateTime.month(.abbreviated))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(event.startTime, format: .dateTime.day())
                                .font(.headline)
                                .bold()
                        }
                        .frame(width: 40)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(event.startTime, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}
```

---

## 🔧 Step 4: Create Widget Bundle

### File: `CafeWidgets/CafeWidgets.swift`

```swift
import WidgetKit
import SwiftUI

@main
struct CafeWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodaysTasksWidget()
        CalendarWidget()
    }
}
```

---

## 🔗 Step 5: Share API Client with Widget

### Update `APIClient.swift` target membership:

1. Select `APIClient.swift` in Project Navigator
2. In File Inspector (right panel)
3. Under **Target Membership**
4. Check ✅ `CafeWidgets` extension

### Do the same for:
- `Models.swift`
- `AiChatMessage.swift`
- `KeychainManager.swift`
- `ColorExtensions.swift`

---

## 🎨 Step 6: Configure App Groups (for data sharing)

### 1. Add App Group Capability:

**Main App Target:**
1. Select Cafe target → Signing & Capabilities
2. Click `+ Capability`
3. Add **App Groups**
4. Click `+` and create: `group.org.halext.cafe`

**Widget Extension Target:**
1. Select CafeWidgets target → Signing & Capabilities
2. Add **App Groups**
3. Select **same group**: `group.org.halext.cafe`

### 2. Update Keychain Manager:

```swift
// In KeychainManager.swift
private let serviceName = "group.org.halext.cafe"
```

---

## 🔍 Step 7: Test Widgets

### In Simulator:

1. Run the **CafeWidgets** scheme
2. Select widget in widget picker
3. Choose size and add to Home Screen

### On Device:

1. Archive and install app
2. Long-press Home Screen
3. Tap `+` → Search "Cafe"
4. Add widgets

---

## 🎯 Step 8: Lock Screen Widgets (iOS 16+)

### Add to `TodaysTasksWidget.swift`:

```swift
.supportedFamilies([
    .systemSmall,
    .systemMedium,
    .systemLarge,
    .accessoryCircular,      // Lock screen circular
    .accessoryRectangular,   // Lock screen rectangular
    .accessoryInline         // Lock screen inline
])
```

### Create Lock Screen Views:

```swift
struct AccessoryCircularView: View {
    let taskCount: Int

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(taskCount)")
                    .font(.title)
                    .bold()
                Text("tasks")
                    .font(.caption2)
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let tasks: [SimpleTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Today's Tasks")
                .font(.headline)
            if let first = tasks.first {
                Text(first.title)
                    .font(.caption)
                    .lineLimit(2)
            } else {
                Text("No tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AccessoryInlineView: View {
    let taskCount: Int

    var body: some View {
        Text("\(taskCount) tasks today")
    }
}
```

### Update Entry View:

```swift
var body: some View {
    switch family {
    case .systemSmall:
        SmallTasksWidget(tasks: entry.tasks)
    case .systemMedium:
        MediumTasksWidget(tasks: entry.tasks)
    case .systemLarge:
        LargeTasksWidget(tasks: entry.tasks)
    case .accessoryCircular:
        AccessoryCircularView(taskCount: entry.tasks.count)
    case .accessoryRectangular:
        AccessoryRectangularView(tasks: entry.tasks)
    case .accessoryInline:
        AccessoryInlineView(taskCount: entry.tasks.count)
    default:
        SmallTasksWidget(tasks: entry.tasks)
    }
}
```

---

## ✅ Checklist

- [ ] Create Widget Extension target
- [ ] Implement Today's Tasks Widget
- [ ] Implement Calendar Widget
- [ ] Create Widget Bundle
- [ ] Share necessary files with widget target
- [ ] Configure App Groups
- [ ] Test on simulator
- [ ] Test on device
- [ ] Add Lock Screen widget support
- [ ] Submit for App Store review

---

## 🐛 Troubleshooting

### Widget not updating?
- Check timeline policy (should refresh every 15-60 min)
- Verify API client is shared with widget target
- Check App Groups configuration

### "Module not found" errors?
- Ensure files are added to widget target membership
- Clean build folder (Cmd+Shift+K)
- Restart Xcode

### Data not shared between app and widget?
- Verify App Group is configured for both targets
- Check that both use same group identifier
- Ensure UserDefaults uses suite name: `UserDefaults(suiteName: "group.org.halext.cafe")`

---

## 📚 Resources

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Human Interface Guidelines - Widgets](https://developer.apple.com/design/human-interface-guidelines/widgets)
- [WWDC Sessions on Widgets](https://developer.apple.com/videos/frameworks/widgetkit)

---

**Note**: Widgets require manual Xcode configuration. This guide provides all the code needed, but you must create the Extension target yourself in Xcode.
