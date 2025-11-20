//
//  SocialDashboardView.swift
//  Cafe
//
//  Main social dashboard with tabs and partner status widget
//

import SwiftUI

struct SocialDashboardView: View {
    @State private var socialManager = SocialManager.shared
    @State private var presenceManager = SocialPresenceManager.shared
    @State private var selectedTab: SocialTab = .tasks

    enum SocialTab: String, CaseIterable {
        case tasks = "Tasks"
        case activity = "Activity"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .tasks:
                return "checkmark.circle"
            case .activity:
                return "bell"
            case .profile:
                return "person.circle"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Partner Status Widget
                if !socialManager.connections.isEmpty {
                    PartnerStatusWidget()
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                }

                // Tab Content
                TabView(selection: $selectedTab) {
                    SharedTasksView()
                        .tag(SocialTab.tasks)

                    ActivityFeedView()
                        .tag(SocialTab.activity)

                    UserProfileView()
                        .tag(SocialTab.profile)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(SocialTab.allCases, id: \.self) { tab in
                            Label(tab.rawValue, systemImage: tab.icon)
                                .tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
            }
            .task {
                await initializeSocial()
            }
        }
    }

    private func initializeSocial() async {
        // Start presence tracking
        presenceManager.startTrackingPresence()
        presenceManager.startMonitoringPartnerPresence()

        // Load initial data
        try? await socialManager.fetchConnections()

        do {
            try await socialManager.fetchSharedTasks()
            try await socialManager.fetchActivities()
        } catch {
            print("Failed to load social data: \(error)")
        }
    }
}

// MARK: - Partner Status Widget

struct PartnerStatusWidget: View {
    @State private var socialManager = SocialManager.shared

    var partners: [SocialProfile] {
        Array(socialManager.partnerProfiles.values)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Connected Partners", systemImage: "person.2.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(partners.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }

            if partners.isEmpty {
                Text("No connections yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(partners) { partner in
                    PartnerCard(partner: partner)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Partner Card

struct PartnerCard: View {
    let partner: SocialProfile
    @State private var socialManager = SocialManager.shared

    var presence: SocialPresenceStatus? {
        socialManager.presenceStatuses[partner.id]
    }

    var sharedTasksCount: Int {
        socialManager.sharedTasks.filter { !$0.completed }.count
    }

    var completedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return socialManager.sharedTasks.filter { task in
            task.completed &&
            task.completedAt ?? Date.distantPast >= today
        }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)

                Text(partner.username.prefix(2).uppercased())
                    .font(.headline)
                    .foregroundColor(.white)

                // Online indicator
                if let presence = presence, presence.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(partner.displayName ?? partner.username)
                    .font(.headline)

                if let activity = partner.currentActivity {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(partner.isOnline ? .green : .gray)
                        Text(activity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let statusMessage = partner.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(partner.isOnline ? .green : .gray)
                        Text(partner.isOnline ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Stats
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("\(sharedTasksCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 2) {
                        Text("\(completedToday)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Today")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Compact Partner Status Widget (for Dashboard integration)

struct CompactPartnerStatusWidget: View {
    @State private var socialManager = SocialManager.shared

    var partner: SocialProfile? {
        socialManager.partnerProfiles.values.first
    }

    var sharedTasksCount: Int {
        socialManager.sharedTasks.filter { !$0.completed }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            if let partner = partner {
                HStack(spacing: 12) {
                    // Avatar
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 40, height: 40)

                        Text(partner.username.prefix(1).uppercased())
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if partner.isOnline {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .offset(x: 2, y: 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(partner.displayName ?? partner.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if let activity = partner.currentActivity {
                            Text(activity)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text(partner.isOnline ? "Online" : "Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Task count
                    VStack(spacing: 2) {
                        Text("\(sharedTasksCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Tasks")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.circle")
                        .font(.largeTitle)
                        .foregroundColor(.gray)

                    Text("No Partner Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Social Quick Actions

struct SocialQuickActionsView: View {
    @State private var showingNewTask = false
    @State private var showingStatusPicker = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                SocialQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "New Task",
                    color: .blue
                ) {
                    showingNewTask = true
                }

                SocialQuickActionButton(
                    icon: "circle.fill",
                    title: "Set Status",
                    color: .orange
                ) {
                    showingStatusPicker = true
                }

                SocialQuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Refresh",
                    color: .green
                ) {
                    // Refresh action
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .sheet(isPresented: $showingNewTask) {
            NewSharedTaskView()
        }
        .sheet(isPresented: $showingStatusPicker) {
            SocialStatusPickerView()
        }
    }
}

struct SocialQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SocialDashboardView()
}

#Preview("Widget") {
    CompactPartnerStatusWidget()
        .padding()
}
