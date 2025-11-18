//
//  TaskListView.swift
//  Cafe
//
//  Task list view with pull-to-refresh and filtering
//

import SwiftUI

struct TaskListView: View {
    @State private var tasks: [Task] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNewTask = false
    @State private var filterCompleted = false

    private var filteredTasks: [Task] {
        if filterCompleted {
            return tasks.filter { !$0.completed }
        }
        return tasks
    }

    private var completedCount: Int {
        tasks.filter { $0.completed }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading && tasks.isEmpty {
                    ProgressView("Loading tasks...")
                } else if tasks.isEmpty {
                    ContentUnavailableView {
                        SwiftUI.Label("No Tasks", systemImage: "checkmark.circle")
                    } description: {
                        Text("Create your first task to get started")
                    } actions: {
                        Button(action: {
                            showingNewTask = true
                        }) {
                            Text("New Task")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if completedCount > 0 && !filterCompleted {
                            Section {
                                HStack {
                                    Text("\(completedCount) completed")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(action: {
                                        withAnimation {
                                            filterCompleted = true
                                        }
                                    }) {
                                        Text("Hide Completed")
                                    }
                                    .font(.caption)
                                }
                            }
                        }

                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task) {
                                await toggleTask(task)
                            } onDelete: {
                                await deleteTask(task)
                            }
                        }
                    }
                    .refreshable {
                        await loadTasks()
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showingNewTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }

                if filterCompleted {
                    ToolbarItem(placement: .secondaryAction) {
                        Button(action: {
                            withAnimation {
                                filterCompleted = false
                            }
                        }) {
                            Text("Show All")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewTask) {
                NewTaskView { newTask in
                    await createTask(newTask)
                }
            }
            .task {
                await loadTasks()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button(action: {
                    errorMessage = nil
                }) {
                    Text("OK")
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - API Methods

    private func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            tasks = try await APIClient.shared.getTasks()
            isLoading = false
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func toggleTask(_ task: Task) async {
        do {
            let updated = try await APIClient.shared.updateTask(id: task.id, completed: !task.completed)
            // Update local list
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updated
            }
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }

    private func createTask(_ taskCreate: TaskCreate) async {
        do {
            let newTask = try await APIClient.shared.createTask(taskCreate)
            tasks.insert(newTask, at: 0)
            showingNewTask = false
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
        }
    }

    private func deleteTask(_ task: Task) async {
        do {
            try await APIClient.shared.deleteTask(id: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let onToggle: () async -> Void
    let onDelete: () async -> Void

    @State private var isToggling = false

    private func performToggle() {
        let _ = Task { @MainActor in
            isToggling = true
            await onToggle()
            isToggling = false
        }
    }

    private func performDelete() {
        let _ = Task { @MainActor in
            await onDelete()
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completion toggle
            Button(action: performToggle) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.completed ? .green : .gray)
            }
            .buttonStyle(.plain)
            .disabled(isToggling)

            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)

                if let description = task.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Labels
                if !task.labels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(task.labels) { label in
                                LabelBadge(label: label)
                            }
                        }
                    }
                }

                // Due date
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(dueDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(dueDate < Date() && !task.completed ? .red : .secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: performDelete) {
                SwiftUI.Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct LabelBadge: View {
    let label: TaskLabel

    var body: some View {
        Text(label.name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: label.color ?? "#6B7280").opacity(0.2))
            )
            .foregroundColor(Color(hex: label.color ?? "#6B7280"))
    }
}

// MARK: - Helper Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    TaskListView()
        .environment(AppState())
}
