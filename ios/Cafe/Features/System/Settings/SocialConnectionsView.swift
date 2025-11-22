//
//  SocialConnectionsView.swift
//  Cafe
//
//  Link social accounts and integrations
//

import SwiftUI

struct SocialConnectionsView: View {
    @State private var connections: [SocialConnection] = [
        SocialConnection(
            id: "google",
            name: "Google",
            icon: "g.circle.fill",
            color: .red,
            isConnected: true,
            connectedAccount: "user@gmail.com"
        ),
        SocialConnection(
            id: "apple",
            name: "Apple",
            icon: "apple.logo",
            color: .black,
            isConnected: true,
            connectedAccount: "user@icloud.com"
        ),
        SocialConnection(
            id: "github",
            name: "GitHub",
            icon: "chevron.left.forwardslash.chevron.right",
            color: .purple,
            isConnected: false,
            connectedAccount: nil
        ),
        SocialConnection(
            id: "slack",
            name: "Slack",
            icon: "message.fill",
            color: .purple,
            isConnected: false,
            connectedAccount: nil
        )
    ]

    var body: some View {
        List {
            Section {
                ForEach(connections) { connection in
                    ConnectionRow(connection: connection) {
                        if connection.isConnected {
                            disconnectAccount(connection)
                        } else {
                            connectAccount(connection)
                        }
                    }
                }
            } header: {
                Text("Connected Accounts")
            } footer: {
                Text("Link accounts to enable cross-platform features and integrations")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Your data is secure")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text("We use industry-standard OAuth authentication. Your credentials are never stored on our servers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Social Connections")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func connectAccount(_ connection: SocialConnection) {
        // Implement OAuth flow
    }

    private func disconnectAccount(_ connection: SocialConnection) {
        // Disconnect account
        if let index = connections.firstIndex(where: { $0.id == connection.id }) {
            connections[index].isConnected = false
            connections[index].connectedAccount = nil
        }
    }
}

struct ConnectionRow: View {
    let connection: SocialConnection
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(connection.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: connection.icon)
                    .font(.title3)
                    .foregroundColor(connection.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(connection.name)
                    .font(.body)
                    .fontWeight(.medium)

                if let account = connection.connectedAccount {
                    Text(account)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Not connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: action) {
                Text(connection.isConnected ? "Disconnect" : "Connect")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(connection.isConnected ? .red : .blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SocialConnection: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    var isConnected: Bool
    var connectedAccount: String?
}

#Preview {
    NavigationStack {
        SocialConnectionsView()
    }
}
