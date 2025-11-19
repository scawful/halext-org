//
//  SmartListEditorView.swift
//  Cafe
//
//  Editor for creating and modifying smart lists
//

import SwiftUI

struct SmartListEditorView: View {
    let list: SmartList?
    @Environment(\.dismiss) var dismiss
    @State private var listManager = SmartListManager.shared

    // Form fields
    @State private var name: String
    @State private var icon: String
    @State private var color: String
    @State private var filters: [TaskFilter]
    @State private var sortOrder: TaskSortOrder
    @State private var groupBy: TaskGrouping?

    // UI state
    @State private var showingAddFilter = false
    @State private var showingIconPicker = false

    init(list: SmartList?) {
        self.list = list

        // Initialize with existing list or defaults
        _name = State(initialValue: list?.name ?? "")
        _icon = State(initialValue: list?.icon ?? "line.3.horizontal.decrease.circle")
        _color = State(initialValue: list?.color ?? "blue")
        _filters = State(initialValue: list?.filters ?? [])
        _sortOrder = State(initialValue: list?.sortOrder ?? .dueDate)
        _groupBy = State(initialValue: list?.groupBy)
    }

    var isValid: Bool {
        !name.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section {
                    TextField("List Name", text: $name)

                    HStack {
                        Text("Icon")
                        Spacer()
                        Button(action: { showingIconPicker = true }) {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(colorFromString(color))
                                Text(icon)
                                    .foregroundColor(.secondary)
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
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Basic Info")
                }

                // Filters
                Section {
                    if filters.isEmpty {
                        Text("No filters added - will show all tasks")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                            HStack {
                                Image(systemName: filter.icon)
                                    .foregroundColor(.blue)
                                Text(filter.displayName)

                                Spacer()

                                Button(role: .destructive, action: {
                                    filters.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button(action: { showingAddFilter = true }) {
                        Label("Add Filter", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Filters")
                } footer: {
                    Text("Tasks must match ALL filters to appear in this list")
                }

                // Sort & Group
                Section {
                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(TaskSortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }

                    Picker("Group By", selection: $groupBy) {
                        Text("None").tag(nil as TaskGrouping?)
                        ForEach(TaskGrouping.allCases, id: \.self) { grouping in
                            Text(grouping.rawValue).tag(grouping as TaskGrouping?)
                        }
                    }
                } header: {
                    Text("Display Options")
                }
            }
            .navigationTitle(list == nil ? "New Smart List" : "Edit Smart List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveList()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingAddFilter) {
                FilterPickerView(filters: $filters)
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $icon)
            }
        }
    }

    private func saveList() {
        let newList = SmartList(
            id: list?.id ?? UUID(),
            name: name,
            icon: icon,
            color: color,
            filters: filters,
            sortOrder: sortOrder,
            groupBy: groupBy
        )

        if list != nil {
            listManager.updateList(newList)
        } else {
            listManager.addList(newList)
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

// MARK: - Filter Picker

struct FilterPickerView: View {
    @Binding var filters: [TaskFilter]
    @Environment(\.dismiss) var dismiss

    @State private var selectedFilterType: FilterType = .dueToday
    @State private var labelName = ""

    enum FilterType: String, CaseIterable {
        case dueToday = "Due Today"
        case dueThisWeek = "Due This Week"
        case overdue = "Overdue"
        case noDueDate = "No Due Date"
        case completed = "Completed"
        case incomplete = "Incomplete"
        case hasDescription = "Has Description"
        case noDescription = "No Description"
        case createdToday = "Created Today"
        case createdThisWeek = "Created This Week"
        case label = "Has Label"

        var filter: TaskFilter {
            switch self {
            case .dueToday: return .dueToday
            case .dueThisWeek: return .dueThisWeek
            case .overdue: return .overdue
            case .noDueDate: return .noDueDate
            case .completed: return .completed
            case .incomplete: return .incomplete
            case .hasDescription: return .hasDescription
            case .noDescription: return .noDescription
            case .createdToday: return .createdToday
            case .createdThisWeek: return .createdThisWeek
            case .label: return .label("") // Will be replaced with actual label
            }
        }

        var icon: String {
            switch self {
            case .dueToday: return "calendar"
            case .dueThisWeek: return "calendar.badge.clock"
            case .overdue: return "exclamationmark.triangle"
            case .noDueDate: return "calendar.badge.minus"
            case .completed: return "checkmark.circle"
            case .incomplete: return "circle"
            case .hasDescription: return "doc.text"
            case .noDescription: return "doc"
            case .createdToday: return "sparkles"
            case .createdThisWeek: return "clock"
            case .label: return "tag"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Filter Type", selection: $selectedFilterType) {
                        ForEach(FilterType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Filter Type")
                }

                if selectedFilterType == .label {
                    Section {
                        TextField("Label Name", text: $labelName)
                    } header: {
                        Text("Label")
                    } footer: {
                        Text("Enter the label name to filter by")
                    }
                }

                Section {
                    Button(action: addFilter) {
                        Text("Add Filter")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedFilterType == .label && labelName.isEmpty)
                } footer: {
                    if selectedFilterType == .label {
                        Text("Tasks with the label '\(labelName)' will be included")
                    } else {
                        Text(filterDescription(for: selectedFilterType))
                    }
                }
            }
            .navigationTitle("Add Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addFilter() {
        let filter: TaskFilter
        if selectedFilterType == .label {
            filter = .label(labelName.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            filter = selectedFilterType.filter
        }

        filters.append(filter)
        dismiss()
    }

    private func filterDescription(for type: FilterType) -> String {
        switch type {
        case .dueToday: return "Tasks due today"
        case .dueThisWeek: return "Tasks due within 7 days"
        case .overdue: return "Incomplete tasks past their due date"
        case .noDueDate: return "Tasks without a due date"
        case .completed: return "Completed tasks"
        case .incomplete: return "Incomplete tasks"
        case .hasDescription: return "Tasks with a description"
        case .noDescription: return "Tasks without a description"
        case .createdToday: return "Tasks created today"
        case .createdThisWeek: return "Tasks created in the last 7 days"
        case .label: return "Tasks with a specific label"
        }
    }
}

// MARK: - Preview

#Preview {
    SmartListEditorView(list: nil)
}
