//
//  TodaysTasksWidget.swift
//  CafeWidgets
//
//  Home screen widget showing today's tasks with refined visual design
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
                WidgetTask(id: 1, title: "Morning workout", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: []),
                WidgetTask(id: 2, title: "Review project proposal", description: nil, completed: false, dueDate: Date(), createdAt: Date(), labels: [])
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            WidgetHeader(
                icon: "checkmark.circle.fill",
                title: "Today",
                iconColor: WidgetColors.taskColor
            )

            Spacer(minLength: 8)

            // Content
            if entry.tasks.isEmpty {
                // Success Empty State
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(WidgetColors.successBackground)
                            .frame(width: 50, height: 50)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(WidgetColors.successColor)
                    }

                    Text("All Done!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
            } else {
                // Task Count Display
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.tasks.count)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetColors.taskColor)
                        .minimumScaleFactor(0.6)

                    Text(entry.tasks.count == 1 ? "task remaining" : "tasks remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 6)

            // Last update indicator
            if let lastUpdate = entry.lastUpdate {
                HStack(spacing: 4) {
                    Circle()
                        .fill(WidgetColors.successColor)
                        .frame(width: 5, height: 5)

                    Text("Updated \(lastUpdate, style: .relative)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Medium Widget (4x2)

struct MediumTasksWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            WidgetHeader(
                icon: "checkmark.circle.fill",
                title: "Today's Tasks",
                iconColor: WidgetColors.taskColor,
                count: entry.tasks.isEmpty ? nil : entry.tasks.count
            )

            if entry.tasks.isEmpty {
                // Success Empty State
                WidgetEmptyState(
                    icon: "checkmark.circle.fill",
                    message: "All Tasks Completed!",
                    iconColor: WidgetColors.successColor,
                    detailMessage: "Great job staying on top of things"
                )
            } else {
                // Task List
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.tasks.prefix(3)) { task in
                        EnhancedTaskRowCompact(task: task)
                    }

                    if entry.tasks.count > 3 {
                        HStack {
                            Spacer()
                            Text("+\(entry.tasks.count - 3) more tasks")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Large Widget (4x4)

struct LargeTasksWidgetView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with count badge
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Tasks")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)

                    if let lastUpdate = entry.lastUpdate {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(WidgetColors.successColor)
                                .frame(width: 5, height: 5)

                            Text("Updated \(lastUpdate, style: .relative)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                // Count badge
                CountBadge(count: entry.tasks.count, color: WidgetColors.taskColor)
            }

            Divider()
                .background(Color.secondary.opacity(0.2))

            if entry.tasks.isEmpty {
                // Success Empty State
                WidgetEmptyState(
                    icon: "checkmark.circle.fill",
                    message: "All Tasks Completed!",
                    iconColor: WidgetColors.successColor,
                    detailMessage: "You've finished everything for today. Take a well-deserved break!"
                )
            } else {
                // Task List
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.tasks.prefix(7)) { task in
                        EnhancedTaskRowFull(task: task)
                    }

                    if entry.tasks.count > 7 {
                        HStack {
                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 10))
                                Text("And \(entry.tasks.count - 7) more")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.1))
                            )

                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Enhanced Task Row (Compact)

struct EnhancedTaskRowCompact: View {
    let task: WidgetTask

    var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date()
    }

    var body: some View {
        HStack(spacing: 10) {
            // Task indicator
            TaskIndicator(isCompleted: task.completed)

            // Task title
            Text(task.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOverdue ? WidgetColors.overdueColor : .primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            // Due time
            if let dueDate = task.dueDate {
                TimeBadge(date: dueDate, isOverdue: isOverdue)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Enhanced Task Row (Full)

struct EnhancedTaskRowFull: View {
    let task: WidgetTask

    var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return dueDate < Date()
    }

    var body: some View {
        HStack(spacing: 12) {
            // Task indicator
            TaskIndicator(isCompleted: task.completed)

            // Task details
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isOverdue ? WidgetColors.overdueColor : .primary)
                    .lineLimit(1)

                // Labels
                if !task.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.labels.prefix(2), id: \.id) { label in
                            LabelPill(label: label)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            // Due time with status
            if let dueDate = task.dueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(dueDate, style: .time)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isOverdue ? WidgetColors.overdueColor : .primary)

                    Text(isOverdue ? "Overdue" : "Due")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(isOverdue ? WidgetColors.overdueColor : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Label Pill Component

struct LabelPill: View {
    let label: WidgetLabel

    var labelColor: Color {
        if let colorHex = label.color {
            return Color(hex: colorHex) ?? WidgetColors.taskColor
        }
        return WidgetColors.taskColor
    }

    var body: some View {
        Text(label.name)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(labelColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(labelColor.opacity(0.15))
            )
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        } else if length == 8 {
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
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
    WidgetEntry(
        date: Date(),
        tasks: [],
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
            WidgetTask(id: 1, title: "Morning workout", description: nil, completed: false, dueDate: Date().addingTimeInterval(-1800), createdAt: Date(), labels: []),
            WidgetTask(id: 2, title: "Team meeting", description: nil, completed: false, dueDate: Date().addingTimeInterval(3600), createdAt: Date(), labels: []),
            WidgetTask(id: 3, title: "Review pull request", description: nil, completed: false, dueDate: Date().addingTimeInterval(7200), createdAt: Date(), labels: []),
            WidgetTask(id: 4, title: "Update documentation", description: nil, completed: false, dueDate: Date().addingTimeInterval(10800), createdAt: Date(), labels: [])
        ],
        events: [],
        lastUpdate: Date()
    )
}

#Preview(as: .systemLarge) {
    TodaysTasksWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: 1, title: "Morning workout", description: nil, completed: false, dueDate: Date().addingTimeInterval(-1800), createdAt: Date(), labels: [WidgetLabel(id: 1, name: "Health", color: "#34C759")]),
            WidgetTask(id: 2, title: "Team standup", description: nil, completed: false, dueDate: Date().addingTimeInterval(1800), createdAt: Date(), labels: [WidgetLabel(id: 2, name: "Work", color: "#007AFF")]),
            WidgetTask(id: 3, title: "Review pull request", description: nil, completed: false, dueDate: Date().addingTimeInterval(3600), createdAt: Date(), labels: []),
            WidgetTask(id: 4, title: "Design review meeting", description: nil, completed: false, dueDate: Date().addingTimeInterval(7200), createdAt: Date(), labels: [WidgetLabel(id: 2, name: "Work", color: "#007AFF")]),
            WidgetTask(id: 5, title: "Update documentation", description: nil, completed: false, dueDate: Date().addingTimeInterval(10800), createdAt: Date(), labels: [])
        ],
        events: [],
        lastUpdate: Date()
    )
}
