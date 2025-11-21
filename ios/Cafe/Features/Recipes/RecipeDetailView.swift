//
//  RecipeDetailView.swift
//  Cafe
//
//  Full recipe display with step-by-step instructions
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recipeGenerator = AIRecipeGenerator.shared

    @State private var currentServings: Int
    @State private var checkedIngredients: Set<String> = []
    @State private var completedSteps: Set<String> = []
    @State private var showingShareSheet = false
    @State private var isSaved = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _currentServings = State(initialValue: recipe.servings)
    }

    var scaledRecipe: Recipe {
        if currentServings == recipe.servings {
            return recipe
        }
        return recipeGenerator.scaleRecipe(recipe, toServings: currentServings)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                recipeImage

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    recipeHeader

                    Divider()

                    // Quick Info
                    quickInfo

                    Divider()

                    // Nutrition (if available)
                    if let nutrition = scaledRecipe.nutrition {
                        nutritionSection(nutrition)
                        Divider()
                    }

                    // Match Info (if available)
                    if scaledRecipe.matchScore != nil || scaledRecipe.missingIngredients != nil {
                        matchInfoSection
                        Divider()
                    }

                    // Ingredients
                    ingredientsSection

                    Divider()

                    // Instructions
                    instructionsSection

                    // Tags
                    if !recipe.tags.isEmpty {
                        tagsSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Menu {
                        Button(action: convertToTasks) {
                            Label("Create Shopping & Prep Tasks", systemImage: "list.bullet.rectangle")
                        }
                        
                        Divider()
                        
                        Button(action: { showingShareSheet = true }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                    Button(action: { isSaved.toggle() }) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .foregroundColor(isSaved ? .red : .primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    // MARK: - Recipe to Task Conversion
    
    private func convertToTasks() {
        _Concurrency.Task {
            do {
                let scaled = scaledRecipe
                
                // Create shopping list task
                let ingredientsList = scaled.ingredients.map { ingredient in
                    var item = "• \(ingredient.name)"
                    if !ingredient.amount.isEmpty {
                        item += " - \(ingredient.amount)"
                        if let unit = ingredient.unit, !unit.isEmpty {
                            item += " \(unit)"
                        }
                    }
                    return item
                }.joined(separator: "\n")
                
                let shoppingTask = TaskCreate(
                    title: "Shopping: \(scaled.name)",
                    description: "Ingredients needed:\n\(ingredientsList)",
                    dueDate: Date().addingTimeInterval(86400), // Due tomorrow
                    labels: ["Shopping", "Recipe"]
                )
                _ = try await APIClient.shared.createTask(shoppingTask)
                
                // Create meal prep task
                let prepTask = TaskCreate(
                    title: "Meal Prep: \(scaled.name)",
                    description: "Prep time: \(scaled.prepTimeMinutes) minutes\nCook time: \(scaled.cookTimeMinutes) minutes\nTotal: \(scaled.totalTimeMinutes) minutes",
                    dueDate: Date().addingTimeInterval(86400 * 2), // Due in 2 days
                    labels: ["Meal Prep", "Recipe"]
                )
                _ = try await APIClient.shared.createTask(prepTask)
                
                // Create cooking task
                let cookingTask = TaskCreate(
                    title: "Cook: \(scaled.name)",
                    description: "Follow recipe instructions. Estimated time: \(scaled.totalTimeMinutes) minutes",
                    dueDate: Date().addingTimeInterval(86400 * 2), // Due in 2 days
                    labels: ["Cooking", "Recipe"]
                )
                _ = try await APIClient.shared.createTask(cookingTask)
                
                // Show success feedback
                await MainActor.run {
                    HapticManager.success()
                }
            } catch {
                print("Failed to create tasks from recipe: \(error)")
            }
        }
    }

    // MARK: - Components

    @ViewBuilder
    private var recipeImage: some View {
        if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                default:
                    placeholderImage
                }
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.4), Color.red.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 250)

            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var recipeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.name)
                .font(.title)
                .fontWeight(.bold)

            if let cuisine = recipe.cuisine {
                Text(cuisine + " Cuisine")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(recipe.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private var quickInfo: some View {
        HStack(spacing: 20) {
            InfoPill(
                icon: "clock",
                label: "Total",
                value: "\(recipe.totalTimeMinutes)m",
                color: .blue
            )

            InfoPill(
                icon: "flame",
                label: "Prep",
                value: "\(recipe.prepTimeMinutes)m",
                color: .orange
            )

            InfoPill(
                icon: recipe.difficulty.icon,
                label: recipe.difficulty.displayName,
                value: "",
                color: difficultyColor(recipe.difficulty)
            )
        }
    }

    private func nutritionSection(_ nutrition: NutritionInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition per serving")
                .font(.headline)

            HStack(spacing: 16) {
                NutritionBadge(label: "Calories", value: "\(nutrition.calories)", unit: "kcal")
                NutritionBadge(label: "Protein", value: String(format: "%.0f", nutrition.protein), unit: "g")
                NutritionBadge(label: "Carbs", value: String(format: "%.0f", nutrition.carbohydrates), unit: "g")
                NutritionBadge(label: "Fat", value: String(format: "%.0f", nutrition.fat), unit: "g")
            }
        }
    }

    private var matchInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let matchScore = recipe.matchScore {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("You have \(Int(matchScore * 100))% of ingredients")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if let missing = recipe.missingIngredients, !missing.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Missing ingredients:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    ForEach(missing, id: \.self) { ingredient in
                        HStack {
                            Image(systemName: "cart.badge.plus")
                                .font(.caption)
                            Text(ingredient)
                                .font(.subheadline)
                        }
                        .foregroundColor(.orange)
                    }

                    Button(action: { /* Add to shopping list */ }) {
                        Label("Add to Shopping List", systemImage: "cart")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Serving Size Adjuster
                HStack(spacing: 12) {
                    Button(action: {
                        if currentServings > 1 {
                            currentServings -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .font(.title3)
                    }
                    .disabled(currentServings <= 1)

                    Text("\(currentServings) servings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 80)

                    Button(action: { currentServings += 1 }) {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                    }
                }
            }

            ForEach(scaledRecipe.ingredients) { ingredient in
                IngredientRow(
                    ingredient: ingredient,
                    isChecked: checkedIngredients.contains(ingredient.id)
                ) {
                    if checkedIngredients.contains(ingredient.id) {
                        checkedIngredients.remove(ingredient.id)
                    } else {
                        checkedIngredients.insert(ingredient.id)
                    }
                }
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(recipe.instructions) { step in
                InstructionStepView(
                    step: step,
                    isCompleted: completedSteps.contains(step.id)
                ) {
                    if completedSteps.contains(step.id) {
                        completedSteps.remove(step.id)
                    } else {
                        completedSteps.insert(step.id)
                    }
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(recipe.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }

    private func generateShareText() -> String {
        var text = "\(recipe.name)\n\n"
        text += "\(recipe.description)\n\n"
        text += "Ingredients:\n"
        for ingredient in recipe.ingredients {
            text += "- \(ingredient.displayText)\n"
        }
        text += "\nInstructions:\n"
        for step in recipe.instructions {
            text += "\(step.stepNumber). \(step.instruction)\n"
        }
        return text
    }
}

// MARK: - Supporting Views

struct InfoPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            if !value.isEmpty {
                Text(value)
                    .font(.headline)
            }

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NutritionBadge: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct IngredientRow: View {
    let ingredient: RecipeIngredient
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? .green : .gray)
                    .font(.title3)

                Text(ingredient.displayText)
                    .font(.body)
                    .foregroundColor(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked)

                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InstructionStepView: View {
    let step: CookingStep
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 16) {
                // Step Number
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.blue)
                        .frame(width: 32, height: 32)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(step.stepNumber)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                // Instruction
                VStack(alignment: .leading, spacing: 8) {
                    Text(step.instruction)
                        .font(.body)
                        .foregroundColor(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)

                    if let timeMinutes = step.timeMinutes {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption)
                            Text("\(timeMinutes) minutes")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }

                Spacer()
            }
            .padding()
            .background(isCompleted ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout for Tags
// Note: FlowLayout is defined in AdvancedFeaturesView.swift

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(
            name: "Classic Chicken Carbonara",
            description: "A creamy Italian pasta dish with chicken, bacon, and parmesan cheese",
            ingredients: [
                RecipeIngredient(name: "spaghetti", amount: "1", unit: "lb"),
                RecipeIngredient(name: "chicken breast", amount: "2", unit: "pieces"),
                RecipeIngredient(name: "bacon", amount: "6", unit: "slices"),
                RecipeIngredient(name: "eggs", amount: "3", unit: "large"),
                RecipeIngredient(name: "parmesan cheese", amount: "1", unit: "cup"),
                RecipeIngredient(name: "garlic", amount: "3", unit: "cloves"),
                RecipeIngredient(name: "black pepper", amount: "1", unit: "tsp", isOptional: true)
            ],
            instructions: [
                CookingStep(stepNumber: 1, instruction: "Bring a large pot of salted water to boil", timeMinutes: 10),
                CookingStep(stepNumber: 2, instruction: "Cook pasta according to package directions", timeMinutes: 12),
                CookingStep(stepNumber: 3, instruction: "Meanwhile, cook bacon until crispy", timeMinutes: 8),
                CookingStep(stepNumber: 4, instruction: "Cook chicken in same pan as bacon", timeMinutes: 10),
                CookingStep(stepNumber: 5, instruction: "Mix eggs and cheese in a bowl"),
                CookingStep(stepNumber: 6, instruction: "Toss hot pasta with egg mixture and meat", timeMinutes: 2)
            ],
            prepTimeMinutes: 15,
            cookTimeMinutes: 30,
            totalTimeMinutes: 45,
            servings: 4,
            difficulty: .intermediate,
            cuisine: "Italian",
            nutrition: NutritionInfo(
                calories: 650,
                protein: 45,
                carbohydrates: 58,
                fat: 25,
                fiber: 3,
                sugar: 2,
                sodium: 820
            ),
            tags: ["pasta", "italian", "dinner", "comfort food"],
            matchedIngredients: ["chicken", "pasta", "eggs"],
            missingIngredients: ["bacon", "parmesan"],
            matchScore: 0.71
        ))
    }
}
