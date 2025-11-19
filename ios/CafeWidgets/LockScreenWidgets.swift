//
//  LockScreenWidgets.swift
//  CafeWidgets
//
//  Lock screen and StandBy mode widgets (iOS 16+)
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Widget Bundle

struct CafeLockScreenWidgets: WidgetBundle {
    var body: some Widget {
        TaskCountWidget()
        NextEventWidget()
        CompletedTodayWidget()
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
        WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())
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

            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))

                Text("\(entry.tasks.count)")
                    .font(.system(size: 24, weight: .bold))

                Text("tasks")
                    .font(.system(size: 10))
                    .textCase(.uppercase)
            }
        }
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
            events: [WidgetEvent(id: 1, title: "Team Meeting", startTime: Date(), endTime: Date(), location: "Office")],
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("NEXT EVENT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                }
                .foregroundColor(.secondary)

                Text(event.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(event.startTime, style: .time)
                            .font(.caption)
                    }

                    if let location = event.location {
                        HStack(spacing: 2) {
                            Image(systemName: "location")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                .foregroundColor(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text("CALENDAR")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                }

                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
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
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct CompletedTodayWidgetView: View {
    var entry: WidgetEntry

    var completedCount: Int {
        WidgetDataProvider.shared.completedTodayCount
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
            Text("\(completedCount) completed today")
        }
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
}

#Preview("Next Event", as: .accessoryRectangular) {
    NextEventWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: [],
        events: [WidgetEvent(id: 1, title: "Team Standup", startTime: Date(), endTime: Date(), location: "Zoom")],
        lastUpdate: Date()
    )
}

#Preview("Completed Today", as: .accessoryInline) {
    CompletedTodayWidget()
} timeline: {
    WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())
}
