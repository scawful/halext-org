//
//  AdminStatsView.swift
//  Cafe
//
//  System statistics and health monitoring dashboard
//

import SwiftUI
import Charts

struct AdminStatsView: View {
    @State private var stats: SystemStats?
    @State private var health: ServerHealth?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefresh = Date()

    var body: some View {
        List {
            if isLoading && stats == nil {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            } else {
                if let health = health {
                    serverHealthSection(health: health)
                }

                if let stats = stats {
                    systemStatsSection(stats: stats)
                    activityStatsSection(stats: stats)
                }

                refreshSection
            }
        }
        .navigationTitle("System Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { _Concurrency.Task { await loadData() } }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
    }

    @ViewBuilder
    private func serverHealthSection(health: ServerHealth) -> some View {
        Section("Server Health") {
            HStack {
                Label("Overall Status", systemImage: "server.rack")
                Spacer()
                Text(health.status.capitalized)
                    .foregroundColor(colorForStatus(health.statusColor))
                    .fontWeight(.semibold)
            }

            HStack {
                Label("API", systemImage: "network")
                Spacer()
                statusBadge(health.apiStatus)
            }

            HStack {
                Label("Database", systemImage: "cylinder.fill")
                Spacer()
                statusBadge(health.databaseStatus)
            }

            HStack {
                Label("AI Service", systemImage: "brain")
                Spacer()
                statusBadge(health.aiServiceStatus)
            }

            HStack {
                Label("Response Time", systemImage: "speedometer")
                Spacer()
                Text("\(Int(health.averageResponseTime))ms")
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Uptime", systemImage: "clock")
                Spacer()
                Text(formatUptime(health.uptime))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func systemStatsSection(stats: SystemStats) -> some View {
        Section("System Overview") {
            StatRow(
                icon: "person.3.fill",
                label: "Total Users",
                value: "\(stats.totalUsers)",
                color: .blue
            )

            StatRow(
                icon: "checkmark.circle.fill",
                label: "Total Tasks",
                value: "\(stats.totalTasks)",
                color: .green
            )

            StatRow(
                icon: "calendar",
                label: "Total Events",
                value: "\(stats.totalEvents)",
                color: .orange
            )

            StatRow(
                icon: "message.fill",
                label: "Total Messages",
                value: "\(stats.totalMessages)",
                color: .cyan
            )
        }
    }

    @ViewBuilder
    private func activityStatsSection(stats: SystemStats) -> some View {
        Section("Recent Activity") {
            StatRow(
                icon: "person.circle.fill",
                label: "Active Users",
                value: "\(stats.activeUsers)",
                color: .purple
            )

            StatRow(
                icon: "checkmark.square.fill",
                label: "Tasks Completed Today",
                value: "\(stats.tasksCompletedToday)",
                color: .mint
            )

            StatRow(
                icon: "calendar.badge.clock",
                label: "Events Today",
                value: "\(stats.eventsToday)",
                color: .pink
            )
        }
    }

    private var refreshSection: some View {
        Section {
            HStack {
                Label("Last Updated", systemImage: "clock.arrow.circlepath")
                Spacer()
                Text(lastRefresh, style: .relative)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForServiceStatus(status))
                .frame(width: 8, height: 8)
            Text(status.capitalized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let statsResult = APIClient.shared.getSystemStats()
            async let healthResult = APIClient.shared.getServerHealth()

            stats = try await statsResult
            health = try await healthResult
            lastRefresh = Date()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load admin stats: \(error)")
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }

    private func colorForServiceStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "healthy", "online": return .green
        case "degraded": return .yellow
        case "down", "offline": return .red
        default: return .gray
        }
    }

    private func formatUptime(_ seconds: Int) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Stat Row Component

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Label {
                Text(label)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    NavigationStack {
        AdminStatsView()
    }
}
