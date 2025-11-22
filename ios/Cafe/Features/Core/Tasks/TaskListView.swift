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
    @State private var showingRecipeGenerator = false
    @State private var selectedTaskForRecipes: Task?

    // iPad Inspector support
    @State private var showInspector = false
    @State private var inspectorTask: Task?

    // Offline support
    @State private var syncManager = SyncManager.shared
    @State private var networkMonitor = NetworkMonitor.shared

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
            mainContent
                .navigationTitle("Tasks")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingNewTask) {
                    newTaskSheet
                }
                .sheet(isPresented: $showingRecipeGenerator) {
                    recipeGeneratorSheet
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
                .inspector(isPresented: $showInspector) {
                    inspectorContent
                }
                .inspectorColumnWidth(min: 280, ideal: 320, max: 400)
                .onChange(of: inspectorTask?.id) { _, newValue in
                    showInspector = newValue != nil
                }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if isLoading && tasks.isEmpty {
                ProgressView("Loading tasks...")
            } else if tasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }
        }
    }

    private var emptyStateView: some View {
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
    }

    private var taskListView: some View {
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
                TaskRowView(task: task, isSelected: inspectorTask?.id == task.id) {
                    await toggleTask(task)
                } onDelete: {
                    await deleteTask(task)
                } onGenerateRecipe: {
                    selectedTaskForRecipes = task
                    showingRecipeGenerator = true
                } onSelect: {
                    inspectorTask = task
                }
            }
        }
        .refreshable {
            await loadTasks()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                showingNewTask = true
            }) {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add new task")
            .accessibilityHint("Opens a form to create a new task")
        }

        ToolbarItem(placement: .status) {
            offlineIndicator
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
                .accessibilityLabel("Show all tasks")
                .accessibilityHint("Shows completed and pending tasks")
            }
        }

        ToolbarItem(placement: .secondaryAction) {
            Button(action: {
                withAnimation {
                    showInspector.toggle()
                }
            }) {
                SwiftUI.Label(
                    showInspector ? "Hide Inspector" : "Show Inspector",
                    systemImage: "sidebar.trailing"
                )
            }
            .accessibilityLabel(showInspector ? "Hide task inspector" : "Show task inspector")
            .accessibilityHint("Toggles the task details panel on iPad")
        }
    }

    private var offlineIndicator: some View {
        HStack(spacing: 4) {
            if !networkMonitor.isConnected {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)
                Text("Offline")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if syncManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
                    .accessibilityHidden(true)
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let lastSync = syncManager.lastSyncDate {
                Text("Synced \(lastSync, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(offlineStatusAccessibilityLabel)
    }

    private var offlineStatusAccessibilityLabel: String {
        if !networkMonitor.isConnected {
            return "Offline mode. Changes will sync when connected."
        } else if syncManager.isSyncing {
            return "Syncing data with server"
        } else if let lastSync = syncManager.lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        }
        return "Sync status unknown"
    }

    private var newTaskSheet: some View {
        NewTaskView { newTask in
            await createTask(newTask)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var recipeGeneratorSheet: some View {
        RecipeGeneratorFromTaskView(task: selectedTaskForRecipes)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }

    private var inspectorContent: some View {
        TaskInspectorContent(
            task: inspectorTask,
            onToggle: { task in
                _Concurrency.Task {
                    await toggleTask(task)
                }
            },
            onDelete: { task in
                _Concurrency.Task {
                    await deleteTask(task)
                    inspectorTask = nil
                }
            }
        )
    }

    // MARK: - Data Loading (Offline-First)

    private func loadTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // First, load from local cache (fast)
            tasks = try syncManager.loadTasksFromCache()
            isLoading = false

            // Then sync with server if online
            if networkMonitor.isConnected {
                await syncManager.syncAll()
                // Reload from cache after sync
                tasks = try syncManager.loadTasksFromCache()
            }
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func toggleTask(_ task: Task) async {
        do {
            let newCompletedStatus = !task.completed

            if networkMonitor.isConnected {
                // Online: update via API
                let updated = try await APIClient.shared.updateTask(id: task.id, completed: newCompletedStatus)
                try? StorageManager.shared.updateTask(updated)

                // Update local list with animation
                withAnimation(.spring(response: 0.3)) {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        tasks[index] = updated
                    }
                }
            } else {
                // Offline: queue for sync
                try await syncManager.updateTaskOffline(id: task.id, completed: newCompletedStatus)

                // Update local list optimistically
                withAnimation(.spring(response: 0.3)) {
                    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                        // Create updated task
                        let updatedTask = Task(
                            id: task.id,
                            title: task.title,
                            description: task.description,
                            completed: newCompletedStatus,
                            dueDate: task.dueDate,
                            createdAt: task.createdAt,
                            ownerId: task.ownerId,
                            labels: task.labels
                        )
                        tasks[index] = updatedTask
                    }
                }
            }
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }

    private func createTask(_ taskCreate: TaskCreate) async {
        do {
            let newTask: Task

            if networkMonitor.isConnected {
                // Online: create via API
                newTask = try await APIClient.shared.createTask(taskCreate)
                try? StorageManager.shared.saveTask(newTask)
            } else {
                // Offline: create locally and queue for sync
                newTask = try await syncManager.createTaskOffline(taskCreate)
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                tasks.insert(newTask, at: 0)
            }
            showingNewTask = false
            HapticManager.success()
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
        }
    }

    private func deleteTask(_ task: Task) async {
        do {
            if networkMonitor.isConnected {
                // Online: delete via API
                try await APIClient.shared.deleteTask(id: task.id)
                try? StorageManager.shared.deleteTask(id: task.id)
            } else {
                // Offline: delete locally and queue for sync
                try await syncManager.deleteTaskOffline(id: task.id)
            }

            withAnimation(.easeOut(duration: 0.3)) {
                tasks.removeAll { $0.id == task.id }
            }
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
}

struct TaskRowView: View {
    let task: Task
    var isSelected: Bool = false
    let onToggle: () async -> Void
    let onDelete: () async -> Void
    let onGenerateRecipe: () -> Void
    var onSelect: (() -> Void)?

    @State private var isToggling = false

    private func performToggle() {
        // Haptic feedback on toggle
        if task.completed {
            HapticManager.lightImpact()
        } else {
            HapticManager.success()
        }

        _Concurrency.Task {
            isToggling = true
            await onToggle()
            isToggling = false
        }
    }

    private func performDelete() {
        // Haptic feedback on delete
        HapticManager.mediumImpact()

        _Concurrency.Task {
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
            .accessibilityLabel(task.completed ? "Mark as incomplete" : "Mark as complete")
            .accessibilityHint(task.completed ? "Double tap to mark this task as not done" : "Double tap to mark this task as done")
            .accessibilityAddTraits(.isButton)

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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Labels: \(task.labels.map { $0.name }.joined(separator: ", "))")
                }

                // Due date
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .accessibilityHidden(true)
                        Text(dueDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(dueDate < Date() && !task.completed ? .red : .secondary)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(dueDateAccessibilityLabel(dueDate))
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect?()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(taskRowAccessibilityLabel)
        .accessibilityHint("Double tap to view details. Swipe right for recipe options, swipe left to delete.")
        .accessibilityValue(task.completed ? "Completed" : "Pending")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !task.completed {
                Button(action: {
                    HapticManager.success()
                    performToggle()
                }) {
                    SwiftUI.Label("Complete", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)
            }
            
            Button(role: .destructive, action: performDelete) {
                SwiftUI.Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if !task.completed {
                Button(action: {
                    HapticManager.selection()
                    // Schedule action - could open date picker
                    // For now, just provide haptic feedback
                }) {
                    SwiftUI.Label("Schedule", systemImage: "calendar.badge.clock")
                }
                .tint(.blue)
            }
            
            Button(action: onGenerateRecipe) {
                SwiftUI.Label("Recipe", systemImage: "fork.knife")
            }
            .tint(.orange)
        }
        .contextMenu {
            Button(action: onGenerateRecipe) {
                SwiftUI.Label("Generate Recipes", systemImage: "fork.knife")
            }

            Button(action: performDelete) {
                SwiftUI.Label("Delete", systemImage: "trash")
            }
        }
    }

    private var taskRowAccessibilityLabel: String {
        var label = task.title
        if let description = task.description {
            label += ". \(description)"
        }
        return label
    }

    private func dueDateAccessibilityLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let isOverdue = date < Date() && !task.completed
        let dateString = formatter.string(from: date)
        return isOverdue ? "Overdue. Due \(dateString)" : "Due \(dateString)"
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
            .accessibilityLabel("Label: \(label.name)")
    }
}

// MARK: - Recipe Generator from Task

struct RecipeGeneratorFromTaskView: View {
    let task: Task?
    @StateObject private var recipeGenerator = AIRecipeGenerator.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIngredients: [String] = []
    @State private var generatedRecipes: [Recipe] = []
    @State private var selectedRecipe: Recipe?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if recipeGenerator.isGenerating {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating recipes from your shopping list...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if generatedRecipes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        if let task = task {
                            Text("Generate recipes from:")
                                .font(.headline)
                            Text(task.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)

                            if !selectedIngredients.isEmpty {
                                Text("Found \(selectedIngredients.count) ingredients")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: generateRecipes) {
                            Label("Generate Recipes", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .disabled(selectedIngredients.isEmpty)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            Text("\(generatedRecipes.count) recipes found")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(generatedRecipes) { recipe in
                                RecipeCardView(recipe: recipe) {
                                    selectedRecipe = recipe
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Recipe Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                NavigationStack {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .task {
                extractIngredients()
            }
        }
    }

    private func extractIngredients() {
        guard let task = task else { return }
        selectedIngredients = recipeGenerator.extractIngredientsFromTask(task)
    }

    private func generateRecipes() {
        _Concurrency.Task {
            do {
                let recipes = try await recipeGenerator.generateRecipes(
                    ingredients: selectedIngredients,
                    servings: 4
                )

                await MainActor.run {
                    generatedRecipes = recipes
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Task Inspector Content (iPad)

struct TaskInspectorContent: View {
    let task: Task?
    let onToggle: (Task) -> Void
    let onDelete: (Task) -> Void

    var body: some View {
        if let task = task {
            TaskInspectorView(task: task, onToggle: onToggle, onDelete: onDelete)
        } else {
            ContentUnavailableView {
                SwiftUI.Label("No Task Selected", systemImage: "checkmark.circle")
            } description: {
                Text("Select a task to view details")
            }
        }
    }
}

struct TaskInspectorView: View {
    let task: Task
    let onToggle: (Task) -> Void
    let onDelete: (Task) -> Void

    @State private var isToggling = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                taskHeader

                Divider()

                // Description
                if let description = task.description, !description.isEmpty {
                    descriptionSection(description)
                    Divider()
                }

                // Due Date
                if let dueDate = task.dueDate {
                    dueDateSection(dueDate)
                    Divider()
                }

                // Labels
                if !task.labels.isEmpty {
                    labelsSection
                    Divider()
                }

                // Created At
                createdAtSection

                Divider()

                // Actions
                actionsSection

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    HapticManager.lightImpact()
                    isToggling = true
                    onToggle(task)
                    isToggling = false
                }) {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.completed ? .green : .gray)
                }
                .buttonStyle(.plain)
                .disabled(isToggling)
                .accessibilityLabel(task.completed ? "Mark as incomplete" : "Mark as complete")
                .accessibilityHint(task.completed ? "Double tap to mark this task as not done" : "Double tap to mark this task as done")

                Text(task.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)
            }
            .accessibilityElement(children: .contain)

            if task.completed {
                SwiftUI.Label("Completed", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .accessibilityLabel("Task status: Completed")
            }
        }
    }

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(description)
                .font(.body)
        }
    }

    private func dueDateSection(_ dueDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Due Date")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "calendar")
                Text(dueDate, style: .date)
                Text("at")
                    .foregroundColor(.secondary)
                Text(dueDate, style: .time)
            }
            .foregroundColor(dueDate < Date() && !task.completed ? .red : .primary)
        }
    }

    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Labels")
                .font(.headline)
                .foregroundColor(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(task.labels) { label in
                    LabelBadge(label: label)
                }
            }
        }
    }

    private var createdAtSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Created")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "clock")
                Text(task.createdAt, style: .date)
                Text("at")
                    .foregroundColor(.secondary)
                Text(task.createdAt, style: .time)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                HapticManager.mediumImpact()
                onDelete(task)
            }) {
                SwiftUI.Label("Delete Task", systemImage: "trash")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .accessibilityLabel("Delete task")
            .accessibilityHint("Double tap to permanently delete this task")
            .accessibilityAddTraits(.isButton)
        }
        .padding(.top, 8)
    }
}

#Preview {
    TaskListView()
        .environment(AppState())
}
