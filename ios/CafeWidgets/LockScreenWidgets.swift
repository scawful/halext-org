//
//  LockScreenWidgets.swift
//  CafeWidgets
//
//  Lock screen and StandBy mode widgets with refined visual design (iOS 16+)
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget Bundle

struct CafeLockScreenWidgets: WidgetBundle {
    var body: some Widget {
        TaskCountWidget()
        NextEventWidget()
        CompletedTodayWidget()
        TaskProgressWidget()
    }
}

// MARK: - Task Count Widget (Circular)

struct TaskCountWidget: Widget {
    let kind: String = "TaskCountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskCountProvider()) { entry in
            TaskCountWidgetView(entry: entry)
        }
        .configurationDisplayName("Task Count")
        .description("Number of tasks due today")
        .supportedFamilies([.accessoryCircular])
    }
}

struct TaskCountProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            tasks: Array(repeating: WidgetTask(id: 0, title: "Task", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: []), count: 3),
            events: [],
            lastUpdate: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let tasks = WidgetDataProvider.shared.todaysTasks
        let entry = WidgetEntry(date: Date(), tasks: tasks, events: [], lastUpdate: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let tasks = WidgetDataProvider.shared.todaysTasks
        let entry = WidgetEntry(date: Date(), tasks: tasks, events: [], lastUpdate: Date())

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TaskCountWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            if entry.tasks.isEmpty {
                // All done state
                VStack(spacing: 1) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .medium))

                    Text("Done")
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)
                }
            } else {
                // Task count state
                VStack(spacing: 0) {
                    Image(systemName: "checklist")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.bottom, 1)

                    Text("\(entry.tasks.count)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text(entry.tasks.count == 1 ? "task" : "tasks")
                        .font(.system(size: 8, weight: .medium))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .widgetAccentable()
    }
}

// MARK: - Task Progress Widget (Circular with Gauge)

struct TaskProgressWidget: Widget {
    let kind: String = "TaskProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProgressProvider()) { entry in
            TaskProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Task Progress")
        .description("Your daily task completion progress")
        .supportedFamilies([.accessoryCircular])
    }
}

struct TaskProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskProgressEntry {
        TaskProgressEntry(date: Date(), completedCount: 3, totalCount: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskProgressEntry) -> ()) {
        let completedCount = WidgetDataProvider.shared.completedTodayCount
        let pendingCount = WidgetDataProvider.shared.todaysTasks.count
        let entry = TaskProgressEntry(
            date: Date(),
            completedCount: completedCount,
            totalCount: completedCount + pendingCount
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskProgressEntry>) -> ()) {
        let completedCount = WidgetDataProvider.shared.completedTodayCount
        let pendingCount = WidgetDataProvider.shared.todaysTasks.count
        let entry = TaskProgressEntry(
            date: Date(),
            completedCount: completedCount,
            totalCount: completedCount + pendingCount
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TaskProgressEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int

    var progress: Double {
        guard totalCount > 0 else { return 1.0 }
        return Double(completedCount) / Double(totalCount)
    }
}

struct TaskProgressWidgetView: View {
    var entry: TaskProgressEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "checkmark.circle.fill")
        } currentValueLabel: {
            VStack(spacing: 0) {
                Text("\(entry.completedCount)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("/\(entry.totalCount)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }
}

// MARK: - Next Event Widget (Rectangular)

struct NextEventWidget: Widget {
    let kind: String = "NextEventWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextEventProvider()) { entry in
            NextEventWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Event")
        .description("Your upcoming event")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct NextEventProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            tasks: [],
            events: [WidgetEvent(id: 1, title: "Team Meeting", startTime: Date().addingTimeInterval(1800), endTime: Date().addingTimeInterval(5400), location: "Conference Room")],
            lastUpdate: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let events = WidgetDataProvider.shared.upcomingEvents
        let entry = WidgetEntry(date: Date(), tasks: [], events: events, lastUpdate: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let events = WidgetDataProvider.shared.upcomingEvents
        let entry = WidgetEntry(date: Date(), tasks: [], events: events, lastUpdate: Date())

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct NextEventWidgetView: View {
    var entry: WidgetEntry

    var nextEvent: WidgetEvent? {
        entry.events.first
    }

    var body: some View {
        if let event = nextEvent {
            VStack(alignment: .leading, spacing: 3) {
                // Header row with icon and time indicator
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .semibold))

                    Text(timeUntilEvent(event.startTime))
                        .font(.system(size: 10, weight: .semibold))
                        .textCase(.uppercase)

                    Spacer()
                }
                .foregroundStyle(.secondary)

                // Event title
                Text(event.title)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)

                // Event details row
                HStack(spacing: 6) {
                    // Time
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 9, weight: .medium))
                        Text(event.startTime, style: .time)
                            .font(.system(size: 11, weight: .medium))
                    }

                    // Location (if available)
                    if let location = event.location {
                        HStack(spacing: 2) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 8, weight: .medium))
                            Text(location)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                        }
                    }
                }
                .foregroundStyle(.secondary)
            }
            .widgetAccentable()
        } else {
            // Empty state
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 12, weight: .semibold))

                    Text("CALENDAR")
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase)
                }

                Text("No upcoming events")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Enjoy your free time")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
            .widgetAccentable()
        }
    }

    private func timeUntilEvent(_ date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)

        if interval < 0 {
            return "Now"
        } else if interval < 60 {
            return "In < 1 min"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "In \(minutes) min"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "In \(hours) hr"
        } else {
            let days = Int(interval / 86400)
            return "In \(days)d"
        }
    }
}

// MARK: - Completed Today Widget (Inline)

struct CompletedTodayWidget: Widget {
    let kind: String = "CompletedTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CompletedTodayProvider()) { entry in
            CompletedTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Completed Today")
        .description("Tasks you've completed today")
        .supportedFamilies([.accessoryInline])
    }
}

struct CompletedTodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompletedEntry {
        CompletedEntry(date: Date(), completedCount: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (CompletedEntry) -> ()) {
        let count = WidgetDataProvider.shared.completedTodayCount
        let entry = CompletedEntry(date: Date(), completedCount: count)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CompletedEntry>) -> ()) {
        let count = WidgetDataProvider.shared.completedTodayCount
        let entry = CompletedEntry(date: Date(), completedCount: count)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CompletedEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
}

struct CompletedTodayWidgetView: View {
    var entry: CompletedEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .medium))

            if entry.completedCount == 0 {
                Text("No tasks completed yet")
            } else {
                Text("\(entry.completedCount) completed today")
            }
        }
        .widgetAccentable()
    }
}

// MARK: - Previews

#Preview("Task Count", as: .accessoryCircular) {
    TaskCountWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: Array(repeating: WidgetTask(id: 1, title: "Task", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: []), count: 5),
        events: [],
        lastUpdate: Date()
    )
    WidgetEntry(
        date: Date(),
        tasks: [],
        events: [],
        lastUpdate: Date()
    )
}

#Preview("Task Progress", as: .accessoryCircular) {
    TaskProgressWidget()
} timeline: {
    TaskProgressEntry(date: Date(), completedCount: 3, totalCount: 5)
    TaskProgressEntry(date: Date(), completedCount: 5, totalCount: 5)
    TaskProgressEntry(date: Date(), completedCount: 0, totalCount: 0)
}

#Preview("Next Event", as: .accessoryRectangular) {
    NextEventWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: [],
        events: [WidgetEvent(id: 1, title: "Team Standup", startTime: Date().addingTimeInterval(1800), endTime: Date().addingTimeInterval(3600), location: "Zoom")],
        lastUpdate: Date()
    )
    WidgetEntry(
        date: Date(),
        tasks: [],
        events: [],
        lastUpdate: Date()
    )
}

#Preview("Completed Today", as: .accessoryInline) {
    CompletedTodayWidget()
} timeline: {
    CompletedEntry(date: Date(), completedCount: 7)
    CompletedEntry(date: Date(), completedCount: 0)
}
