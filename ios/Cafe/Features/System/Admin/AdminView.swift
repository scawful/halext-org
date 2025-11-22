//
//  AdminView.swift
//  Cafe
//
//  Main admin interface for system management
//

import SwiftUI

struct AdminView: View {
    @Environment(AppState.self) var appState
    @State private var showingClearCacheConfirmation = false
    @State private var showingRebuildConfirmation = false
    @State private var isPerformingAction = false
    @State private var actionMessage: String?
    @State private var showingActionResult = false

    var body: some View {
        NavigationStack {
            List {
                if !appState.isAdmin {
                    Section {
                        Label("Admin access required", systemImage: "lock.shield")
                            .foregroundColor(.red)
                    }
                } else {
                    headerSection
                    managementSection
                    systemActionsSection
                    dangerZoneSection
                }
            }
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Clear Cache", isPresented: $showingClearCacheConfirmation) {
                Button("Clear Cache", role: .destructive) {
                    _Concurrency.Task {
                        await clearCache()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all cached data on the server. Are you sure?")
            }
            .confirmationDialog("Rebuild Frontend", isPresented: $showingRebuildConfirmation) {
                Button("Rebuild Frontend", role: .destructive) {
                    _Concurrency.Task {
                        await rebuildFrontend()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will trigger a frontend rebuild. This may take several minutes.")
            }
            .alert("Action Result", isPresented: $showingActionResult) {
                Button("OK", role: .cancel) {}
            } message: {
                if let message = actionMessage {
                    Text(message)
                }
            }
        }
    }

    private var headerSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Administrator Access")
                        .font(.headline)
                        .foregroundColor(.orange)

                    if let user = appState.currentUser {
                        Text("Logged in as \(user.username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "shield.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
            }
            .padding(.vertical, 8)
        }
    }

    private var managementSection: some View {
        Section("System Management") {
            NavigationLink(destination: ServerManagementView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Server Management")
                        Text("Monitor and control the backend server")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "server.rack")
                        .foregroundColor(.red)
                }
            }
            
            NavigationLink(destination: AdminStatsView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Statistics")
                        Text("View server health and metrics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                }
            }

            NavigationLink(destination: UserManagementView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("User Management")
                        Text("Manage user accounts and permissions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.green)
                }
            }

            NavigationLink(destination: AdminAICredentialsView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Credentials")
                        Text("Configure OpenAI and Gemini API keys")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "key.fill")
                        .foregroundColor(.purple)
                }
            }

            NavigationLink(destination: AIClientManagementView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Client Nodes")
                        Text("Manage AI service connections")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "brain")
                        .foregroundColor(.purple)
                }
            }

            NavigationLink(destination: ContentManagementView()) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Content Management")
                        Text("Manage site pages, albums, and blog")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.indigo)
                }
            }
        }
    }

    private var systemActionsSection: some View {
        Section("System Actions") {
            Button(action: { showingClearCacheConfirmation = true }) {
                if isPerformingAction {
                    HStack {
                        ProgressView()
                        Text("Processing...")
                    }
                } else {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear Cache")
                            Text("Remove cached data from server")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .disabled(isPerformingAction)

            Button(action: { showingRebuildConfirmation = true }) {
                if isPerformingAction {
                    HStack {
                        ProgressView()
                        Text("Processing...")
                    }
                } else {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rebuild Frontend")
                            Text("Trigger frontend build process")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "hammer.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .disabled(isPerformingAction)
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Danger Zone")
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                    Text("Actions in this section can affect system stability")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Actions

    @MainActor
    private func clearCache() async {
        isPerformingAction = true

        do {
            let response = try await APIClient.shared.clearCache()
            actionMessage = response.message
            if let items = response.itemsCleared {
                actionMessage = "\(response.message)\n\(items) items cleared"
            }
            showingActionResult = true
            print("Cache cleared: \(response.message)")
        } catch {
            actionMessage = "Failed to clear cache: \(error.localizedDescription)"
            showingActionResult = true
            print("Failed to clear cache: \(error)")
        }

        isPerformingAction = false
    }

    @MainActor
    private func rebuildFrontend() async {
        isPerformingAction = true

        do {
            let response = try await APIClient.shared.rebuildFrontend()
            actionMessage = response.message
            showingActionResult = true
            print("Frontend rebuild: \(response.message)")
        } catch {
            actionMessage = "Failed to rebuild frontend: \(error.localizedDescription)"
            showingActionResult = true
            print("Failed to rebuild frontend: \(error)")
        }

        isPerformingAction = false
    }
}

#Preview {
    AdminView()
        .environment(AppState())
}
