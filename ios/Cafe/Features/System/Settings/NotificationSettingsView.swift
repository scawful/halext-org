//
//  NotificationSettingsView.swift
//  Cafe
//
//  Granular notification controls
//

import SwiftUI

struct NotificationSettingsView: View {
    @State private var notificationManager = NotificationManager.shared

    @AppStorage("notify_tasks") private var notifyTasks = true
    @AppStorage("notify_events") private var notifyEvents = true
    @AppStorage("notify_messages") private var notifyMessages = true
    @AppStorage("notify_reminders") private var notifyReminders = true
    @AppStorage("notify_updates") private var notifyUpdates = true

    @AppStorage("notification_lead_time") private var leadTime = 15

    var body: some View {
        List {
            Section {
                Toggle(isOn: $notifyTasks) {
                    NotificationTypeRow(
                        icon: "checkmark.circle.fill",
                        iconColor: .blue,
                        title: "Tasks",
                        description: "Due dates and reminders"
                    )
                }

                Toggle(isOn: $notifyEvents) {
                    NotificationTypeRow(
                        icon: "calendar",
                        iconColor: .red,
                        title: "Events",
                        description: "Calendar event reminders"
                    )
                }

                Toggle(isOn: $notifyMessages) {
                    NotificationTypeRow(
                        icon: "message.fill",
                        iconColor: .green,
                        title: "Messages",
                        description: "New messages and mentions"
                    )
                }

                Toggle(isOn: $notifyReminders) {
                    NotificationTypeRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Reminders",
                        description: "Custom reminders"
                    )
                }

                Toggle(isOn: $notifyUpdates) {
                    NotificationTypeRow(
                        icon: "arrow.down.circle.fill",
                        iconColor: .purple,
                        title: "App Updates",
                        description: "New features and improvements"
                    )
                }
            } header: {
                Text("Notification Types")
            } footer: {
                Text("Choose which types of notifications you want to receive")
            }

            Section {
                Picker("Reminder Lead Time", selection: $leadTime) {
                    Text("5 minutes").tag(5)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                    Text("1 day").tag(1440)
                }
            } header: {
                Text("Timing")
            } footer: {
                Text("How much advance notice for upcoming tasks and events")
            }

            Section {
                Button(action: openSystemSettings) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                        Text("Open System Settings")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("System Settings")
            } footer: {
                Text("Configure notification style, sounds, and badges in system settings")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct NotificationTypeRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
