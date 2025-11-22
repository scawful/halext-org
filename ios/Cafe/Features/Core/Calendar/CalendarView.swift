//
//  CalendarView.swift
//  Cafe
//
//  Calendar interface with month view and event list
//

import SwiftUI

struct CalendarView: View {
    @Environment(ThemeManager.self) var themeManager
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
                            events: viewModel.selectedDateEvents,
                            sharedEvents: viewModel.sharedEvents(for: viewModel.selectedDate)
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
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.selection()
                        viewModel.showingNewEvent = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectedDate = Date()
                        }
                    } label: {
                        Text("Today")
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.accentColor)
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
    @Environment(ThemeManager.self) var themeManager
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
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.accentColor)
                }

                Spacer()

                Text(currentMonth, format: .dateTime.year().month(.wide))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)

                Spacer()

                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.accentColor)
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
                            HapticManager.selection()
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
        .themedCardBackground(cornerRadius: 16, shadow: true)
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
    @Environment(ThemeManager.self) var themeManager
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : (isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? themeManager.accentColor : themeManager.textColor))

            if hasEvents {
                Circle()
                    .fill(isSelected ? Color.white : themeManager.accentColor)
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: themeManager.accentColor.opacity(0.3), radius: 4, y: 2)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themeManager.accentColor.opacity(0.15))
                } else {
                    Color.clear
                }
            }
        )
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Event List Section

struct EventListSection: View {
    let title: String
    let events: [Event]
    let sharedEvents: [Event]?
    
    init(title: String, events: [Event], sharedEvents: [Event]? = nil) {
        self.title = title
        self.events = events
        self.sharedEvents = sharedEvents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(events) { event in
                    let isShared = sharedEvents?.contains(where: { $0.id == event.id }) ?? false
                    EventCard(event: event, isShared: isShared)
                }
            }
        }
    }
}

struct EventCard: View {
    @Environment(ThemeManager.self) var themeManager
    let event: Event
    let isShared: Bool
    @State private var isPressed = false
    
    init(event: Event, isShared: Bool = false) {
        self.event = event
        self.isShared = isShared
    }

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 4) {
                Text(event.startTime, format: .dateTime.hour().minute())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)

                Text(event.endTime, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .frame(width: 60)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeManager.accentColor.opacity(0.1))
            )

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: isShared ? [.pink, .pink.opacity(0.7)] : [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    if isShared {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.pink)
                    }
                }

                if let description = event.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let location = event.location {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(themeManager.secondaryTextColor)
                    }

                    if event.recurrenceType != "none" {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption2)
                            Text(event.recurrenceType.capitalized)
                                .font(.caption)
                        }
                        .foregroundColor(themeManager.accentColor)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding()
        .themedCardBackground(cornerRadius: 12, shadow: true)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Empty Events View

struct EmptyEventsView: View {
    @Environment(ThemeManager.self) var themeManager
    let date: Date
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.accentColor.opacity(0.2),
                                themeManager.accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .opacity(animateIcon ? 0.8 : 1.0)
                
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
            }

            VStack(spacing: 6) {
                Text("No events")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)

                Text("Create an event for \(date.formatted(.dateTime.month().day()))")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
}
