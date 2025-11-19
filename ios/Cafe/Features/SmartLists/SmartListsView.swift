//
//  SmartListsView.swift
//  Cafe
//
//  UI for managing smart lists
//

import SwiftUI
import SwiftData

struct SmartListsView: View {
    @State private var listManager = SmartListManager.shared
    @State private var searchText = ""
    @State private var showingNewList = false
    @State private var selectedList: SmartList?

    @Query private var taskModels: [TaskModel]

    var tasks: [Task] {
        taskModels.map { $0.toTask() }
    }

    var filteredLists: [SmartList] {
        listManager.searchLists(query: searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                // Built-in Lists
                Section {
                    ForEach(SmartList.builtInLists) { list in
                        NavigationLink(value: list) {
                            SmartListRow(list: list, tasks: tasks)
                        }
                    }
                } header: {
                    Text("Built-in Lists")
                } footer: {
                    Text("Pre-configured smart lists for common views")
                }

                // Custom Lists
                if !listManager.customLists.isEmpty {
                    Section {
                        ForEach(listManager.customLists) { list in
                            NavigationLink(value: list) {
                                SmartListRow(list: list, tasks: tasks)
                            }
                        }
                        .onDelete { offsets in
                            listManager.deleteLists(at: Array(offsets))
                        }
                    } header: {
                        Text("Custom Lists")
                    } footer: {
                        Text("Your custom filtered views")
                    }
                }

                // Statistics
                Section {
                    LabeledContent("Total Lists", value: "\(listManager.listCount)")
                    LabeledContent("Custom Lists", value: "\(listManager.customListCount)")
                    LabeledContent("Total Tasks", value: "\(tasks.count)")
                } header: {
                    Text("Statistics")
                }
            }
            .navigationTitle("Smart Lists")
            .navigationDestination(for: SmartList.self) { list in
                SmartListDetailView(list: list, tasks: tasks)
            }
            .searchable(text: $searchText, prompt: "Search smart lists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewList = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewList) {
                SmartListEditorView(list: nil)
            }
        }
    }

    private func countTasks(for list: SmartList) -> Int {
        list.filter(tasks: tasks).count
    }
}

// MARK: - Smart List Row

struct SmartListRow: View {
    let list: SmartList
    let tasks: [Task]

    var filteredTasks: [Task] {
        list.filter(tasks: tasks)
    }

    var completedCount: Int {
        filteredTasks.filter { $0.completed }.count
    }

    var totalCount: Int {
        filteredTasks.count
    }

    var body: some View {
        HStack(spacing: 12) {
            // Progress Wheel
            MiniProgressWheel(
                completed: completedCount,
                total: totalCount,
                foregroundColor: colorFromString(list.color)
            )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    if !list.filters.isEmpty {
                        Text("\(list.filters.count) filter(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if list.groupBy != nil {
                        Text("• Grouped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Task count badge
            Text("\(totalCount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorFromString(list.color))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Smart List Detail View

struct SmartListDetailView: View {
    let list: SmartList
    let tasks: [Task]

    @Environment(\.dismiss) var dismiss
    @State private var showingEditor = false
    @State private var listManager = SmartListManager.shared

    var filteredTasks: [Task] {
        list.filter(tasks: tasks)
    }

    var groupedTasks: [(String, [Task])] {
        list.group(tasks: filteredTasks)
    }

    var body: some View {
        List {
            // Summary
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: list.icon)
                            .font(.title)
                            .foregroundColor(colorFromString(list.color))

                        VStack(alignment: .leading) {
                            Text(list.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("\(filteredTasks.count) tasks")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        ProgressWheel(
                            completed: filteredTasks.filter { $0.completed }.count,
                            total: filteredTasks.count,
                            size: 60,
                            foregroundColor: colorFromString(list.color)
                        )
                    }

                    // Progress bar
                    if filteredTasks.count > 0 {
                        ProgressBar(
                            completed: filteredTasks.filter { $0.completed }.count,
                            total: filteredTasks.count,
                            foregroundColor: colorFromString(list.color)
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            // Active Filters
            if !list.filters.isEmpty {
                Section {
                    ForEach(list.filters, id: \.self) { filter in
                        Label(filter.displayName, systemImage: filter.icon)
                    }
                } header: {
                    Text("Active Filters")
                }
            }

            // Tasks (grouped or flat)
            if list.groupBy != nil {
                ForEach(groupedTasks, id: \.0) { groupName, groupTasks in
                    Section {
                        ForEach(groupTasks) { task in
                            SmartListTaskRowView(task: task)
                        }
                    } header: {
                        Text(groupName)
                    }
                }
            } else {
                Section {
                    ForEach(filteredTasks) { task in
                        SmartListTaskRowView(task: task)
                    }
                } header: {
                    Text("Tasks")
                }
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Only show edit for custom lists
            if !SmartList.builtInLists.contains(where: { $0.id == list.id }) {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingEditor = true }) {
                        Text("Edit")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            SmartListEditorView(list: list)
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Simple Task Row

struct SmartListTaskRowView: View {
    let task: Task

    var body: some View {
        HStack {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completed ? .green : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.completed)

                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    SmartListsView()
        .modelContainer(StorageManager.shared.modelContainer)
}
