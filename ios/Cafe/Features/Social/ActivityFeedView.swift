//
//  ActivityFeedView.swift
//  Cafe
//
//  Timeline of shared activities and updates
//

import SwiftUI

struct ActivityFeedView: View {
    @State private var socialManager = SocialManager.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTimeframe: Timeframe = .today

    enum Timeframe: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"

        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .today:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .all:
                return Date.distantPast
            }
        }
    }

    var filteredActivities: [ActivityItem] {
        socialManager.activities.filter { activity in
            activity.timestamp >= selectedTimeframe.startDate
        }
    }

    var groupedActivities: [Date: [ActivityItem]] {
        Dictionary(grouping: filteredActivities) { activity in
            Calendar.current.startOfDay(for: activity.timestamp)
        }
    }

    var sortedDates: [Date] {
        groupedActivities.keys.sorted(by: >)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timeframe Picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                Divider()

                // Activity Timeline
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredActivities.isEmpty {
                    EmptyActivityView()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                            ForEach(sortedDates, id: \.self) { date in
                                Section {
                                    if let activities = groupedActivities[date] {
                                        ForEach(activities) { activity in
                                            ActivityItemRow(activity: activity)
                                        }
                                    }
                                } header: {
                                    DateHeaderView(date: date)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Activity Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: refreshActivities) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
            .task {
                await loadActivities()
            }
            .refreshable {
                await loadActivities()
            }
        }
    }

    // MARK: - Actions

    private func loadActivities() async {
        isLoading = true

        do {
            try await socialManager.fetchActivities()
            isLoading = false
        } catch {
            errorMessage = "Failed to load activities: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func refreshActivities() {
        _Concurrency.Task {
            await loadActivities()
        }
    }
}

// MARK: - Date Header

struct DateHeaderView: View {
    let date: Date

    var dateString: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(.dateTime.month().day().year())
        }
    }

    var body: some View {
        Text(dateString)
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemBackground))
    }
}

// MARK: - Activity Item Row

struct ActivityItemRow: View {
    let activity: ActivityItem
    @State private var socialManager = SocialManager.shared

    var actorProfile: SocialProfile? {
        socialManager.partnerProfiles[activity.profileId] ?? socialManager.currentProfile
    }

    var isMyActivity: Bool {
        activity.profileId == socialManager.currentProfile?.id
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline Indicator
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(activity.iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: activity.icon)
                        .font(.body)
                        .foregroundColor(activity.iconColor)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            VStack(alignment: .leading, spacing: 8) {
                // Actor & Action
                HStack(spacing: 6) {
                    Text(isMyActivity ? "You" : actorProfile?.displayName ?? actorProfile?.username ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isMyActivity ? .blue : .primary)

                    Text(actionDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Title
                Text(activity.title)
                    .font(.body)
                    .foregroundColor(.primary)

                // Description
                if let description = activity.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                // Metadata
                HStack(spacing: 12) {
                    // Timestamp
                    Label(
                        activity.timestamp.formatted(.relative(presentation: .named)),
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)

                    // Related item indicator
                    if activity.relatedTaskId != nil {
                        Label("Task", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if activity.relatedEventId != nil {
                        Label("Event", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
    }

    var actionDescription: String {
        switch activity.activityType {
        case .taskCreated:
            return "created a task"
        case .taskCompleted:
            return "completed a task"
        case .taskAssigned:
            return "assigned a task"
        case .taskCommented:
            return "commented on a task"
        case .eventCreated:
            return "created an event"
        case .eventUpdated:
            return "updated an event"
        case .statusChanged:
            return "changed status"
        case .connectionAccepted:
            return "connected"
        }
    }
}

// MARK: - Empty Activity View

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Activity Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Activity from you and your partner will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Activity Detail View

struct ActivityDetailView: View {
    let activity: ActivityItem
    @State private var socialManager = SocialManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(activity.iconColor.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: activity.icon)
                                .font(.title2)
                                .foregroundColor(activity.iconColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.title)
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text(activity.timestamp.formatted(.dateTime.month().day().hour().minute()))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()

                    Divider()

                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        if let description = activity.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                Text(description)
                                    .font(.body)
                            }
                            .padding(.horizontal)
                        }

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Type")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            HStack {
                                Image(systemName: activity.icon)
                                    .foregroundColor(activity.iconColor)
                                Text(activity.activityType.rawValue)
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal)

                        // Related Items
                        if activity.relatedTaskId != nil || activity.relatedEventId != nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Related Items")
                                    .font(.headline)
                                    .foregroundColor(.secondary)

                                if let taskId = activity.relatedTaskId {
                                    HStack {
                                        Image(systemName: "checkmark.circle")
                                        Text("Task: \(taskId)")
                                            .font(.body)
                                    }
                                }

                                if let eventId = activity.relatedEventId {
                                    HStack {
                                        Image(systemName: "calendar")
                                        Text("Event: \(eventId)")
                                            .font(.body)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Activity Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ActivityFeedView()
}
