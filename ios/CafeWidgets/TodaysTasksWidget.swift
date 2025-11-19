//
//  TodaysTasksWidget.swift
//  CafeWidgets
//
//  Home screen widget showing today's tasks
//

import WidgetKit
import SwiftUI

struct TodaysTasksWidget: Widget {
    let kind: String = "TodaysTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaysTasksProvider()) { entry in
            TodaysTasksWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Tasks")
        .description("See your tasks for today at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct TodaysTasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            tasks: [
                WidgetTask(id: 1, title: "Example Task", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: []),
                WidgetTask(id: 2, title: "Another Task", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: [])
            ],
            events: [],
            lastUpdate: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let tasks = WidgetDataProvider.shared.todaysTasks
        let entry = WidgetEntry(
            date: Date(),
            tasks: tasks,
            events: [],
            lastUpdate: WidgetDataProvider.shared.loadLastUpdate()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let tasks = WidgetDataProvider.shared.todaysTasks
        let currentDate = Date()

        let entry = WidgetEntry(
            date: currentDate,
            tasks: tasks,
            events: [],
            lastUpdate: WidgetDataProvider.shared.loadLastUpdate()
        )

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}

// MARK: - Widget Views

struct TodaysTasksWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallTasksWidgetView(entry: entry)
        case .systemMedium:
            MediumTasksWidgetView(entry: entry)
        case .systemLarge:
            LargeTasksWidgetView(entry: entry)
        default:
            SmallTasksWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (2x2)

struct SmallTasksWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Today")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            // Task count
            if entry.tasks.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("All Done!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.tasks.count)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.blue)

                    Text(entry.tasks.count == 1 ? "task" : "tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Last update
            if let lastUpdate = entry.lastUpdate {
                Text("Updated \(lastUpdate, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget (4x2)

struct MediumTasksWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(entry.tasks.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if entry.tasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("All tasks completed!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.tasks.prefix(3)) { task in
                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundColor(.blue)

                            Text(task.title)
                                .font(.subheadline)
                                .lineLimit(1)

                            Spacer()

                            if let dueDate = task.dueDate {
                                Text(dueDate, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if entry.tasks.count > 3 {
                        Text("+\(entry.tasks.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Large Widget (4x4)

struct LargeTasksWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Tasks")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let lastUpdate = entry.lastUpdate {
                        Text("Updated \(lastUpdate, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Count badge
                Text("\(entry.tasks.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.blue)
                    )
            }

            Divider()

            if entry.tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text("All tasks completed!")
                        .font(.headline)

                    Text("Great job! You've completed all your tasks for today.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(entry.tasks.prefix(8)) { task in
                            TaskRowView(task: task)
                        }

                        if entry.tasks.count > 8 {
                            HStack {
                                Spacer()
                                Text("And \(entry.tasks.count - 8) more tasks...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct TaskRowView: View {
    let task: WidgetTask

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle")
                .font(.caption)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if !task.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.labels.prefix(2), id: \.id) { label in
                            Text(label.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.2))
                                )
                        }
                    }
                }
            }

            Spacer()

            if let dueDate = task.dueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .fontWeight(.medium)

                    Text(dueDate < Date() ? "Overdue" : "Due")
                        .font(.caption2)
                        .foregroundColor(dueDate < Date() ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    TodaysTasksWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: 1, title: "Morning workout", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: []),
            WidgetTask(id: 2, title: "Team meeting", description: nil, completed: false, dueDate: Date().addingTimeInterval(3600), createdAt: Date(), labels: []),
            WidgetTask(id: 3, title: "Code review", description: nil, completed: false, dueDate: Date().addingTimeInterval(7200), createdAt: Date(), labels: [])
        ],
        events: [],
        lastUpdate: Date()
    )
}

#Preview(as: .systemMedium) {
    TodaysTasksWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: 1, title: "Morning workout", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: []),
            WidgetTask(id: 2, title: "Team meeting", description: nil, completed: false, dueDate: Date().addingTimeInterval(3600), createdAt: Date(), labels: [])
        ],
        events: [],
        lastUpdate: Date()
    )
}
