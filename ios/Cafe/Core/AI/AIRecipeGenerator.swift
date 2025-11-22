//
//  AIRecipeGenerator.swift
//  Cafe
//
//  AI-powered recipe generation and meal planning manager
//

import Foundation
import Combine

@MainActor
class AIRecipeGenerator: ObservableObject {
    static let shared = AIRecipeGenerator()

    @Published var isGenerating = false
    @Published var lastError: String?
    @Published var generatedRecipes: [Recipe] = []
    @Published var currentMealPlan: [DayMealPlan] = []

    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Recipe Generation

    /// Generate recipes based on available ingredients
    func generateRecipes(
        ingredients: [String],
        dietaryRestrictions: [DietaryRestriction] = [],
        cuisinePreferences: [String] = [],
        difficultyLevel: DifficultyLevel? = nil,
        timeLimitMinutes: Int? = nil,
        servings: Int? = 4,
        mealType: MealType? = nil
    ) async throws -> [Recipe] {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }

        do {
            let request = RecipeGenerationRequest(
                ingredients: ingredients,
                dietaryRestrictions: dietaryRestrictions,
                cuisinePreferences: cuisinePreferences,
                difficultyLevel: difficultyLevel,
                timeLimitMinutes: timeLimitMinutes,
                servings: servings,
                mealType: mealType
            )

            let response: RecipeGenerationResponse = try await apiClient.generateRecipes(request: request)
            generatedRecipes = response.recipes

            return response.recipes
        } catch let error as APIError {
            let userMessage = error.errorDescription ?? "Failed to generate recipes. Please try again."
            lastError = userMessage
            throw error
        } catch let urlError as URLError {
            let userMessage: String
            switch urlError.code {
            case .timedOut:
                userMessage = "Request timed out. The AI service may be busy. Please try again."
            case .notConnectedToInternet:
                userMessage = "No internet connection. Please check your network and try again."
            case .cannotConnectToHost:
                userMessage = "Cannot connect to server. Please check your connection and try again."
            default:
                userMessage = "Network error: \(urlError.localizedDescription). Please try again."
            }
            lastError = userMessage
            throw urlError
        } catch {
            let userMessage = "Failed to generate recipes: \(error.localizedDescription). Please try again."
            lastError = userMessage
            throw error
        }
    }

    /// Generate a meal plan for multiple days
    func generateMealPlan(
        ingredients: [String],
        days: Int = 7,
        dietaryRestrictions: [DietaryRestriction] = [],
        budget: Double? = nil,
        mealsPerDay: Int = 3
    ) async throws -> MealPlanResponse {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }

        do {
            let request = MealPlanRequest(
                ingredients: ingredients,
                days: days,
                dietaryRestrictions: dietaryRestrictions,
                budget: budget,
                mealsPerDay: mealsPerDay
            )

            let response: MealPlanResponse = try await apiClient.generateMealPlan(request: request)
            currentMealPlan = response.mealPlan

            return response
        } catch let error as APIError {
            let userMessage = error.errorDescription ?? "Failed to generate meal plan. Please try again."
            lastError = userMessage
            throw error
        } catch let urlError as URLError {
            let userMessage: String
            switch urlError.code {
            case .timedOut:
                userMessage = "Request timed out. The AI service may be busy. Please try again."
            case .notConnectedToInternet:
                userMessage = "No internet connection. Please check your network and try again."
            case .cannotConnectToHost:
                userMessage = "Cannot connect to server. Please check your connection and try again."
            default:
                userMessage = "Network error: \(urlError.localizedDescription). Please try again."
            }
            lastError = userMessage
            throw urlError
        } catch {
            let userMessage = "Failed to generate meal plan: \(error.localizedDescription). Please try again."
            lastError = userMessage
            throw error
        }
    }

    /// Get recipe suggestions based on what's missing
    func suggestRecipesWithSubstitutions(
        availableIngredients: [String],
        desiredRecipeType: String? = nil
    ) async throws -> [Recipe] {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }

        // This will analyze available ingredients and suggest recipes
        // even if some ingredients are missing, providing substitution options
        let response: RecipeGenerationResponse = try await apiClient.generateRecipesWithSubstitutions(
            ingredients: availableIngredients,
            recipeType: desiredRecipeType
        )

        return response.recipes
    }

    // MARK: - Ingredient Parsing

    /// Extract ingredients from a shopping list task
    func extractIngredientsFromTask(_ task: Task) -> [String] {
        var ingredients: [String] = []

        // Parse title
        let titleIngredients = parseIngredientsFromText(task.title)
        ingredients.append(contentsOf: titleIngredients)

        // Parse description if available
        if let description = task.description {
            let descIngredients = parseIngredientsFromText(description)
            ingredients.append(contentsOf: descIngredients)
        }

        return Array(Set(ingredients)) // Remove duplicates
    }

    /// Parse ingredients from plain text
    func parseIngredientsFromText(_ text: String) -> [String] {
        // Split by common delimiters
        let separators = CharacterSet(charactersIn: ",;\n-•")
        let components = text.components(separatedBy: separators)

        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { cleanIngredientText($0) }
    }

    /// Clean ingredient text by removing quantities and common words
    private func cleanIngredientText(_ text: String) -> String {
        var cleaned = text.lowercased()

        // Remove common action words
        let removeWords = ["buy", "get", "purchase", "pick up", "grab"]
        for word in removeWords {
            cleaned = cleaned.replacingOccurrences(of: word, with: "")
        }

        // Remove numbers and measurement units
        let pattern = "\\b\\d+(\\.\\d+)?\\s*(lbs?|oz|g|kg|ml|l|cups?|tbsp|tsp)?\\b"
        cleaned = cleaned.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Analyze ingredients and categorize them
    func analyzeIngredients(_ ingredients: [String]) async throws -> IngredientAnalysis {
        let response: IngredientAnalysis = try await apiClient.analyzeIngredients(ingredients: ingredients)
        return response
    }

    // MARK: - Recipe Matching

    /// Calculate how well ingredients match a recipe
    func calculateMatchScore(
        availableIngredients: [String],
        recipeIngredients: [RecipeIngredient]
    ) -> Double {
        let requiredIngredients = recipeIngredients.filter { !$0.isOptional }
        let matchedCount = requiredIngredients.filter { recipeIng in
            availableIngredients.contains { available in
                available.lowercased().contains(recipeIng.name.lowercased()) ||
                recipeIng.name.lowercased().contains(available.lowercased())
            }
        }.count

        guard !requiredIngredients.isEmpty else { return 0.0 }
        return Double(matchedCount) / Double(requiredIngredients.count)
    }

    /// Find missing ingredients for a recipe
    func findMissingIngredients(
        availableIngredients: [String],
        recipe: Recipe
    ) -> [String] {
        let required = recipe.ingredients.filter { !$0.isOptional }

        return required.filter { recipeIng in
            !availableIngredients.contains { available in
                available.lowercased().contains(recipeIng.name.lowercased()) ||
                recipeIng.name.lowercased().contains(available.lowercased())
            }
        }.map { $0.name }
    }

    // MARK: - Shopping List Integration

    /// Generate a shopping list from a recipe
    func generateShoppingList(from recipe: Recipe) -> [String] {
        return recipe.ingredients.map { $0.displayText }
    }

    /// Generate a shopping list from multiple recipes
    func generateShoppingList(from recipes: [Recipe]) -> [String] {
        var allIngredients: [String: RecipeIngredient] = [:]

        for recipe in recipes {
            for ingredient in recipe.ingredients {
                // Group by ingredient name
                let key = ingredient.name.lowercased()
                allIngredients[key] = ingredient
            }
        }

        return allIngredients.values.map { $0.displayText }.sorted()
    }

    /// Generate a shopping list for missing ingredients
    func generateShoppingListForMissingIngredients(
        availableIngredients: [String],
        recipe: Recipe
    ) -> [String] {
        let missing = findMissingIngredients(
            availableIngredients: availableIngredients,
            recipe: recipe
        )

        return missing
    }

    // MARK: - Recipe Scaling

    /// Scale recipe servings
    func scaleRecipe(_ recipe: Recipe, toServings newServings: Int) -> Recipe {
        let scale = Double(newServings) / Double(recipe.servings)

        let scaledIngredients = recipe.ingredients.map { ingredient in
            let scaledAmount = scaleAmount(ingredient.amount, by: scale)
            return RecipeIngredient(
                id: ingredient.id,
                name: ingredient.name,
                amount: scaledAmount,
                unit: ingredient.unit,
                notes: ingredient.notes,
                isOptional: ingredient.isOptional
            )
        }

        return Recipe(
            id: recipe.id,
            name: recipe.name,
            description: recipe.description,
            ingredients: scaledIngredients,
            instructions: recipe.instructions,
            prepTimeMinutes: recipe.prepTimeMinutes,
            cookTimeMinutes: recipe.cookTimeMinutes,
            totalTimeMinutes: recipe.totalTimeMinutes,
            servings: newServings,
            difficulty: recipe.difficulty,
            cuisine: recipe.cuisine,
            imageURL: recipe.imageURL,
            nutrition: scaleNutrition(recipe.nutrition, by: scale),
            tags: recipe.tags,
            matchedIngredients: recipe.matchedIngredients,
            missingIngredients: recipe.missingIngredients,
            matchScore: recipe.matchScore
        )
    }

    private func scaleAmount(_ amount: String, by scale: Double) -> String {
        // Try to extract number from amount string
        let pattern = "\\d+(\\.\\d+)?"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: amount,
                range: NSRange(amount.startIndex..., in: amount)
              ),
              let range = Range(match.range, in: amount),
              let value = Double(amount[range]) else {
            return amount // Return original if can't parse
        }

        let scaledValue = value * scale
        let roundedValue = round(scaledValue * 100) / 100 // Round to 2 decimals

        return amount.replacingCharacters(in: range, with: String(format: "%.1f", roundedValue))
    }

    private func scaleNutrition(_ nutrition: NutritionInfo?, by scale: Double) -> NutritionInfo? {
        guard let nutrition = nutrition else { return nil }

        return NutritionInfo(
            calories: Int(Double(nutrition.calories) * scale),
            protein: nutrition.protein * scale,
            carbohydrates: nutrition.carbohydrates * scale,
            fat: nutrition.fat * scale,
            fiber: nutrition.fiber.map { $0 * scale },
            sugar: nutrition.sugar.map { $0 * scale },
            sodium: nutrition.sodium.map { $0 * scale }
        )
    }

    // MARK: - Smart Features

    /// Suggest batch cooking recipes (recipes that share ingredients)
    func suggestBatchCookingRecipes(
        from recipes: [Recipe],
        minimumSharedIngredients: Int = 3
    ) -> [[Recipe]] {
        var batches: [[Recipe]] = []
        var processed = Set<String>()

        for recipe in recipes {
            guard !processed.contains(recipe.id) else { continue }

            var batch = [recipe]
            processed.insert(recipe.id)

            // Find recipes with shared ingredients
            for otherRecipe in recipes where otherRecipe.id != recipe.id {
                guard !processed.contains(otherRecipe.id) else { continue }

                let sharedCount = countSharedIngredients(recipe, otherRecipe)
                if sharedCount >= minimumSharedIngredients {
                    batch.append(otherRecipe)
                    processed.insert(otherRecipe.id)
                }
            }

            if batch.count > 1 {
                batches.append(batch)
            }
        }

        return batches
    }

    private func countSharedIngredients(_ recipe1: Recipe, _ recipe2: Recipe) -> Int {
        let ingredients1 = Set(recipe1.ingredients.map { $0.name.lowercased() })
        let ingredients2 = Set(recipe2.ingredients.map { $0.name.lowercased() })
        return ingredients1.intersection(ingredients2).count
    }

    /// Get seasonal recipe suggestions
    func getSeasonalRecipes(season: Season? = nil) async throws -> [Recipe] {
        let currentSeason = season ?? Season.current
        let seasonalIngredients = currentSeason.typicalIngredients

        return try await generateRecipes(ingredients: seasonalIngredients)
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) {
        lastError = error.localizedDescription
        print("Recipe Generation Error: \(error)")
    }
}

// MARK: - Season Helper

enum Season {
    case spring
    case summer
    case fall
    case winter

    static var current: Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }

    var typicalIngredients: [String] {
        switch self {
        case .spring:
            return ["asparagus", "peas", "strawberries", "artichokes", "radishes"]
        case .summer:
            return ["tomatoes", "corn", "zucchini", "berries", "peaches"]
        case .fall:
            return ["pumpkin", "squash", "apples", "brussels sprouts", "sweet potatoes"]
        case .winter:
            return ["root vegetables", "citrus", "kale", "cabbage", "pomegranate"]
        }
    }
}
