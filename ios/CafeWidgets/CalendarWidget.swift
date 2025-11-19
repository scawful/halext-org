//
//  CalendarWidget.swift
//  CafeWidgets
//
//  Calendar widget showing upcoming events
//

import WidgetKit
import SwiftUI

struct CalendarWidget: Widget {
    let kind: String = "CalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calendar")
        .description("See your upcoming events")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider

struct CalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            tasks: [],
            events: [
                WidgetEvent(id: 1, title: "Team Meeting", startTime: Date(), endTime: Date().addingTimeInterval(3600), location: "Office"),
                WidgetEvent(id: 2, title: "Lunch", startTime: Date().addingTimeInterval(7200), endTime: Date().addingTimeInterval(10800), location: nil)
            ],
            lastUpdate: Date()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let events = WidgetDataProvider.shared.upcomingEvents
        let entry = WidgetEntry(
            date: Date(),
            tasks: [],
            events: events,
            lastUpdate: WidgetDataProvider.shared.loadLastUpdate()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let events = WidgetDataProvider.shared.upcomingEvents
        let currentDate = Date()

        let entry = WidgetEntry(
            date: currentDate,
            tasks: [],
            events: events,
            lastUpdate: WidgetDataProvider.shared.loadLastUpdate()
        )

        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }
}

// MARK: - Widget Views

struct CalendarWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: WidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallCalendarView(entry: entry)
        case .systemMedium:
            MediumCalendarView(entry: entry)
        default:
            SmallCalendarView(entry: entry)
        }
    }
}

// MARK: - Small Calendar Widget

struct SmallCalendarView: View {
    let entry: WidgetEntry

    var nextEvent: WidgetEvent? {
        entry.events.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Calendar")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            if let event = nextEvent {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(event.startTime, style: .time)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    if let location = event.location {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                            Text(location)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundColor(.purple.opacity(0.5))
                    Text("No events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Medium Calendar Widget

struct MediumCalendarView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text("Upcoming Events")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(entry.events.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if entry.events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .foregroundColor(.purple.opacity(0.5))
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.events.prefix(3)) { event in
                        EventRowView(event: event)
                    }

                    if entry.events.count > 3 {
                        Text("+\(entry.events.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
    }
}

struct EventRowView: View {
    let event: WidgetEvent

    var body: some View {
        HStack(spacing: 10) {
            // Date badge
            VStack(spacing: 2) {
                Text(event.startTime, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(event.startTime, format: .dateTime.day())
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(width: 40)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.purple.opacity(0.1))
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.startTime, style: .time)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    CalendarWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: [],
        events: [
            WidgetEvent(id: 1, title: "Team Standup", startTime: Date(), endTime: Date().addingTimeInterval(1800), location: "Zoom"),
            WidgetEvent(id: 2, title: "Lunch Meeting", startTime: Date().addingTimeInterval(7200), endTime: Date().addingTimeInterval(10800), location: "Cafe")
        ],
        lastUpdate: Date()
    )
}
