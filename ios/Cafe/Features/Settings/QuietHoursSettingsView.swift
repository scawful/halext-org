//
//  QuietHoursSettingsView.swift
//  Cafe
//
//  Configure quiet hours for notifications
//

import SwiftUI

struct QuietHoursSettingsView: View {
    @State private var settingsManager = SettingsManager.shared

    var body: some View {
        List {
            Section {
                Toggle("Enable Quiet Hours", isOn: $settingsManager.quietHoursEnabled)

                if settingsManager.quietHoursEnabled {
                    DatePicker(
                        "Start Time",
                        selection: $settingsManager.quietHoursStart,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "End Time",
                        selection: $settingsManager.quietHoursEnd,
                        displayedComponents: .hourAndMinute
                    )
                }
            } header: {
                Text("Quiet Hours")
            } footer: {
                Text("Notifications will be silenced during quiet hours. Urgent notifications may still appear.")
            }

            if settingsManager.quietHoursEnabled {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.indigo)
                            Text("Quiet hours active")
                                .fontWeight(.medium)
                        }

                        Text("From \(formattedTime(settingsManager.quietHoursStart)) to \(formattedTime(settingsManager.quietHoursEnd))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Divider()
                            .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            InfoBullet(text: "Regular notifications will be silenced")
                            InfoBullet(text: "You'll still see notification badges")
                            InfoBullet(text: "Critical alerts will still sound")
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Summary")
                }
            }
        }
        .navigationTitle("Quiet Hours")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoBullet: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.secondary)
                .frame(width: 4, height: 4)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        QuietHoursSettingsView()
    }
}
