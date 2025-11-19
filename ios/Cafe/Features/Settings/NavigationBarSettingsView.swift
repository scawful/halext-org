//
//  NavigationBarSettingsView.swift
//  Cafe
//
//  UI for customizing bottom navigation bar
//

import SwiftUI

struct NavigationBarSettingsView: View {
    @State private var navManager = NavigationBarManager.shared
    @State private var showingAddTab = false

    var body: some View {
        List {
            // Current Tabs
            Section {
                ForEach(navManager.visibleTabs) { tab in
                    HStack {
                        Image(systemName: tab.icon)
                            .font(.title3)
                            .foregroundColor(tab.color)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(tab.rawValue)
                                .font(.body)

                            Text(tab.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onMove { source, destination in
                    navManager.moveTab(from: source, to: destination)
                }
                .onDelete { offsets in
                    for index in offsets {
                        let tab = navManager.visibleTabs[index]
                        navManager.removeTab(tab)
                    }
                }
            } header: {
                Text("Active Tabs (\(navManager.visibleTabs.count)/\(navManager.maxTabs))")
            } footer: {
                Text("Drag to reorder tabs. Minimum \(navManager.minTabs) tabs required.")
            }

            // Available Tabs
            if !navManager.availableTabs.isEmpty {
                Section {
                    ForEach(navManager.availableTabs) { tab in
                        Button(action: {
                            navManager.addTab(tab)
                        }) {
                            HStack {
                                Image(systemName: tab.icon)
                                    .font(.title3)
                                    .foregroundColor(tab.color)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tab.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(tab.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 4)
                        }
                        .disabled(navManager.visibleTabs.count >= navManager.maxTabs)
                    }
                } header: {
                    Text("Available Tabs")
                } footer: {
                    if navManager.visibleTabs.count >= navManager.maxTabs {
                        Text("Maximum of \(navManager.maxTabs) tabs reached. Remove a tab to add another.")
                    }
                }
            }

            // Actions
            Section {
                Button("Reset to Default") {
                    navManager.resetToDefaults()
                }
                .foregroundColor(.blue)
            } header: {
                Text("Actions")
            } footer: {
                Text("Reset to default tab configuration: Dashboard, Tasks, Calendar, AI Chat, and Settings")
            }

            // Preview
            Section {
                TabBarPreview(tabs: navManager.visibleTabs)
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Navigation Bar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
    }
}

// MARK: - Tab Bar Preview

struct TabBarPreview: View {
    let tabs: [NavigationTab]

    var body: some View {
        VStack(spacing: 8) {
            Text("Bottom Navigation Preview")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))

                        Text(tab.rawValue)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(tab.color.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Tab Detail Row

struct TabDetailRow: View {
    let tab: NavigationTab
    let isVisible: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: tab.icon)
                .font(.title3)
                .foregroundColor(tab.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(tab.rawValue)
                    .font(.body)

                Text(tab.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isVisible {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NavigationBarSettingsView()
    }
}
