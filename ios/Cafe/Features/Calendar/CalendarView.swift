//
//  CalendarView.swift
//  Cafe
//
//  Calendar interface with month view and event list
//

import SwiftUI

struct CalendarView: View {
    @State private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar month view
                    MonthCalendarView(
                        selectedDate: $viewModel.selectedDate,
                        datesWithEvents: viewModel.datesWithEvents(in: viewModel.selectedDate)
                    )
                    .padding(.horizontal)

                    Divider()

                    // Events for selected date
                    if !viewModel.selectedDateEvents.isEmpty {
                        EventListSection(
                            title: "Events on \(viewModel.selectedDate.formatted(.dateTime.month().day()))",
                            events: viewModel.selectedDateEvents
                        )
                        .padding(.horizontal)
                    } else {
                        EmptyEventsView(date: viewModel.selectedDate)
                            .padding()
                    }

                    // Upcoming events
                    if !viewModel.upcomingEvents.isEmpty {
                        EventListSection(
                            title: "Upcoming Events",
                            events: Array(viewModel.upcomingEvents.prefix(5))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showingNewEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.selectedDate = Date()
                    } label: {
                        Text("Today")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingNewEvent) {
                NewEventView(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.loadEvents()
            }
            .task {
                await viewModel.loadEvents()
            }
            .overlay {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - Month Calendar View

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let datesWithEvents: Set<DateComponents>
    @State private var currentMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(currentMonth, format: .dateTime.year().month(.wide))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEvents: hasEvents(on: date)
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }

    private var weekdaySymbols: [String] {
        calendar.veryShortWeekdaySymbols
    }

    private var daysInMonth: [Date?] {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)),
              let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func hasEvents(on date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return datesWithEvents.contains(components)
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))

            if hasEvents {
                Circle()
                    .fill(isSelected ? Color.white : Color.blue)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
        )
    }
}

// MARK: - Event List Section

struct EventListSection: View {
    let title: String
    let events: [Event]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(events) { event in
                    EventCard(event: event)
                }
            }
        }
    }
}

struct EventCard: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 4) {
                Text(event.startTime, format: .dateTime.hour().minute())
                    .font(.caption)
                    .fontWeight(.semibold)

                Text(event.endTime, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)

            Rectangle()
                .fill(Color.purple)
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let description = event.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                if event.recurrenceType != "none" {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption2)
                        Text(event.recurrenceType.capitalized)
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Empty Events View

struct EmptyEventsView: View {
    let date: Date

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("No events")
                .font(.headline)

            Text("Create an event for this day")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
}
