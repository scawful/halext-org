//
//  IngredientSelectorView.swift
//  Cafe
//
//  Ingredient input and selection interface
//

import SwiftUI

struct IngredientSelectorView: View {
    @Binding var selectedIngredients: [String]
    @Binding var dietaryRestrictions: [DietaryRestriction]
    @Binding var cuisinePreferences: [String]
    @Binding var difficultyLevel: DifficultyLevel?
    @Binding var timeLimitMinutes: Int?
    @Binding var mealType: MealType?

    @State private var ingredientInput = ""
    @State private var showingTaskPicker = false
    @State private var showingCommonIngredients = true
    @State private var selectedTasks: [Task] = []

    @Environment(\.dismiss) private var dismiss

    // Common ingredients by category
    private let commonIngredients: [String: [String]] = [
        "Proteins": ["chicken", "beef", "pork", "fish", "tofu", "eggs", "beans"],
        "Vegetables": ["broccoli", "carrots", "tomatoes", "onions", "peppers", "spinach", "potatoes"],
        "Grains": ["rice", "pasta", "bread", "quinoa", "oats"],
        "Dairy": ["milk", "cheese", "yogurt", "butter"],
        "Pantry": ["flour", "sugar", "salt", "pepper", "oil", "garlic", "soy sauce"]
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Current Ingredients
                    currentIngredientsSection

                    // Add Ingredients Section
                    addIngredientsSection

                    // Import from Tasks
                    importFromTasksSection

                    // Common Ingredients
                    if showingCommonIngredients {
                        commonIngredientsSection
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Preferences
                    preferencesSection
                }
                .padding()
            }
            .navigationTitle("Select Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedIngredients.isEmpty)
                }
            }
            .sheet(isPresented: $showingTaskPicker) {
                TaskPickerView(selectedTasks: $selectedTasks) { tasks in
                    importIngredientsFromTasks(tasks)
                }
            }
        }
    }

    // MARK: - Sections

    private var currentIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Ingredients")
                    .font(.headline)

                Spacer()

                Text("\(selectedIngredients.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if selectedIngredients.isEmpty {
                Text("No ingredients selected yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(selectedIngredients, id: \.self) { ingredient in
                        IngredientChip(
                            name: ingredient,
                            isSelected: true
                        ) {
                            selectedIngredients.removeAll { $0 == ingredient }
                        }
                    }
                }
            }
        }
    }

    private var addIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Ingredient")
                .font(.headline)

            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)

                TextField("Enter ingredient name", text: $ingredientInput)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .onSubmit {
                        addIngredient()
                    }

                Button(action: addIngredient) {
                    Text("Add")
                        .fontWeight(.medium)
                }
                .disabled(ingredientInput.isEmpty)
            }
        }
    }

    private var importFromTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import from Tasks")
                .font(.headline)

            Button(action: { showingTaskPicker = true }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.blue)

                    Text("Select shopping list tasks")
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    private var commonIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Add")
                    .font(.headline)

                Spacer()

                Button(action: { showingCommonIngredients.toggle() }) {
                    Image(systemName: showingCommonIngredients ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }

            ForEach(Array(commonIngredients.keys.sorted()), id: \.self) { category in
                VStack(alignment: .leading, spacing: 8) {
                    Text(category)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(commonIngredients[category] ?? [], id: \.self) { ingredient in
                            IngredientChip(
                                name: ingredient,
                                isSelected: selectedIngredients.contains(ingredient)
                            ) {
                                toggleIngredient(ingredient)
                            }
                        }
                    }
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferences")
                .font(.headline)

            // Dietary Restrictions
            VStack(alignment: .leading, spacing: 12) {
                Text("Dietary Restrictions")
                    .font(.subheadline)
                    .fontWeight(.medium)

                FlowLayout(spacing: 8) {
                    ForEach(DietaryRestriction.allCases) { restriction in
                        PreferenceChip(
                            icon: restriction.icon,
                            name: restriction.displayName,
                            isSelected: dietaryRestrictions.contains(restriction)
                        ) {
                            toggleDietaryRestriction(restriction)
                        }
                    }
                }
            }

            // Cuisine Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Cuisine Type")
                    .font(.subheadline)
                    .fontWeight(.medium)

                FlowLayout(spacing: 8) {
                    ForEach(CuisineType.allCases) { cuisine in
                        CuisineChip(
                            flag: cuisine.flag,
                            name: cuisine.rawValue,
                            isSelected: cuisinePreferences.contains(cuisine.rawValue)
                        ) {
                            toggleCuisine(cuisine.rawValue)
                        }
                    }
                }
            }

            // Difficulty Level
            VStack(alignment: .leading, spacing: 12) {
                Text("Difficulty Level")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    ForEach(DifficultyLevel.allCases) { difficulty in
                        DifficultyButton(
                            difficulty: difficulty,
                            isSelected: difficultyLevel == difficulty
                        ) {
                            difficultyLevel = difficulty == difficultyLevel ? nil : difficulty
                        }
                    }
                }
            }

            // Time Limit
            VStack(alignment: .leading, spacing: 12) {
                Text("Time Limit")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    TimeButton(label: "15 min", minutes: 15, selected: timeLimitMinutes) {
                        timeLimitMinutes = 15
                    }
                    TimeButton(label: "30 min", minutes: 30, selected: timeLimitMinutes) {
                        timeLimitMinutes = 30
                    }
                    TimeButton(label: "1 hour", minutes: 60, selected: timeLimitMinutes) {
                        timeLimitMinutes = 60
                    }
                    TimeButton(label: "Any", minutes: nil, selected: timeLimitMinutes) {
                        timeLimitMinutes = nil
                    }
                }
            }

            // Meal Type
            VStack(alignment: .leading, spacing: 12) {
                Text("Meal Type")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    ForEach(MealType.allCases) { meal in
                        MealTypeButton(
                            mealType: meal,
                            isSelected: mealType == meal
                        ) {
                            mealType = meal == mealType ? nil : meal
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func addIngredient() {
        let trimmed = ingredientInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !selectedIngredients.contains(trimmed.lowercased()) {
            selectedIngredients.append(trimmed.lowercased())
        }

        ingredientInput = ""
    }

    private func toggleIngredient(_ ingredient: String) {
        if let index = selectedIngredients.firstIndex(of: ingredient) {
            selectedIngredients.remove(at: index)
        } else {
            selectedIngredients.append(ingredient)
        }
    }

    private func toggleDietaryRestriction(_ restriction: DietaryRestriction) {
        if let index = dietaryRestrictions.firstIndex(of: restriction) {
            dietaryRestrictions.remove(at: index)
        } else {
            dietaryRestrictions.append(restriction)
        }
    }

    private func toggleCuisine(_ cuisine: String) {
        if let index = cuisinePreferences.firstIndex(of: cuisine) {
            cuisinePreferences.remove(at: index)
        } else {
            cuisinePreferences.append(cuisine)
        }
    }

    private func importIngredientsFromTasks(_ tasks: [Task]) {
        let generator = AIRecipeGenerator.shared
        for task in tasks {
            let ingredients = generator.extractIngredientsFromTask(task)
            for ingredient in ingredients {
                if !selectedIngredients.contains(ingredient.lowercased()) {
                    selectedIngredients.append(ingredient.lowercased())
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct IngredientChip: View {
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(name.capitalized)
                    .font(.subheadline)

                if isSelected {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct PreferenceChip: View {
    let icon: String
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct CuisineChip: View {
    let flag: String
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(flag)
                    .font(.caption)
                Text(name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct DifficultyButton: View {
    let difficulty: DifficultyLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: difficulty.icon)
                    .font(.title3)
                Text(difficulty.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? difficultyColor : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }

    private var difficultyColor: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
}

struct TimeButton: View {
    let label: String
    let minutes: Int?
    let selected: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected == minutes ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(selected == minutes ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct MealTypeButton: View {
    let mealType: MealType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: mealType.icon)
                    .font(.title3)
                Text(mealType.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Task Picker

struct TaskPickerView: View {
    @Binding var selectedTasks: [Task]
    let onDone: ([Task]) -> Void

    @State private var tasks: [Task] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading tasks...")
                } else if tasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks",
                        systemImage: "list.bullet",
                        description: Text("Create some shopping list tasks first")
                    )
                } else {
                    List {
                        ForEach(tasks) { task in
                            TaskSelectionRow(
                                task: task,
                                isSelected: selectedTasks.contains(where: { $0.id == task.id })
                            ) {
                                toggleTask(task)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        onDone(selectedTasks)
                        dismiss()
                    }
                    .disabled(selectedTasks.isEmpty)
                }
            }
            .task {
                await loadTasks()
            }
        }
    }

    private func loadTasks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            tasks = try await APIClient.shared.getTasks()
        } catch {
            print("Failed to load tasks: \(error)")
        }
    }

    private func toggleTask(_ task: Task) {
        if let index = selectedTasks.firstIndex(where: { $0.id == task.id }) {
            selectedTasks.remove(at: index)
        } else {
            selectedTasks.append(task)
        }
    }
}

struct TaskSelectionRow: View {
    let task: Task
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body)

                    if let description = task.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    IngredientSelectorView(
        selectedIngredients: .constant(["chicken", "rice", "broccoli"]),
        dietaryRestrictions: .constant([.glutenFree]),
        cuisinePreferences: .constant(["Italian"]),
        difficultyLevel: .constant(.beginner),
        timeLimitMinutes: .constant(30),
        mealType: .constant(.dinner)
    )
}
