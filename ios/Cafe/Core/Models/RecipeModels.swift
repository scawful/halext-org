//
//  RecipeModels.swift
//  Cafe
//
//  Recipe data models for AI-powered recipe generation
//

import Foundation

// MARK: - Recipe Request

struct RecipeGenerationRequest: Codable {
    let ingredients: [String]
    let dietaryRestrictions: [DietaryRestriction]
    let cuisinePreferences: [String]
    let difficultyLevel: DifficultyLevel?
    let timeLimitMinutes: Int?
    let servings: Int?
    let mealType: MealType?

    enum CodingKeys: String, CodingKey {
        case ingredients
        case dietaryRestrictions = "dietary_restrictions"
        case cuisinePreferences = "cuisine_preferences"
        case difficultyLevel = "difficulty_level"
        case timeLimitMinutes = "time_limit_minutes"
        case servings
        case mealType = "meal_type"
    }

    init(
        ingredients: [String],
        dietaryRestrictions: [DietaryRestriction] = [],
        cuisinePreferences: [String] = [],
        difficultyLevel: DifficultyLevel? = nil,
        timeLimitMinutes: Int? = nil,
        servings: Int? = 4,
        mealType: MealType? = nil
    ) {
        self.ingredients = ingredients
        self.dietaryRestrictions = dietaryRestrictions
        self.cuisinePreferences = cuisinePreferences
        self.difficultyLevel = difficultyLevel
        self.timeLimitMinutes = timeLimitMinutes
        self.servings = servings
        self.mealType = mealType
    }
}

struct MealPlanRequest: Codable {
    let ingredients: [String]
    let days: Int
    let dietaryRestrictions: [DietaryRestriction]
    let budget: Double?
    let mealsPerDay: Int

    enum CodingKeys: String, CodingKey {
        case ingredients
        case days
        case dietaryRestrictions = "dietary_restrictions"
        case budget
        case mealsPerDay = "meals_per_day"
    }

    init(
        ingredients: [String],
        days: Int = 7,
        dietaryRestrictions: [DietaryRestriction] = [],
        budget: Double? = nil,
        mealsPerDay: Int = 3
    ) {
        self.ingredients = ingredients
        self.days = days
        self.dietaryRestrictions = dietaryRestrictions
        self.budget = budget
        self.mealsPerDay = mealsPerDay
    }
}

// MARK: - Recipe Response

struct RecipeGenerationResponse: Codable {
    let recipes: [Recipe]
    let totalRecipes: Int
    let matchScore: Double?

    enum CodingKeys: String, CodingKey {
        case recipes
        case totalRecipes = "total_recipes"
        case matchScore = "match_score"
    }
}

struct MealPlanResponse: Codable {
    let mealPlan: [DayMealPlan]
    let shoppingList: [String]
    let estimatedCost: Double?
    let nutritionSummary: NutritionInfo?

    enum CodingKeys: String, CodingKey {
        case mealPlan = "meal_plan"
        case shoppingList = "shopping_list"
        case estimatedCost = "estimated_cost"
        case nutritionSummary = "nutrition_summary"
    }
}

struct DayMealPlan: Codable, Identifiable {
    let id: String
    let day: String
    let meals: [MealSlot]

    init(id: String = UUID().uuidString, day: String, meals: [MealSlot]) {
        self.id = id
        self.day = day
        self.meals = meals
    }
}

struct MealSlot: Codable, Identifiable {
    let id: String
    let mealType: MealType
    let recipe: Recipe

    enum CodingKeys: String, CodingKey {
        case id
        case mealType = "meal_type"
        case recipe
    }

    init(id: String = UUID().uuidString, mealType: MealType, recipe: Recipe) {
        self.id = id
        self.mealType = mealType
        self.recipe = recipe
    }
}

// MARK: - Recipe Model

struct Recipe: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let ingredients: [RecipeIngredient]
    let instructions: [CookingStep]
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let totalTimeMinutes: Int
    let servings: Int
    let difficulty: DifficultyLevel
    let cuisine: String?
    let imageURL: String?
    let nutrition: NutritionInfo?
    let tags: [String]
    let matchedIngredients: [String]?
    let missingIngredients: [String]?
    let matchScore: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, description, ingredients, instructions, servings, difficulty, cuisine, tags
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case totalTimeMinutes = "total_time_minutes"
        case imageURL = "image_url"
        case nutrition
        case matchedIngredients = "matched_ingredients"
        case missingIngredients = "missing_ingredients"
        case matchScore = "match_score"
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        ingredients: [RecipeIngredient],
        instructions: [CookingStep],
        prepTimeMinutes: Int,
        cookTimeMinutes: Int,
        totalTimeMinutes: Int,
        servings: Int,
        difficulty: DifficultyLevel,
        cuisine: String? = nil,
        imageURL: String? = nil,
        nutrition: NutritionInfo? = nil,
        tags: [String] = [],
        matchedIngredients: [String]? = nil,
        missingIngredients: [String]? = nil,
        matchScore: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.totalTimeMinutes = totalTimeMinutes
        self.servings = servings
        self.difficulty = difficulty
        self.cuisine = cuisine
        self.imageURL = imageURL
        self.nutrition = nutrition
        self.tags = tags
        self.matchedIngredients = matchedIngredients
        self.missingIngredients = missingIngredients
        self.matchScore = matchScore
    }

    // Hashable conformance for Set operations
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Recipe Components

struct RecipeIngredient: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let amount: String
    let unit: String?
    let notes: String?
    let isOptional: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, amount, unit, notes
        case isOptional = "is_optional"
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        amount: String,
        unit: String? = nil,
        notes: String? = nil,
        isOptional: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.unit = unit
        self.notes = notes
        self.isOptional = isOptional
    }

    var displayText: String {
        var text = amount
        if let unit = unit {
            text += " \(unit)"
        }
        text += " \(name)"
        if let notes = notes {
            text += " (\(notes))"
        }
        if isOptional {
            text += " (optional)"
        }
        return text
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RecipeIngredient, rhs: RecipeIngredient) -> Bool {
        lhs.id == rhs.id
    }
}

struct CookingStep: Codable, Identifiable, Hashable {
    let id: String
    let stepNumber: Int
    let instruction: String
    let timeMinutes: Int?
    let imageURL: String?
    let timerName: String?

    enum CodingKeys: String, CodingKey {
        case id, instruction
        case stepNumber = "step_number"
        case timeMinutes = "time_minutes"
        case imageURL = "image_url"
        case timerName = "timer_name"
    }

    init(
        id: String = UUID().uuidString,
        stepNumber: Int,
        instruction: String,
        timeMinutes: Int? = nil,
        imageURL: String? = nil,
        timerName: String? = nil
    ) {
        self.id = id
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.timeMinutes = timeMinutes
        self.imageURL = imageURL
        self.timerName = timerName
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CookingStep, rhs: CookingStep) -> Bool {
        lhs.id == rhs.id
    }
}

struct NutritionInfo: Codable, Hashable {
    let calories: Int
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?

    var caloriesPerServing: String {
        "\(calories) cal"
    }

    var macroSummary: String {
        "P: \(Int(protein))g | C: \(Int(carbohydrates))g | F: \(Int(fat))g"
    }
}

// MARK: - Enums

enum DietaryRestriction: String, Codable, CaseIterable, Identifiable {
    case vegetarian
    case vegan
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case nutFree = "nut_free"
    case kosher
    case halal
    case lowCarb = "low_carb"
    case lowFat = "low_fat"
    case paleo
    case keto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        case .nutFree: return "Nut-Free"
        case .kosher: return "Kosher"
        case .halal: return "Halal"
        case .lowCarb: return "Low Carb"
        case .lowFat: return "Low Fat"
        case .paleo: return "Paleo"
        case .keto: return "Keto"
        }
    }

    var icon: String {
        switch self {
        case .vegetarian: return "leaf"
        case .vegan: return "leaf.fill"
        case .glutenFree: return "g.circle"
        case .dairyFree: return "drop.triangle"
        case .nutFree: return "n.circle"
        case .kosher: return "k.circle"
        case .halal: return "h.circle"
        case .lowCarb: return "c.circle"
        case .lowFat: return "f.circle"
        case .paleo: return "p.circle"
        case .keto: return "k.square"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    case expert

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        case .expert: return "star.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack
    case dessert

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cube.fill"
        case .dessert: return "birthday.cake"
        }
    }
}

// MARK: - Cuisine Types

enum CuisineType: String, CaseIterable, Identifiable {
    case italian = "Italian"
    case chinese = "Chinese"
    case mexican = "Mexican"
    case japanese = "Japanese"
    case indian = "Indian"
    case thai = "Thai"
    case french = "French"
    case mediterranean = "Mediterranean"
    case american = "American"
    case korean = "Korean"
    case vietnamese = "Vietnamese"
    case greek = "Greek"
    case middleEastern = "Middle Eastern"
    case spanish = "Spanish"
    case caribbean = "Caribbean"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .italian: return "🇮🇹"
        case .chinese: return "🇨🇳"
        case .mexican: return "🇲🇽"
        case .japanese: return "🇯🇵"
        case .indian: return "🇮🇳"
        case .thai: return "🇹🇭"
        case .french: return "🇫🇷"
        case .mediterranean: return "🌊"
        case .american: return "🇺🇸"
        case .korean: return "🇰🇷"
        case .vietnamese: return "🇻🇳"
        case .greek: return "🇬🇷"
        case .middleEastern: return "🕌"
        case .spanish: return "🇪🇸"
        case .caribbean: return "🏝️"
        }
    }
}

// MARK: - Saved Recipe

struct SavedRecipe: Codable, Identifiable {
    let id: String
    let recipeId: String
    let userId: Int
    let savedAt: Date
    let notes: String?
    let rating: Int?
    let collectionIds: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case userId = "user_id"
        case savedAt = "saved_at"
        case notes
        case rating
        case collectionIds = "collection_ids"
    }
}

struct RecipeCollection: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let recipeIds: [String]
    let createdAt: Date
    let icon: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, icon
        case recipeIds = "recipe_ids"
        case createdAt = "created_at"
    }
}

// MARK: - Ingredient Analysis

struct IngredientAnalysis: Codable {
    let extractedIngredients: [String]
    let categories: [IngredientCategory]
    let suggestions: [String]

    enum CodingKeys: String, CodingKey {
        case extractedIngredients = "extracted_ingredients"
        case categories
        case suggestions
    }
}

struct IngredientCategory: Codable, Identifiable {
    let id: String
    let name: String
    let ingredients: [String]

    init(id: String = UUID().uuidString, name: String, ingredients: [String]) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
    }
}
