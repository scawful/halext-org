//
//  DashboardView.swift
//  Cafe
//
//  Main dashboard with productivity widgets
//

import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome header
                    WelcomeHeader()
                        .padding(.horizontal)

                    // Stats cards
                    StatsCardsView(viewModel: viewModel)
                        .padding(.horizontal)

                    // Today's tasks widget
                    if !viewModel.todaysTasks.isEmpty {
                        TodaysTasksWidget(tasks: viewModel.todaysTasks)
                            .padding(.horizontal)
                    }

                    // Overdue tasks (if any)
                    if !viewModel.overdueTasks.isEmpty {
                        OverdueTasksWidget(tasks: viewModel.overdueTasks)
                            .padding(.horizontal)
                    }

                    // Upcoming events widget
                    if !viewModel.upcomingEvents.isEmpty {
                        UpcomingEventsWidget(events: viewModel.upcomingEvents)
                            .padding(.horizontal)
                    }

                    // Quick actions
                    QuickActionsWidget()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView()
                }
            }
        }
    }
}

// MARK: - Welcome Header

struct WelcomeHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Decorative icon
            Image(systemName: "sun.max.fill")
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
}

// MARK: - Stats Cards

struct StatsCardsView: View {
    let viewModel: DashboardViewModel

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                value: "\(viewModel.completedToday)",
                label: "Completed Today",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                value: "\(viewModel.tasksThisWeek)",
                label: "This Week",
                icon: "calendar",
                color: .blue
            )

            StatCard(
                value: "\(viewModel.upcomingEventsCount)",
                label: "Upcoming",
                icon: "star.fill",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Today's Tasks Widget

struct TodaysTasksWidget: View {
    let tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                ForEach(tasks.prefix(5)) { task in
                    CompactTaskRow(task: task)
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
}

struct CompactTaskRow: View {
    let task: Task

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completed ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if !task.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.labels.prefix(2)) { label in
                            Text(label.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: label.color ?? "#6B7280").opacity(0.2))
                                )
                        }
                    }
                }
            }

            Spacer()

            if let dueDate = task.dueDate {
                Text(dueDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Overdue Tasks Widget

struct OverdueTasksWidget: View {
    let tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Overdue")
                    .font(.headline)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                ForEach(tasks.prefix(3)) { task in
                    CompactTaskRow(task: task)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .red.opacity(0.1), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Upcoming Events Widget

struct UpcomingEventsWidget: View {
    let events: [Event]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text("Upcoming Events")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(events) { event in
                    EventRow(event: event)
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
}

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(event.startTime, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(event.startTime, format: .dateTime.day())
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.1))
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.startTime, style: .time)
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Quick Actions

struct QuickActionsWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "New Task",
                    icon: "plus.circle.fill",
                    color: .blue
                )

                QuickActionButton(
                    title: "New Event",
                    icon: "calendar.badge.plus",
                    color: .purple
                )

                QuickActionButton(
                    title: "AI Assistant",
                    icon: "sparkles",
                    color: .orange
                )

                QuickActionButton(
                    title: "View All",
                    icon: "list.bullet",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Button {
            // Action will be handled by navigation
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}
