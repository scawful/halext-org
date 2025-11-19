//
//  QuickAddWidget.swift
//  CafeWidgets
//
//  Interactive widget for quick task creation (iOS 17+)
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
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Quick Add")
                .font(.headline)
                .fontWeight(.bold)

            Text("Tap to create")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "cafe://new-task"))
    }
}

// MARK: - Medium Quick Add (Interactive Buttons)

struct MediumQuickAddView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                Text("Quick Add")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(intent: QuickAddTaskIntent()) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)

                        Text("Task")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)

                Button(intent: QuickAddEventIntent()) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundColor(.purple)

                        Text("Event")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)

                Link(destination: URL(string: "cafe://chat")!) {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.orange)

                        Text("AI Chat")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
        }
        .padding()
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
