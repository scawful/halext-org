//
//  LayoutPresetsView.swift
//  Cafe
//
//  Layout presets management and custom layout saving
//

import SwiftUI

struct LayoutPresetsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var layoutManager = DashboardLayoutManager.shared
    @State private var showingSaveDialog = false
    @State private var newLayoutName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in Presets") {
                    ForEach(DashboardLayout.allPresets) { preset in
                        LayoutPresetRow(
                            layout: preset,
                            isActive: layoutManager.currentLayout.name == preset.name
                        ) {
                            layoutManager.applyPreset(preset)
                            dismiss()
                        }
                    }
                }

                if !layoutManager.savedLayouts.isEmpty {
                    Section("My Layouts") {
                        ForEach(layoutManager.savedLayouts) { layout in
                            LayoutPresetRow(
                                layout: layout,
                                isActive: layoutManager.currentLayout.id == layout.id
                            ) {
                                layoutManager.loadLayout(layout)
                                dismiss()
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    layoutManager.deleteLayout(layout)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingSaveDialog = true
                    } label: {
                        Label("Save Current Layout", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .navigationTitle("Layout Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Save Layout", isPresented: $showingSaveDialog) {
                TextField("Layout Name", text: $newLayoutName)
                Button("Cancel", role: .cancel) {
                    newLayoutName = ""
                }
                Button("Save") {
                    if !newLayoutName.isEmpty {
                        layoutManager.saveLayoutAs(name: newLayoutName)
                        newLayoutName = ""
                    }
                }
            } message: {
                Text("Give your custom layout a name")
            }
        }
    }
}

// MARK: - Layout Preset Row

struct LayoutPresetRow: View {
    let layout: DashboardLayout
    let isActive: Bool
    let action: () -> Void
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(layout.name)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)

                    Text("\(layout.cards.count) cards")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)

                    if !layout.isDefault {
                        Text("Created \(layout.createdAt, style: .date)")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LayoutPresetsView()
}
