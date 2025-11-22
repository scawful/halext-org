//
//  ConnectedDevicesView.swift
//  Cafe
//
//  View and manage connected devices
//

import SwiftUI

struct ConnectedDevicesView: View {
    @State private var devices: [ConnectedDevice] = [
        ConnectedDevice(
            id: "1",
            name: "iPhone 15 Pro",
            type: .iPhone,
            lastSynced: Date().addingTimeInterval(-300),
            isCurrentDevice: true
        ),
        ConnectedDevice(
            id: "2",
            name: "iPad Pro",
            type: .iPad,
            lastSynced: Date().addingTimeInterval(-3600),
            isCurrentDevice: false
        ),
        ConnectedDevice(
            id: "3",
            name: "MacBook Pro",
            type: .mac,
            lastSynced: Date().addingTimeInterval(-7200),
            isCurrentDevice: false
        )
    ]

    var body: some View {
        List {
            Section {
                ForEach(devices) { device in
                    DeviceRow(device: device)
                }
                .onDelete(perform: removeDevice)
            } header: {
                Text("Your Devices")
            } footer: {
                Text("Devices signed in with your account. Swipe to remove a device.")
            }

            Section {
                Button(action: refreshDevices) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh List")
                    }
                }
            }
        }
        .navigationTitle("Connected Devices")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func removeDevice(at offsets: IndexSet) {
        devices.remove(atOffsets: offsets)
    }

    private func refreshDevices() {
        // Refresh device list from server
    }
}

struct DeviceRow: View {
    let device: ConnectedDevice

    var body: some View {
        HStack(spacing: 16) {
            // Device icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(device.type.color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: device.type.icon)
                    .font(.title2)
                    .foregroundColor(device.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if device.isCurrentDevice {
                        Text("This device")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.2))
                            )
                            .foregroundColor(.blue)
                    }
                }

                Text(device.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Last synced \(timeAgoString(device.lastSynced))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func timeAgoString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ConnectedDevice: Identifiable {
    let id: String
    let name: String
    let type: DeviceType
    let lastSynced: Date
    let isCurrentDevice: Bool
}

enum DeviceType {
    case iPhone
    case iPad
    case mac
    case appleWatch

    var icon: String {
        switch self {
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .mac: return "laptopcomputer"
        case .appleWatch: return "applewatch"
        }
    }

    var displayName: String {
        switch self {
        case .iPhone: return "iPhone"
        case .iPad: return "iPad"
        case .mac: return "Mac"
        case .appleWatch: return "Apple Watch"
        }
    }

    var color: Color {
        switch self {
        case .iPhone: return .blue
        case .iPad: return .purple
        case .mac: return .gray
        case .appleWatch: return .red
        }
    }
}

#Preview {
    NavigationStack {
        ConnectedDevicesView()
    }
}
