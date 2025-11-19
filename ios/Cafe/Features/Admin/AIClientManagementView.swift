//
//  AIClientManagementView.swift
//  Cafe
//
//  AI client node management interface
//

import SwiftUI

struct AIClientManagementView: View {
    @State private var clients: [AIClientNode] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingClientDetail: AIClientNode?
    @State private var testingAllClients = false

    var body: some View {
        List {
            if isLoading && clients.isEmpty {
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
                overviewSection
                clientsSection
                actionsSection
            }
        }
        .navigationTitle("AI Client Nodes")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadClients()
        }
        .task {
            await loadClients()
        }
        .sheet(item: $showingClientDetail) { client in
            NavigationStack {
                AIClientDetailView(client: client) {
                    await loadClients()
                }
            }
        }
    }

    private var overviewSection: some View {
        Section("Overview") {
            HStack {
                Label("Total Nodes", systemImage: "server.rack")
                Spacer()
                Text("\(clients.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            HStack {
                Label("Online", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(clients.filter { $0.status.lowercased() == "online" }.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }

            HStack {
                Label("Public Nodes", systemImage: "globe")
                Spacer()
                Text("\(clients.filter { $0.isPublic }.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }
        }
    }

    private var clientsSection: some View {
        Section("AI Clients") {
            if clients.isEmpty {
                Text("No AI clients configured")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(clients) { client in
                    Button(action: { showingClientDetail = client }) {
                        AIClientRow(client: client)
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(action: { _Concurrency.Task { await healthCheckAll() } }) {
                if testingAllClients {
                    HStack {
                        ProgressView()
                        Text("Testing Connections...")
                    }
                } else {
                    Label("Test All Connections", systemImage: "stethoscope")
                }
            }
            .disabled(testingAllClients || clients.isEmpty)
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadClients() async {
        isLoading = true
        errorMessage = nil

        do {
            clients = try await APIClient.shared.getAIClients()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load AI clients: \(error)")
        }

        isLoading = false
    }

    @MainActor
    private func healthCheckAll() async {
        testingAllClients = true

        do {
            _ = try await APIClient.shared.healthCheckAllAIClients()
            // Reload clients to get updated status
            await loadClients()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to health check clients: \(error)")
        }

        testingAllClients = false
    }
}

// MARK: - AI Client Row

struct AIClientRow: View {
    let client: AIClientNode

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(.blue)

                Text(client.name)
                    .font(.headline)

                Spacer()

                statusIndicator

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(client.nodeType.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)

                if client.isPublic {
                    Text("PUBLIC")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }

                if !client.isActive {
                    Text("INACTIVE")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(4)
                }
            }

            Text("\(client.hostname):\(client.port)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let lastSeen = client.lastSeenAt {
                Text("Last seen: \(lastSeen)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(client.status.capitalized)
                .font(.caption)
                .foregroundColor(statusColor)
        }
    }

    private var statusColor: Color {
        switch client.status.lowercased() {
        case "online": return .green
        case "offline": return .red
        case "degraded": return .yellow
        default: return .gray
        }
    }
}

// MARK: - AI Client Detail View

struct AIClientDetailView: View {
    let client: AIClientNode
    let onUpdate: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    @State private var isTesting = false
    @State private var errorMessage: String?
    @State private var testResult: ConnectionTestResponse?
    @State private var models: [String] = []
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section("Client Information") {
                LabeledContent("Name", value: client.name)
                LabeledContent("Type", value: client.nodeType.uppercased())
                LabeledContent("Hostname", value: client.hostname)
                LabeledContent("Port", value: "\(client.port)")
                LabeledContent("Base URL", value: client.baseUrl)
            }

            Section("Status") {
                HStack {
                    Label("Connection Status", systemImage: "network")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(client.status.capitalized)
                            .foregroundColor(statusColor)
                    }
                }

                HStack {
                    Label("Active", systemImage: client.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                    Spacer()
                    Text(client.isActive ? "Yes" : "No")
                        .foregroundColor(client.isActive ? .green : .gray)
                }

                HStack {
                    Label("Public Access", systemImage: "globe")
                    Spacer()
                    Text(client.isPublic ? "Yes" : "No")
                        .foregroundColor(client.isPublic ? .purple : .secondary)
                }

                if let lastSeen = client.lastSeenAt {
                    LabeledContent("Last Seen", value: lastSeen)
                }
            }

            if !models.isEmpty {
                Section("Available Models") {
                    ForEach(models, id: \.self) { model in
                        HStack {
                            Image(systemName: "brain")
                                .foregroundColor(.purple)
                            Text(model)
                                .font(.body)
                        }
                    }
                }
            }

            if let result = testResult {
                Section("Connection Test") {
                    HStack {
                        Label("Status", systemImage: result.online ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.online ? .green : .red)
                        Spacer()
                        Text(result.online ? "Online" : "Offline")
                            .foregroundColor(result.online ? .green : .red)
                    }

                    if let message = result.message {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let modelCount = result.modelCount {
                        LabeledContent("Models Available", value: "\(modelCount)")
                    }

                    if let responseTime = result.responseTimeMs {
                        LabeledContent("Response Time", value: "\(responseTime)ms")
                    }
                }
            }

            Section("Actions") {
                Button(action: { _Concurrency.Task { await testConnection() } }) {
                    if isTesting {
                        HStack {
                            ProgressView()
                            Text("Testing Connection...")
                        }
                    } else {
                        Label("Test Connection", systemImage: "stethoscope")
                    }
                }
                .disabled(isTesting || isUpdating)

                Button(action: { _Concurrency.Task { await loadModels() } }) {
                    Label("Refresh Models", systemImage: "arrow.clockwise")
                }
                .disabled(isTesting || isUpdating)

                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Delete Client", systemImage: "trash")
                }
                .disabled(isTesting || isUpdating)
            }

            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isUpdating || isTesting {
                    ProgressView()
                } else {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadModels()
        }
        .confirmationDialog("Delete Client", isPresented: $showingDeleteConfirmation) {
            Button("Delete Client", role: .destructive) {
                _Concurrency.Task {
                    await deleteClient()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(client.name)? This action cannot be undone.")
        }
    }

    private var statusColor: Color {
        switch client.status.lowercased() {
        case "online": return .green
        case "offline": return .red
        case "degraded": return .yellow
        default: return .gray
        }
    }

    // MARK: - Actions

    @MainActor
    private func testConnection() async {
        isTesting = true
        errorMessage = nil
        testResult = nil

        do {
            testResult = try await APIClient.shared.testAIClientConnection(id: client.id)
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to test connection: \(error)")
        }

        isTesting = false
    }

    @MainActor
    private func loadModels() async {
        isUpdating = true
        errorMessage = nil

        do {
            models = try await APIClient.shared.getAIClientModels(id: client.id)
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load models: \(error)")
        }

        isUpdating = false
    }

    @MainActor
    private func deleteClient() async {
        isUpdating = true
        errorMessage = nil

        do {
            try await APIClient.shared.deleteAIClient(id: client.id)
            await onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to delete client: \(error)")
        }

        isUpdating = false
    }
}

#Preview {
    NavigationStack {
        AIClientManagementView()
    }
}
