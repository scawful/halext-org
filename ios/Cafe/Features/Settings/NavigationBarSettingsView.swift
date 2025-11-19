//
//  NavigationBarSettingsView.swift
//  Cafe
//
//  Enhanced UI for customizing bottom navigation bar with presets,
//  drag-and-drop, and live preview
//

import SwiftUI

struct NavigationBarSettingsView: View {
    @State private var navManager = NavigationBarManager.shared
    @State private var showingSaveLayout = false
    @State private var customLayoutName = ""
    @State private var selectedPreset: NavigationPreset?
    @State private var showingPresetConfirmation = false
    @State private var customLayouts: [CustomLayout] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Live Preview Section
                livePreviewSection

                // Quick Stats
                quickStatsSection

                // Preset Layouts Section
                presetsSection

                // Custom Layouts Section
                if !customLayouts.isEmpty {
                    customLayoutsSection
                }

                // Active Tabs Section
                activeTabsSection

                // Available Tabs Section
                if !navManager.availableTabs.isEmpty {
                    availableTabsSection
                }

                // Actions Section
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Navigation Bar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            customLayouts = navManager.loadCustomLayouts()
        }
        .alert("Apply Preset", isPresented: $showingPresetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Apply") {
                if let preset = selectedPreset {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        navManager.applyPreset(preset)
                    }
                }
            }
        } message: {
            if let preset = selectedPreset {
                Text("Replace your current layout with '\(preset.name)'?")
            }
        }
        .sheet(isPresented: $showingSaveLayout) {
            SaveLayoutSheet(layoutName: $customLayoutName) { name in
                navManager.saveCustomLayout(name: name)
                customLayouts = navManager.loadCustomLayouts()
                customLayoutName = ""
            }
        }
    }

    // MARK: - Live Preview Section

    private var livePreviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundStyle(.blue)
                Text("Live Preview")
                    .font(.headline)
                Spacer()
            }

            EnhancedTabBarPreview(tabs: navManager.visibleTabs)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            NavStatCard(
                icon: "rectangle.grid.2x2",
                title: "Active",
                value: "\(navManager.visibleTabs.count)",
                color: .blue
            )

            NavStatCard(
                icon: "square.stack.3d.up",
                title: "Available",
                value: "\(navManager.availableTabs.count)",
                color: .green
            )

            NavStatCard(
                icon: "checkmark.seal",
                title: "Max Tabs",
                value: "\(navManager.maxTabs)",
                color: .orange
            )
        }
    }

    // MARK: - Presets Section

    private var presetsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Recommended Layouts")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(NavigationPreset.allPresets) { preset in
                    PresetCard(
                        preset: preset,
                        isActive: isPresetActive(preset)
                    ) {
                        selectedPreset = preset
                        showingPresetConfirmation = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Custom Layouts Section

    private var customLayoutsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(.indigo)
                Text("Custom Layouts")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(customLayouts) { layout in
                    CustomLayoutCard(layout: layout) {
                        // Apply layout
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            navManager.applyCustomLayout(layout)
                        }
                    } onDelete: {
                        // Delete layout
                        navManager.deleteCustomLayout(layout)
                        customLayouts = navManager.loadCustomLayouts()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Active Tabs Section

    private var activeTabsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Active Tabs")
                    .font(.headline)
                Text("(\(navManager.visibleTabs.count)/\(navManager.maxTabs))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text("Drag to reorder. Swipe left to remove. Minimum \(navManager.minTabs) tabs required.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                ForEach(Array(navManager.visibleTabs.enumerated()), id: \.element.id) { index, tab in
                    TabCard(
                        tab: tab,
                        isVisible: true,
                        position: index + 1,
                        canRemove: navManager.visibleTabs.count > navManager.minTabs
                    ) {
                        // Remove tab
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            navManager.removeTab(tab)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Available Tabs Section

    private var availableTabsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundStyle(.blue)
                Text("Available Tabs")
                    .font(.headline)
                Spacer()
            }

            if navManager.visibleTabs.count >= navManager.maxTabs {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Maximum of \(navManager.maxTabs) tabs reached. Remove a tab to add another.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            VStack(spacing: 8) {
                ForEach(navManager.availableTabs) { tab in
                    TabCard(
                        tab: tab,
                        isVisible: false,
                        position: nil,
                        canRemove: false
                    ) {
                        // Add tab
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            navManager.addTab(tab)
                        }
                    }
                    .disabled(navManager.visibleTabs.count >= navManager.maxTabs)
                    .opacity(navManager.visibleTabs.count >= navManager.maxTabs ? 0.5 : 1.0)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingSaveLayout = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Current Layout")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .cornerRadius(12)
            }

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    navManager.resetToDefaults()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset to Default")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func isPresetActive(_ preset: NavigationPreset) -> Bool {
        return navManager.visibleTabs == preset.tabs
    }
}

// MARK: - Enhanced Tab Bar Preview

struct EnhancedTabBarPreview: View {
    let tabs: [NavigationTab]

    var body: some View {
        VStack(spacing: 16) {
            // iPhone mockup with tab bar
            VStack(spacing: 0) {
                // Screen area
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                    .overlay(
                        Text("Your app content")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    )

                // Tab bar
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        VStack(spacing: 6) {
                            Image(systemName: tab.filledIcon)
                                .font(.system(size: 22))
                                .symbolRenderingMode(.hierarchical)

                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(tab.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
                .background(Color(.systemBackground))
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Nav Stat Card

struct NavStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let preset: NavigationPreset
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: preset.icon)
                    .font(.title2)
                    .foregroundStyle(isActive ? .green : .blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isActive ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(preset.name)
                            .font(.body)
                            .fontWeight(.medium)

                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Mini preview
                HStack(spacing: 2) {
                    ForEach(preset.tabs) { tab in
                        Circle()
                            .fill(tab.color.opacity(0.6))
                            .frame(width: 8, height: 8)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Layout Card

struct CustomLayoutCard: View {
    let layout: CustomLayout
    let onApply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.title3)
                .foregroundStyle(.indigo)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.indigo.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(layout.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(layout.tabs.count) tabs • \(layout.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onApply) {
                Text("Apply")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.indigo)
                    .cornerRadius(8)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Tab Card

struct TabCard: View {
    let tab: NavigationTab
    let isVisible: Bool
    let position: Int?
    let canRemove: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Position badge
            if let position = position {
                Text("\(position)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(tab.color))
            } else {
                Image(systemName: tab.filledIcon)
                    .font(.title3)
                    .foregroundStyle(tab.color)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tab.rawValue)
                    .font(.body)
                    .fontWeight(.medium)

                Text(tab.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Color indicator
            Circle()
                .fill(tab.color.opacity(0.3))
                .frame(width: 12, height: 12)

            if isVisible {
                if canRemove {
                    Button(action: action) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.red)
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isVisible ? tab.color.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Save Layout Sheet

struct SaveLayoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var layoutName: String
    let onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Layout Name", text: $layoutName)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your custom layout a descriptive name")
                }
            }
            .navigationTitle("Save Layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(layoutName)
                        dismiss()
                    }
                    .disabled(layoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NavigationBarSettingsView()
    }
}
