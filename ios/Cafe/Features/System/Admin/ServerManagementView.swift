//
//  ServerManagementView.swift
//  Cafe
//
//  Server management and monitoring
//

import SwiftUI

struct ServerManagementView: View {
    @State private var serverStats: ServerStats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastRefresh: Date?
    @State private var showingActionResult = false
    @State private var actionMessage: String?
    
    var body: some View {
        List {
            // Server Health Section
            Section("Server Health") {
                if isLoading && serverStats == nil {
                    HStack {
                        ProgressView()
                        Text("Loading server stats...")
                            .foregroundColor(.secondary)
                    }
                } else if let stats = serverStats {
                    ServerHealthCard(stats: stats)
                } else {
                    Text("Unable to load server statistics")
                        .foregroundColor(.secondary)
                }
                
                if let lastRefresh = lastRefresh {
                    HStack {
                        Text("Last updated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(lastRefresh, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // System Resources
            if let stats = serverStats {
                Section("System Resources") {
                    ResourceRow(
                        icon: "cpu",
                        label: "CPU Usage",
                        value: "\(Int(stats.cpuUsagePercent))%",
                        color: stats.cpuUsagePercent > 80 ? .red : .green
                    )
                    
                    ResourceRow(
                        icon: "memorychip",
                        label: "Memory Usage",
                        value: "\(Int(stats.memoryUsagePercent))%",
                        color: stats.memoryUsagePercent > 80 ? .red : .green
                    )
                    
                    ResourceRow(
                        icon: "internaldrive",
                        label: "Disk Usage",
                        value: "\(Int(stats.diskUsagePercent))%",
                        color: stats.diskUsagePercent > 90 ? .red : .green
                    )
                }
                
                // Running Services
                Section("Services") {
                    ServiceRow(name: "API Server", status: stats.apiServerRunning ? .running : .stopped)
                    ServiceRow(name: "Database", status: stats.databaseConnected ? .running : .stopped)
                    ServiceRow(name: "AI Provider", status: stats.aiProviderAvailable ? .running : .stopped)
                }
            }
            
            // Server Actions
            Section("Server Actions") {
                Button(action: restartAPIServer) {
                    Label("Restart API Server", systemImage: "arrow.clockwise.circle")
                }
                .foregroundColor(.orange)
                
                Button(action: clearServerCache) {
                    Label("Clear Server Cache", systemImage: "trash.circle")
                }
                .foregroundColor(.blue)
                
                Button(action: syncDatabase) {
                    Label("Sync Database", systemImage: "arrow.triangle.2.circlepath.circle")
                }
                .foregroundColor(.green)
            }
            
            // Logs
            Section {
                NavigationLink(destination: ServerLogsView()) {
                    Label("View Server Logs", systemImage: "doc.text.magnifyingglass")
                }
            }
        }
        .navigationTitle("Server Management")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadServerStats()
        }
        .task {
            await loadServerStats()
        }
        .alert("Action Result", isPresented: $showingActionResult) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = actionMessage {
                Text(message)
            }
        }
    }
    
    private func loadServerStats() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            serverStats = try await APIClient.shared.getServerStats()
            lastRefresh = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func restartAPIServer() {
        _Concurrency.Task {
            do {
                let result = try await APIClient.shared.restartAPIServer()
                actionMessage = result.message
                showingActionResult = true
                
                // Wait a moment then reload stats
                try await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                await loadServerStats()
            } catch {
                actionMessage = "Failed: \(error.localizedDescription)"
                showingActionResult = true
            }
        }
    }
    
    private func clearServerCache() {
        _Concurrency.Task {
            do {
                let result = try await APIClient.shared.clearCache()
                actionMessage = result.message
                await MainActor.run {
                    showingActionResult = true
                }
            } catch {
                await MainActor.run {
                    actionMessage = "Failed: \(error.localizedDescription)"
                    showingActionResult = true
                }
            }
        }
    }
    
    private func syncDatabase() {
        _Concurrency.Task {
            do {
                let result = try await APIClient.shared.syncDatabase()
                actionMessage = result.message
                showingActionResult = true
            } catch {
                actionMessage = "Failed: \(error.localizedDescription)"
                showingActionResult = true
            }
        }
    }
}

// MARK: - Server Health Card

struct ServerHealthCard: View {
    let stats: ServerStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(stats.isHealthy ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(stats.isHealthy ? "Healthy" : "Issues Detected")
                    .font(.headline)
                    .foregroundColor(stats.isHealthy ? .green : .red)
                
                Spacer()
            }
            
            Divider()
            
            VStack(spacing: 8) {
                ServerStatRow(label: "Uptime", value: stats.uptimeFormatted)
                ServerStatRow(label: "Active Users", value: "\(stats.activeUsers)")
                ServerStatRow(label: "Total Requests", value: "\(stats.totalRequests)")
            }
        }
        .padding(.vertical, 8)
    }
}

struct ServerStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Resource Row

struct ResourceRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Service Row

struct ServiceRow: View {
    let name: String
    let status: ServiceStatus
    
    enum ServiceStatus {
        case running
        case stopped
        case error
        
        var color: Color {
            switch self {
            case .running: return .green
            case .stopped: return .gray
            case .error: return .red
            }
        }
        
        var label: String {
            switch self {
            case .running: return "Running"
            case .stopped: return "Stopped"
            case .error: return "Error"
            }
        }
        
        var icon: String {
            switch self {
            case .running: return "checkmark.circle.fill"
            case .stopped: return "pause.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            Label(status.label, systemImage: status.icon)
                .font(.caption)
                .foregroundColor(status.color)
        }
    }
}

// MARK: - Server Logs View

struct ServerLogsView: View {
    @State private var logs: [String] = []
    @State private var isLoading = false
    @State private var logLevel: LogLevel = .all
    
    enum LogLevel: String, CaseIterable {
        case all = "All"
        case error = "Errors"
        case warning = "Warnings"
        case info = "Info"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Log Level", selection: $logLevel) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if logs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No logs available")
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(logs.indices, id: \.self) { index in
                            LogLineView(line: logs[index])
                        }
                    }
                    .padding()
                }
                .font(.system(.caption, design: .monospaced))
            }
        }
        .navigationTitle("Server Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { _Concurrency.Task { await loadLogs() } }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await loadLogs()
        }
        .onChange(of: logLevel) { _, _ in
            _Concurrency.Task {
                await loadLogs()
            }
        }
    }
    
    private func loadLogs() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            logs = try await APIClient.shared.getServerLogs(level: logLevel.rawValue.lowercased())
        } catch {
            logs = ["Error loading logs: \(error.localizedDescription)"]
        }
    }
}

struct LogLineView: View {
    let line: String
    
    var lineColor: Color {
        if line.contains("ERROR") {
            return .red
        } else if line.contains("WARNING") {
            return .orange
        } else if line.contains("INFO") {
            return .blue
        }
        return .primary
    }
    
    var body: some View {
        Text(line)
            .foregroundColor(lineColor)
    }
}

// MARK: - Server Stats Model

struct ServerStats: Codable {
    let cpuUsagePercent: Double
    let memoryUsagePercent: Double
    let diskUsagePercent: Double
    let uptimeSeconds: Int
    let activeUsers: Int
    let totalRequests: Int
    let apiServerRunning: Bool
    let databaseConnected: Bool
    let aiProviderAvailable: Bool
    
    var isHealthy: Bool {
        apiServerRunning && databaseConnected && cpuUsagePercent < 90 && memoryUsagePercent < 90
    }
    
    var uptimeFormatted: String {
        let hours = uptimeSeconds / 3600
        let minutes = (uptimeSeconds % 3600) / 60
        
        if hours > 24 {
            return "\(hours / 24)d \(hours % 24)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    NavigationStack {
        ServerManagementView()
    }
}

