//
//  SharedTasksView.swift
//  Cafe
//
//  View for managing shared tasks (DEPRECATED - CloudKit-only feature)
//  Use regular tasks with Social Circles for backend-powered collaboration
//

import SwiftUI

struct SharedTasksView: View {
    @State private var socialManager = SocialManager.shared
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingNewTask = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case myTasks = "My Tasks"
        case partnerTasks = "Partner's"
        case unassigned = "Unassigned"
        case completed = "Completed"

        var icon: String {
            switch self {
            case .all:
                return "list.bullet"
            case .myTasks:
                return "person.fill"
            case .partnerTasks:
                return "person.2.fill"
            case .unassigned:
                return "circle"
            case .completed:
                return "checkmark.circle.fill"
            }
        }
    }

    var filteredTasks: [SharedTask] {
        let currentProfileId = socialManager.currentProfile?.id

        switch selectedFilter {
        case .all:
            return socialManager.sharedTasks.filter { !$0.completed }
        case .myTasks:
            return socialManager.sharedTasks.filter {
                $0.assignedToProfileId == currentProfileId && !$0.completed
            }
        case .partnerTasks:
            return socialManager.sharedTasks.filter {
                $0.assignedToProfileId != currentProfileId &&
                $0.assignedToProfileId != nil &&
                !$0.completed
            }
        case .unassigned:
            return socialManager.sharedTasks.filter {
                $0.assignedToProfileId == nil && !$0.completed
            }
        case .completed:
            return socialManager.sharedTasks.filter { $0.completed }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(uiColor: .systemBackground))

                Divider()

                // Tasks List
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTasks.isEmpty {
                    SharedTasksEmptyStateView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            SharedTaskRow(task: task)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTask(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        toggleTaskCompletion(task)
                                    } label: {
                                        Label(
                                            task.completed ? "Uncomplete" : "Complete",
                                            systemImage: task.completed ? "xmark.circle" : "checkmark.circle"
                                        )
                                    }
                                    .tint(task.completed ? .orange : .green)
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Shared Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewTask = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshTasks) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingNewTask) {
                NewSharedTaskView()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
            .task {
                await loadSharedTasks()
            }
            .refreshable {
                await loadSharedTasks()
            }
        }
    }

    // MARK: - Actions

    private func loadSharedTasks() async {
        isLoading = true

        do {
            try await socialManager.fetchSharedTasks()
            isLoading = false
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func refreshTasks() {
        _Concurrency.Task {
            await loadSharedTasks()
        }
    }

    private func toggleTaskCompletion(_ task: SharedTask) {
        var updatedTask = task
        updatedTask = SharedTask(
            id: task.id,
            taskId: task.taskId,
            title: task.title,
            description: task.description,
            completed: !task.completed,
            dueDate: task.dueDate,
            assignedToProfileId: task.assignedToProfileId,
            createdByProfileId: task.createdByProfileId,
            connectionId: task.connectionId,
            labels: task.labels,
            createdAt: task.createdAt,
            updatedAt: Date(),
            completedAt: !task.completed ? Date() : nil,
            completedByProfileId: !task.completed ? socialManager.currentProfile?.id : nil
        )

        _Concurrency.Task {
            do {
                try await socialManager.updateSharedTask(updatedTask)
            } catch {
                errorMessage = "Failed to update task: \(error.localizedDescription)"
            }
        }
    }

    private func deleteTask(_ task: SharedTask) {
        // Optimistically remove from local list for immediate UI feedback
        if let index = socialManager.sharedTasks.firstIndex(where: { $0.id == task.id }) {
            socialManager.sharedTasks.remove(at: index)
        }

        // Delete from CloudKit
        _Concurrency.Task {
            do {
                try await socialManager.deleteSharedTask(task)
            } catch {
                // Restore task on failure
                socialManager.sharedTasks.append(task)
                errorMessage = "Failed to delete task: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Shared Task Row

struct SharedTaskRow: View {
    let task: SharedTask
    @State private var socialManager = SocialManager.shared

    var assignedProfile: SocialProfile? {
        guard let assignedId = task.assignedToProfileId else {
            return nil
        }
        return socialManager.partnerProfiles[assignedId] ?? socialManager.currentProfile
    }

    var creatorProfile: SocialProfile? {
        socialManager.partnerProfiles[task.createdByProfileId] ?? socialManager.currentProfile
    }

    var isAssignedToMe: Bool {
        task.assignedToProfileId == socialManager.currentProfile?.id
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completion Circle
            Button(action: {}) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.completed ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)

                // Description
                if let description = task.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Metadata
                HStack(spacing: 8) {
                    // Assignment
                    if let assigned = assignedProfile {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text(assigned.username)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isAssignedToMe ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(isAssignedToMe ? .blue : .orange)
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "circle")
                                .font(.caption2)
                            Text("Unassigned")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(8)
                    }

                    // Due Date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate.formatted(.dateTime.month().day()))
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                    }
                }

                // Completion Info
                if task.completed, let completedBy = task.completedByProfileId {
                    let completerProfile = socialManager.partnerProfiles[completedBy] ?? socialManager.currentProfile

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("Completed by \(completerProfile?.username ?? "Unknown")")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }

            Spacer()

            // Task Options
            Menu {
                if !task.completed {
                    Menu {
                        Button {
                            assignTask(to: nil)
                        } label: {
                            Label("Unassign", systemImage: "circle")
                        }

                        if let profile = socialManager.currentProfile {
                            Button {
                                assignTask(to: profile.id)
                            } label: {
                                Label("Assign to Me", systemImage: "person.fill")
                            }
                        }

                        ForEach(Array(socialManager.partnerProfiles.values), id: \.id) { partner in
                            Button {
                                assignTask(to: partner.id)
                            } label: {
                                Label("Assign to \(partner.username)", systemImage: "person.2.fill")
                            }
                        }
                    } label: {
                        Label("Assign", systemImage: "person.crop.circle.badge.plus")
                    }
                }

                Button(role: .destructive) {
                    // Delete action
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func assignTask(to profileId: String?) {
        var updatedTask = task
        updatedTask = SharedTask(
            id: task.id,
            taskId: task.taskId,
            title: task.title,
            description: task.description,
            completed: task.completed,
            dueDate: task.dueDate,
            assignedToProfileId: profileId,
            createdByProfileId: task.createdByProfileId,
            connectionId: task.connectionId,
            labels: task.labels,
            createdAt: task.createdAt,
            updatedAt: Date()
        )

        _Concurrency.Task {
            do {
                try await socialManager.updateSharedTask(updatedTask)
            } catch {
                print("Failed to assign task: \(error)")
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct SharedTasksEmptyStateView: View {
    let filter: SharedTasksView.TaskFilter

    var message: String {
        switch filter {
        case .all:
            return "No shared tasks yet.\nCreate one to get started!"
        case .myTasks:
            return "No tasks assigned to you"
        case .partnerTasks:
            return "No tasks assigned to your partner"
        case .unassigned:
            return "No unassigned tasks"
        case .completed:
            return "No completed tasks yet"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - New Shared Task View

struct NewSharedTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var socialManager = SocialManager.shared

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var assignedToProfileId: String?

    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                        .textInputAutocapitalization(.sentences)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3...6)
                } header: {
                    Text("Task Details")
                }

                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                } header: {
                    Text("Schedule")
                }

                Section {
                    Picker("Assign To", selection: $assignedToProfileId) {
                        Text("Unassigned").tag(nil as String?)

                        if let profile = socialManager.currentProfile {
                            Text("Me (\(profile.username))").tag(profile.id as String?)
                        }

                        ForEach(Array(socialManager.partnerProfiles.values), id: \.id) { partner in
                            Text(partner.username).tag(partner.id as String?)
                        }
                    }
                } header: {
                    Text("Assignment")
                }
            }
            .navigationTitle("New Shared Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(title.isEmpty || isCreating)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") {
                    errorMessage = nil
                }
            } message: { message in
                Text(message)
            }
        }
    }

    private func createTask() {
        isCreating = true

        _Concurrency.Task {
            do {
                // Create task in backend first
                let taskCreate = TaskCreate(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    dueDate: hasDueDate ? dueDate : nil,
                    labels: ["shared"]
                )

                let createdTask = try await APIClient.shared.createTask(taskCreate)

                // Create shared task in CloudKit
                _ = try await socialManager.createSharedTask(
                    createdTask,
                    assignedTo: assignedToProfileId
                )

                isCreating = false
                dismiss()
            } catch {
                errorMessage = "Failed to create task: \(error.localizedDescription)"
                isCreating = false
            }
        }
    }
}

#Preview {
    SharedTasksView()
}
