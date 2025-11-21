//
//  SettingsStubViews.swift
//  Cafe
//
//  Stub views for additional settings screens
//

import SwiftUI

// MARK: - Dashboard Layout Settings

struct DashboardLayoutSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Customize your dashboard widget layout")
                    .foregroundColor(.secondary)
            } header: {
                Text("Layout Options")
            }
        }
        .navigationTitle("Dashboard Layout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Labs Features

struct LabsFeaturesView: View {
    @State private var settingsManager = SettingsManager.shared

    private let labsFeatures = [
        LabsFeature(
            id: "ai_suggestions",
            name: "AI Task Suggestions",
            description: "Get intelligent task recommendations based on your habits",
            icon: "wand.and.stars",
            color: .purple
        ),
        LabsFeature(
            id: "voice_commands",
            name: "Advanced Voice Commands",
            description: "Extended voice control throughout the app",
            icon: "mic.fill",
            color: .red
        ),
        LabsFeature(
            id: "smart_scheduling",
            name: "Smart Scheduling",
            description: "AI-powered event time suggestions",
            icon: "calendar.badge.clock",
            color: .blue
        ),
        LabsFeature(
            id: "real_time_sync",
            name: "Real-time Sync",
            description: "Instant synchronization across devices",
            icon: "arrow.triangle.2.circlepath",
            color: .green
        )
    ]

    var body: some View {
        List {
            Section {
                Text("Enable experimental features that are still in development. These features may change or be removed in future updates.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Section {
                ForEach(labsFeatures) { feature in
                    Toggle(isOn: Binding(
                        get: { settingsManager.isLabsFeatureEnabled(feature.id) },
                        set: { enabled in
                            if enabled {
                                settingsManager.enableLabsFeature(feature.id)
                            } else {
                                settingsManager.disableLabsFeature(feature.id)
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: feature.icon)
                                .foregroundColor(feature.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.name)
                                    .font(.body)

                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Experimental Features")
            }
        }
        .navigationTitle("Labs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LabsFeature: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Shortcuts Config

struct ShortcutsConfigView: View {
    var body: some View {
        List {
            Section {
                Button(action: openShortcutsApp) {
                    HStack {
                        Image(systemName: "command")
                            .foregroundColor(.orange)
                        Text("Open Shortcuts App")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Shortcuts App")
            }

            Section {
                NavigationLink("Available Shortcuts") {
                    ShortcutsInfoView()
                }
            }
        }
        .navigationTitle("Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Data Export

struct DataExportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var exportFormat: ExportFormat = .json
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Export Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Format")
                }

                Section {
                    Toggle("Include Tasks", isOn: .constant(true))
                    Toggle("Include Events", isOn: .constant(true))
                    Toggle("Include Messages", isOn: .constant(true))
                    Toggle("Include Files", isOn: .constant(true))
                } header: {
                    Text("Data to Export")
                }

                Section {
                    Button(action: exportData) {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                            } else {
                                Text("Export Data")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                } footer: {
                    Text("Your data will be exported as a \(exportFormat.rawValue) file and can be shared or backed up.")
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportData() {
        isExporting = true
        // Export data logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            dismiss()
        }
    }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"
    case pdf = "PDF"

    var id: String { rawValue }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Last updated: November 2024")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Group {
                    PolicySection(
                        title: "Information We Collect",
                        content: "We collect information you provide directly to us, including your account information, tasks, events, and messages."
                    )

                    PolicySection(
                        title: "How We Use Your Information",
                        content: "We use the information we collect to provide, maintain, and improve our services, including AI features."
                    )

                    PolicySection(
                        title: "Data Security",
                        content: "We implement industry-standard security measures to protect your data."
                    )

                    PolicySection(
                        title: "Your Rights",
                        content: "You have the right to access, update, or delete your personal information at any time."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms of Service

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Last updated: November 2024")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Group {
                    PolicySection(
                        title: "Acceptance of Terms",
                        content: "By accessing and using Cafe, you accept and agree to be bound by these terms."
                    )

                    PolicySection(
                        title: "Use License",
                        content: "Permission is granted to use Cafe for personal and commercial purposes."
                    )

                    PolicySection(
                        title: "User Obligations",
                        content: "You agree to use the service responsibly and in compliance with applicable laws."
                    )

                    PolicySection(
                        title: "Modifications",
                        content: "We reserve the right to modify these terms at any time."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Credits

struct CreditsView: View {
    var body: some View {
        List {
            Section {
                CreditRow(name: "SwiftUI", role: "UI Framework")
                CreditRow(name: "Claude", role: "AI Assistant")
                CreditRow(name: "Open Source Libraries", role: "Various")
            } header: {
                Text("Technologies")
            }

            Section {
                Text("Built as an experimental productivity app. Thanks to the open source community.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreditRow: View {
    let name: String
    let role: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.body)
                .fontWeight(.medium)

            Text(role)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Help

struct SettingsHelpStubView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("Getting Started") {
                    SettingsHelpArticleView(
                        title: "Getting Started",
                        content: "Welcome to Cafe! This guide will help you get started with the app..."
                    )
                }

                NavigationLink("Tasks & Events") {
                    SettingsHelpArticleView(
                        title: "Tasks & Events",
                        content: "Learn how to create and manage tasks and events..."
                    )
                }

                NavigationLink("AI Features") {
                    SettingsHelpArticleView(
                        title: "AI Features",
                        content: "Discover how to use AI assistants and smart features..."
                    )
                }

                NavigationLink("Widgets") {
                    SettingsHelpArticleView(
                        title: "Widgets",
                        content: "Add Cafe widgets to your home screen and lock screen..."
                    )
                }
            } header: {
                Text("Help Topics")
            }

            Section {
                Button(action: contactSupport) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Contact Support")
                    }
                }

                Button(action: openFAQ) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Visit FAQ")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Support")
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func contactSupport() {
        if let url = URL(string: "mailto:support@halext.org") {
            UIApplication.shared.open(url)
        }
    }

    private func openFAQ() {
        if let url = URL(string: "https://halext.org") {
            UIApplication.shared.open(url)
        }
    }
}

struct SettingsHelpArticleView: View {
    let title: String
    let content: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Labs Features") {
    NavigationStack {
        LabsFeaturesView()
    }
}

#Preview("Data Export") {
    DataExportView()
}

#Preview("Help") {
    NavigationStack {
        SettingsHelpStubView()
    }
}
