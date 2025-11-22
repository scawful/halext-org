//
//  CalendarWidget.swift
//  CafeWidgets
//
//  Calendar widget showing upcoming events with refined visual design
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
                WidgetEvent(id: 2, title: "Lunch with Alex", startTime: Date().addingTimeInterval(7200), endTime: Date().addingTimeInterval(10800), location: nil)
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            WidgetHeader(
                icon: "calendar",
                title: "Calendar",
                iconColor: WidgetColors.eventColor
            )

            Spacer(minLength: 10)

            if let event = nextEvent {
                // Next Event Content
                VStack(alignment: .leading, spacing: 8) {
                    // Time until event
                    Text(timeUntilEvent(event.startTime))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WidgetColors.eventColor)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    // Event title
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    // Event details
                    VStack(alignment: .leading, spacing: 4) {
                        TimeBadge(date: event.startTime)

                        if let location = event.location {
                            LocationBadge(location: location)
                        }
                    }
                }
            } else {
                // Empty State
                WidgetEmptyState(
                    icon: "calendar.badge.checkmark",
                    message: "No Events",
                    iconColor: WidgetColors.eventColor,
                    isCompact: true
                )
            }

            Spacer(minLength: 6)
        }
        .padding(14)
    }

    private func timeUntilEvent(_ date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)

        if interval < 0 {
            return "Now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "In \(minutes) min"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "In \(hours) hr"
        } else {
            let days = Int(interval / 86400)
            return "In \(days) day\(days == 1 ? "" : "s")"
        }
    }
}

// MARK: - Medium Calendar Widget

struct MediumCalendarView: View {
    let entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            WidgetHeader(
                icon: "calendar",
                title: "Upcoming Events",
                iconColor: WidgetColors.eventColor,
                count: entry.events.isEmpty ? nil : entry.events.count
            )

            if entry.events.isEmpty {
                WidgetEmptyState(
                    icon: "calendar.badge.checkmark",
                    message: "No Upcoming Events",
                    iconColor: WidgetColors.eventColor,
                    detailMessage: "Enjoy your free time"
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.events.prefix(3)) { event in
                        EnhancedEventRowView(event: event)
                    }

                    if entry.events.count > 3 {
                        HStack {
                            Spacer()
                            Text("+\(entry.events.count - 3) more")
                                .font(.system(size: 12, weight: .medium))
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

// MARK: - Enhanced Event Row

struct EnhancedEventRowView: View {
    let event: WidgetEvent

    var isToday: Bool {
        Calendar.current.isDateInToday(event.startTime)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Date badge
            WidgetDateBadge(
                date: event.startTime,
                accentColor: WidgetColors.eventColor,
                isCompact: true
            )

            // Event details
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    TimeBadge(date: event.startTime)

                    if let location = event.location {
                        LocationBadge(location: location)
                    }
                }
            }

            Spacer(minLength: 0)

            // Today indicator
            if isToday {
                Text("Today")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(WidgetColors.eventColor.gradient)
                    )
            }
        }
        .padding(.vertical, 2)
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
            WidgetEvent(id: 1, title: "Team Standup", startTime: Date().addingTimeInterval(1800), endTime: Date().addingTimeInterval(3600), location: "Zoom"),
            WidgetEvent(id: 2, title: "Lunch Meeting", startTime: Date().addingTimeInterval(7200), endTime: Date().addingTimeInterval(10800), location: "Cafe")
        ],
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
    CalendarWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        tasks: [],
        events: [
            WidgetEvent(id: 1, title: "Team Standup", startTime: Date(), endTime: Date().addingTimeInterval(1800), location: "Zoom"),
            WidgetEvent(id: 2, title: "Design Review", startTime: Date().addingTimeInterval(7200), endTime: Date().addingTimeInterval(10800), location: "Conference Room"),
            WidgetEvent(id: 3, title: "Client Call", startTime: Date().addingTimeInterval(14400), endTime: Date().addingTimeInterval(18000), location: nil)
        ],
        lastUpdate: Date()
    )
    WidgetEntry(
        date: Date(),
        tasks: [],
        events: [],
        lastUpdate: Date()
    )
}
