//
//  QuickAddWidget.swift
//  CafeWidgets
//
//  Interactive widget for quick task creation with refined visual design (iOS 17+)
//

import WidgetKit
import SwiftUI
import AppIntents

struct QuickAddWidget: Widget {
    let kind: String = "QuickAddWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAddProvider()) { entry in
            QuickAddWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Add")
        .description("Quickly create tasks and events")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider

struct QuickAddProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(
            date: Date(),
            tasks: [],
            events: [],
            lastUpdate: Date()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = WidgetEntry(
            date: Date(),
            tasks: [],
            events: [],
            lastUpdate: Date()
        )

        // Static widget - update once per day
        let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}

// MARK: - Widget View

struct QuickAddWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallQuickAddView()
        case .systemMedium:
            MediumQuickAddView()
        default:
            SmallQuickAddView()
        }
    }
}

// MARK: - Small Quick Add

struct SmallQuickAddView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main action icon with gradient ring
            ZStack {
                // Outer gradient ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .blue],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 64, height: 64)

                // Inner background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.15),
                                Color.purple.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Spacer(minLength: 12)

            // Title
            Text("Quick Add")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)

            // Subtitle
            Text("Tap to create")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "cafe://new-task"))
    }
}

// MARK: - Medium Quick Add (Interactive Buttons)

struct MediumQuickAddView: View {
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Quick Add")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                // Hint text
                Text("Tap an action")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            // Action buttons grid
            HStack(spacing: 10) {
                // Task Button
                Button(intent: QuickAddTaskIntent()) {
                    QuickAddActionButton(
                        icon: "checkmark.circle.fill",
                        label: "Task",
                        color: WidgetColors.taskColor
                    )
                }
                .buttonStyle(.plain)

                // Event Button
                Button(intent: QuickAddEventIntent()) {
                    QuickAddActionButton(
                        icon: "calendar.badge.plus",
                        label: "Event",
                        color: WidgetColors.eventColor
                    )
                }
                .buttonStyle(.plain)

                // AI Chat Link
                Link(destination: URL(string: "cafe://chat")!) {
                    QuickAddActionButton(
                        icon: "sparkles",
                        label: "AI Chat",
                        color: WidgetColors.aiColor
                    )
                }
            }
        }
        .padding(14)
    }
}

// MARK: - Quick Add Action Button

struct QuickAddActionButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            // Icon container
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }

            // Label
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - App Intents (iOS 17+)

struct QuickAddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Quickly add a new task")

    func perform() async throws -> some IntentResult & OpensIntent {
        return .result(opensIntent: CreateTaskIntent())
    }
}

struct QuickAddEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Event"
    static var description = IntentDescription("Quickly add a new event")

    func perform() async throws -> some IntentResult & OpensIntent {
        return .result(opensIntent: CreateEventIntent())
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    QuickAddWidget()
} timeline: {
    WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())
}

#Preview(as: .systemMedium) {
    QuickAddWidget()
} timeline: {
    WidgetEntry(date: Date(), tasks: [], events: [], lastUpdate: Date())
}
