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
                            } onGenerateRecipe: {
                                selectedTaskForRecipes = task
                                showingRecipeGenerator = true
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

                // Offline indicator
                ToolbarItem(placement: .status) {
                    HStack(spacing: 4) {
                        if !networkMonitor.isConnected {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.orange)
                            Text("Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if syncManager.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Syncing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if let lastSync = syncManager.lastSyncDate {
                            Text("Synced \(lastSync, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
            .sheet(isPresented: $showingRecipeGenerator) {
                RecipeGeneratorFromTaskView(task: selectedTaskForRecipes)
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
    let onToggle: () async -> Void
    let onDelete: () async -> Void
    let onGenerateRecipe: () -> Void

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
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
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

#Preview {
    TaskListView()
        .environment(AppState())
}
