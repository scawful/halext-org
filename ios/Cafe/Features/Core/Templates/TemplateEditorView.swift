//
//  TemplateEditorView.swift
//  Cafe
//
//  Editor for creating and modifying task templates
//

import SwiftUI

struct TemplateEditorView: View {
    let template: TaskTemplate?
    @Environment(\.dismiss) var dismiss
    @State private var templateManager = TaskTemplateManager.shared

    // Form fields
    @State private var name: String
    @State private var icon: String
    @State private var color: String
    @State private var titleTemplate: String
    @State private var descriptionTemplate: String
    @State private var defaultLabels: [String]
    @State private var defaultDueDays: Int?
    @State private var defaultPriority: TaskPriority?
    @State private var checklist: [ChecklistItem]

    // UI state
    @State private var newLabel = ""
    @State private var newChecklistItem = ""
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false

    init(template: TaskTemplate?) {
        self.template = template

        // Initialize with existing template or defaults
        _name = State(initialValue: template?.name ?? "")
        _icon = State(initialValue: template?.icon ?? "doc.text")
        _color = State(initialValue: template?.color ?? "blue")
        _titleTemplate = State(initialValue: template?.titleTemplate ?? "")
        _descriptionTemplate = State(initialValue: template?.descriptionTemplate ?? "")
        _defaultLabels = State(initialValue: template?.defaultLabels ?? [])
        _defaultDueDays = State(initialValue: template?.defaultDueDays)
        _defaultPriority = State(initialValue: template?.defaultPriority)
        _checklist = State(initialValue: template?.checklist ?? [])
    }

    var isValid: Bool {
        !name.isEmpty && !titleTemplate.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("Template Name", text: $name)

                    HStack {
                        Text("Icon")
                        Spacer()
                        Button(action: { showingIconPicker = true }) {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(colorFromString(color))
                                        Text(icon)
                                    .themedSecondaryText()
                            }
                        }
                    }

                    HStack {
                        Text("Color")
                        Spacer()
                        Menu {
                            ForEach(availableColors, id: \.name) { colorOption in
                                Button(action: { color = colorOption.name }) {
                                    Label(colorOption.name.capitalized, systemImage: "circle.fill")
                                        .foregroundColor(colorOption.color)
                                }
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 20, height: 20)
                                Text(color.capitalized)
                                    .themedSecondaryText()
                            }
                        }
                    }
                } header: {
                    Text("Basic Info")
                }

                // Template Content
                Section {
                    TextField("Title Template", text: $titleTemplate)

                    VStack(alignment: .leading) {
                        Text("Description Template")
                            .font(.caption)
                            .themedSecondaryText()

                        TextEditor(text: $descriptionTemplate)
                            .frame(minHeight: 100)
                            .themedCardBackground(cornerRadius: 8, shadow: false)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Content")
                }

                // Default Settings
                Section {
                    Picker("Priority", selection: $defaultPriority) {
                        Text("None").tag(nil as TaskPriority?)
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Label(priority.rawValue, systemImage: priority.icon)
                                .tag(priority as TaskPriority?)
                        }
                    }

                    HStack {
                        Text("Due In")
                        Spacer()
                        TextField("Days", value: $defaultDueDays, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("days")
                            .themedSecondaryText()
                    }
                } header: {
                    Text("Default Settings")
                }

                // Labels
                Section {
                    ForEach(defaultLabels, id: \.self) { label in
                        HStack {
                            Text(label)
                            Spacer()
                            Button(role: .destructive, action: {
                                defaultLabels.removeAll { $0 == label }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack {
                        TextField("Add label", text: $newLabel)
                        Button(action: addLabel) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newLabel.isEmpty)
                    }
                } header: {
                    Text("Labels")
                } footer: {
                    Text("Add default labels for tasks created from this template")
                }

                // Checklist
                Section {
                    ForEach(checklist) { item in
                        HStack {
                            Image(systemName: "circle")
                                .themedSecondaryText()
                            Text(item.title)
                            Spacer()
                            Button(role: .destructive, action: {
                                checklist.removeAll { $0.id == item.id }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { from, to in
                        checklist.move(fromOffsets: from, toOffset: to)
                    }

                    HStack {
                        TextField("Add checklist item", text: $newChecklistItem)
                        Button(action: addChecklistItem) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newChecklistItem.isEmpty)
                    }
                } header: {
                    Text("Checklist")
                } footer: {
                    Text("Add default checklist items for this template")
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $icon)
            }
        }
    }

    private func saveTemplate() {
        let newTemplate = TaskTemplate(
            id: template?.id ?? UUID(),
            name: name,
            icon: icon,
            color: color,
            titleTemplate: titleTemplate,
            descriptionTemplate: descriptionTemplate.isEmpty ? nil : descriptionTemplate,
            defaultLabels: defaultLabels,
            defaultDueDays: defaultDueDays,
            defaultPriority: defaultPriority,
            checklist: checklist
        )

        if template != nil {
            templateManager.updateTemplate(newTemplate)
        } else {
            templateManager.addTemplate(newTemplate)
        }
    }

    private func addLabel() {
        let trimmed = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !defaultLabels.contains(trimmed) {
            defaultLabels.append(trimmed)
            newLabel = ""
        }
    }

    private func addChecklistItem() {
        let trimmed = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            checklist.append(ChecklistItem(title: trimmed))
            newChecklistItem = ""
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        availableColors.first { $0.name == colorName }?.color ?? .blue
    }

    private var availableColors: [(name: String, color: Color)] {
        [
            ("blue", .blue),
            ("red", .red),
            ("green", .green),
            ("orange", .orange),
            ("purple", .purple),
            ("pink", .pink),
            ("teal", .teal),
            ("indigo", .indigo),
            ("yellow", .yellow),
            ("gray", .gray)
        ]
    }
}

// MARK: - Icon Picker

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    @Environment(ThemeManager.self) var themeManager

    let commonIcons = [
        "doc.text", "folder", "calendar", "clock", "bell",
        "person", "person.3", "envelope", "phone", "message",
        "cart", "bag", "creditcard", "wrench", "hammer",
        "paintbrush", "book", "graduationcap", "sportscourt", "figure.run",
        "heart", "star", "flag", "bookmark", "tag",
        "house", "building", "car", "airplane", "location",
        "globe", "map", "camera", "photo", "film",
        "music.note", "headphones", "gamecontroller", "tv", "desktopcomputer",
        "laptopcomputer", "iphone", "server.rack", "wifi", "antenna.radiowaves.left.and.right",
        "bolt", "flame", "drop", "sun.max", "moon",
        "cloud", "umbrella", "snowflake", "wind", "tornado",
        "ant", "ladybug", "sparkles", "wand.and.stars", "gift",
        "party.popper", "balloon", "trophy", "medal", "crown",
        "shield", "lock", "key", "checkmark", "xmark"
    ]

    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(commonIcons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? themeManager.accentColor : themeManager.textColor)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? themeManager.accentColor.opacity(0.2) : themeManager.secondaryTextColor.opacity(0.1))
                                    )

                                Text(icon)
                                    .font(.caption2)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .lineLimit(1)
                                    .frame(width: 60)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TemplateEditorView(template: nil)
}
