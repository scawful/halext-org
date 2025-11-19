//
//  RecipeGeneratorView.swift
//  Cafe
//
//  Main recipe generation interface with AI-powered suggestions
//

import SwiftUI

struct RecipeGeneratorView: View {
    @StateObject private var recipeGenerator = AIRecipeGenerator.shared
    @Environment(\.dismiss) private var dismiss

    // Input state
    @State private var selectedIngredients: [String] = []
    @State private var dietaryRestrictions: [DietaryRestriction] = []
    @State private var cuisinePreferences: [String] = []
    @State private var difficultyLevel: DifficultyLevel?
    @State private var timeLimitMinutes: Int?
    @State private var mealType: MealType?
    @State private var servings: Int = 4

    // UI state
    @State private var generatedRecipes: [Recipe] = []
    @State private var showingIngredientSelector = false
    @State private var showingMealPlan = false
    @State private var selectedRecipe: Recipe?
    @State private var viewMode: ViewMode = .grid
    @State private var sortOption: SortOption = .matchScore
    @State private var errorMessage: String?
    @State private var showingError = false

    enum ViewMode {
        case grid
        case list
    }

    enum SortOption {
        case matchScore
        case time
        case difficulty
        case name
    }

    var sortedRecipes: [Recipe] {
        switch sortOption {
        case .matchScore:
            return generatedRecipes.sorted { ($0.matchScore ?? 0) > ($1.matchScore ?? 0) }
        case .time:
            return generatedRecipes.sorted { $0.totalTimeMinutes < $1.totalTimeMinutes }
        case .difficulty:
            return generatedRecipes.sorted { $0.difficulty.rawValue < $1.difficulty.rawValue }
        case .name:
            return generatedRecipes.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if recipeGenerator.isGenerating {
                    loadingView
                } else if generatedRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipesView
                }
            }
            .navigationTitle("Recipe Generator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingIngredientSelector = true }) {
                        Label("Ingredients", systemImage: "slider.horizontal.3")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewMode = .grid }) {
                            Label("Grid View", systemImage: "square.grid.2x2")
                        }
                        Button(action: { viewMode = .list }) {
                            Label("List View", systemImage: "list.bullet")
                        }

                        Divider()

                        Picker("Sort By", selection: $sortOption) {
                            Text("Best Match").tag(SortOption.matchScore)
                            Text("Quickest").tag(SortOption.time)
                            Text("Easiest").tag(SortOption.difficulty)
                            Text("Name").tag(SortOption.name)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingIngredientSelector) {
                IngredientSelectorView(
                    selectedIngredients: $selectedIngredients,
                    dietaryRestrictions: $dietaryRestrictions,
                    cuisinePreferences: $cuisinePreferences,
                    difficultyLevel: $difficultyLevel,
                    timeLimitMinutes: $timeLimitMinutes,
                    mealType: $mealType
                )
            }
            .sheet(item: $selectedRecipe) { recipe in
                NavigationStack {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 12) {
                Text("Let's Cook Something!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add ingredients to generate personalized recipe suggestions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                Button(action: { showingIngredientSelector = true }) {
                    Label("Select Ingredients", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Button(action: loadQuickSuggestions) {
                    Label("Surprise Me", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            // Quick Start Ideas
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Ideas")
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickIdeaCard(
                            icon: "clock",
                            title: "Quick Dinners",
                            subtitle: "Under 30 min"
                        ) {
                            loadQuickDinners()
                        }

                        QuickIdeaCard(
                            icon: "leaf",
                            title: "Healthy Meals",
                            subtitle: "Low calorie"
                        ) {
                            loadHealthyMeals()
                        }

                        QuickIdeaCard(
                            icon: "dollarsign.circle",
                            title: "Budget Friendly",
                            subtitle: "Under $10"
                        ) {
                            loadBudgetMeals()
                        }

                        QuickIdeaCard(
                            icon: "calendar",
                            title: "Meal Prep",
                            subtitle: "Weekly plan"
                        ) {
                            loadMealPlan()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var recipesView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Active Filters
                if !selectedIngredients.isEmpty || !dietaryRestrictions.isEmpty {
                    activeFiltersSection
                }

                // Results Count
                HStack {
                    Text("\(generatedRecipes.count) recipes found")
                        .font(.headline)

                    Spacer()

                    Button(action: regenerateRecipes) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                // Recipes
                if viewMode == .grid {
                    recipesGridView
                } else {
                    recipesListView
                }
            }
            .padding(.vertical)
        }
    }

    private var activeFiltersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Filters")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedIngredients.prefix(5), id: \.self) { ingredient in
                        FilterBadge(text: ingredient, color: .blue)
                    }

                    if selectedIngredients.count > 5 {
                        FilterBadge(text: "+\(selectedIngredients.count - 5) more", color: .blue)
                    }

                    ForEach(dietaryRestrictions, id: \.self) { restriction in
                        FilterBadge(text: restriction.displayName, color: .green)
                    }

                    if let difficulty = difficultyLevel {
                        FilterBadge(text: difficulty.displayName, color: .orange)
                    }

                    if let time = timeLimitMinutes {
                        FilterBadge(text: "< \(time)m", color: .purple)
                    }

                    Button(action: { showingIngredientSelector = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Edit")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var recipesGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(sortedRecipes) { recipe in
                RecipeGridCardView(recipe: recipe) {
                    selectedRecipe = recipe
                }
            }
        }
        .padding(.horizontal)
    }

    private var recipesListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(sortedRecipes) { recipe in
                RecipeCardView(recipe: recipe) {
                    selectedRecipe = recipe
                }
            }
        }
        .padding(.horizontal)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Generating delicious recipes...")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Analyzing your ingredients and preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Actions

    private func generateRecipes() {
        guard !selectedIngredients.isEmpty else {
            errorMessage = "Please select at least one ingredient"
            showingError = true
            return
        }

        _Concurrency.Task {
            do {
                let recipes = try await recipeGenerator.generateRecipes(
                    ingredients: selectedIngredients,
                    dietaryRestrictions: dietaryRestrictions,
                    cuisinePreferences: cuisinePreferences,
                    difficultyLevel: difficultyLevel,
                    timeLimitMinutes: timeLimitMinutes,
                    servings: servings,
                    mealType: mealType
                )

                await MainActor.run {
                    generatedRecipes = recipes
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    private func regenerateRecipes() {
        generateRecipes()
    }

    private func loadQuickSuggestions() {
        selectedIngredients = ["chicken", "pasta", "tomatoes", "garlic"]
        timeLimitMinutes = 30
        generateRecipes()
    }

    private func loadQuickDinners() {
        timeLimitMinutes = 30
        mealType = .dinner
        selectedIngredients = [] // Let AI suggest common ingredients
        generateRecipes()
    }

    private func loadHealthyMeals() {
        dietaryRestrictions = [.lowFat]
        selectedIngredients = ["chicken", "vegetables", "quinoa"]
        generateRecipes()
    }

    private func loadBudgetMeals() {
        selectedIngredients = ["rice", "beans", "eggs", "pasta"]
        generateRecipes()
    }

    private func loadMealPlan() {
        showingMealPlan = true
        // Navigate to meal plan generator
    }
}

// MARK: - Supporting Views

struct FilterBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.capitalized)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(12)
    }
}

struct QuickIdeaCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Meal Plan View

struct MealPlanGeneratorView: View {
    @StateObject private var recipeGenerator = AIRecipeGenerator.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIngredients: [String] = []
    @State private var dietaryRestrictions: [DietaryRestriction] = []
    @State private var numberOfDays = 7
    @State private var budget: Double?
    @State private var mealsPerDay = 3

    @State private var mealPlan: MealPlanResponse?
    @State private var showingIngredientSelector = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Configuration
                    configurationSection

                    // Generate Button
                    Button(action: generateMealPlan) {
                        if recipeGenerator.isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Label("Generate Meal Plan", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.blue)
                    .cornerRadius(12)
                    .disabled(selectedIngredients.isEmpty || recipeGenerator.isGenerating)

                    // Results
                    if let mealPlan = mealPlan {
                        mealPlanResults(mealPlan)
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Plan Generator")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingIngredientSelector) {
                IngredientSelectorView(
                    selectedIngredients: $selectedIngredients,
                    dietaryRestrictions: $dietaryRestrictions,
                    cuisinePreferences: .constant([]),
                    difficultyLevel: .constant(nil),
                    timeLimitMinutes: .constant(nil),
                    mealType: .constant(nil)
                )
            }
        }
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Ingredients
            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients")
                    .font(.headline)

                Button(action: { showingIngredientSelector = true }) {
                    HStack {
                        if selectedIngredients.isEmpty {
                            Text("Select ingredients")
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedIngredients.count) ingredients selected")
                                .foregroundColor(.primary)
                        }

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

            // Number of Days
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.headline)

                Picker("Days", selection: $numberOfDays) {
                    Text("3 days").tag(3)
                    Text("5 days").tag(5)
                    Text("7 days").tag(7)
                }
                .pickerStyle(.segmented)
            }

            // Meals Per Day
            VStack(alignment: .leading, spacing: 8) {
                Text("Meals Per Day")
                    .font(.headline)

                Picker("Meals", selection: $mealsPerDay) {
                    Text("2 meals").tag(2)
                    Text("3 meals").tag(3)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private func mealPlanResults(_ plan: MealPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Meal Plan")
                .font(.title2)
                .fontWeight(.bold)

            // Shopping List
            if !plan.shoppingList.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shopping List")
                        .font(.headline)

                    ForEach(plan.shoppingList, id: \.self) { item in
                        HStack {
                            Image(systemName: "cart")
                                .foregroundColor(.blue)
                            Text(item)
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            // Daily Meals
            ForEach(plan.mealPlan) { dayPlan in
                DayMealPlanCard(dayPlan: dayPlan)
            }
        }
    }

    private func generateMealPlan() {
        _Concurrency.Task {
            do {
                let plan = try await recipeGenerator.generateMealPlan(
                    ingredients: selectedIngredients,
                    days: numberOfDays,
                    dietaryRestrictions: dietaryRestrictions,
                    budget: budget,
                    mealsPerDay: mealsPerDay
                )

                await MainActor.run {
                    mealPlan = plan
                }
            } catch {
                print("Failed to generate meal plan: \(error)")
            }
        }
    }
}

struct DayMealPlanCard: View {
    let dayPlan: DayMealPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dayPlan.day)
                .font(.headline)

            ForEach(dayPlan.meals) { meal in
                HStack {
                    Image(systemName: meal.mealType.icon)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.mealType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(meal.recipe.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    Text("\(meal.recipe.totalTimeMinutes)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview("Recipe Generator") {
    RecipeGeneratorView()
}

#Preview("Meal Plan") {
    MealPlanGeneratorView()
}
