# AI Recipe Generator - Cross-Platform Feature Documentation

## Feature Overview

The AI Recipe Generator is a comprehensive feature that allows users to generate personalized recipes, meal plans, and cooking instructions based on available ingredients, dietary restrictions, and preferences. This feature integrates seamlessly with the existing task management system to suggest recipes from shopping lists.

---

## iOS Implementation Summary

### Architecture
- **AIRecipeGenerator**: Singleton manager handling all recipe generation logic
- **RecipeModels**: Comprehensive data structures for recipes, ingredients, meal plans
- **RecipeViews**: Beautiful, Pinterest-style UI components for recipe display
- **Integration Points**: Tasks, Dashboard, and dedicated Recipe section

### Key Components

1. **Core Manager** (`AIRecipeGenerator.swift`)
   - Recipe generation from ingredients
   - Meal plan creation (3-7 days)
   - Ingredient parsing from task descriptions
   - Recipe scaling and nutritional adjustments
   - Smart batch cooking suggestions
   - Seasonal recipe recommendations

2. **UI Components**
   - `RecipeGeneratorView`: Main interface for recipe generation
   - `RecipeDetailView`: Full recipe display with step-by-step instructions
   - `RecipeCardView`: Pinterest-style recipe cards
   - `IngredientSelectorView`: Advanced ingredient and preference selection
   - `MealPlanGeneratorView`: Weekly meal planning interface

3. **Integration**
   - Task list swipe actions: "Generate Recipe" from shopping list tasks
   - Dashboard widget: "What's for Dinner?" quick access
   - Automatic ingredient extraction from task titles/descriptions

---

## Backend API Requirements

### Endpoint 1: Generate Recipes

**POST** `/api/ai/recipes/generate`

**Request Body:**
```json
{
  "ingredients": ["chicken", "rice", "broccoli", "soy sauce"],
  "dietary_restrictions": ["gluten_free", "dairy_free"],
  "cuisine_preferences": ["Asian", "Italian"],
  "difficulty_level": "beginner",
  "time_limit_minutes": 30,
  "servings": 4,
  "meal_type": "dinner"
}
```

**Response:**
```json
{
  "recipes": [
    {
      "id": "recipe-uuid-1",
      "name": "Chicken Stir Fry",
      "description": "A quick and healthy Asian-inspired chicken stir fry",
      "ingredients": [
        {
          "id": "ing-uuid-1",
          "name": "chicken breast",
          "amount": "1",
          "unit": "lb",
          "notes": "cut into bite-sized pieces",
          "is_optional": false
        },
        {
          "id": "ing-uuid-2",
          "name": "broccoli",
          "amount": "2",
          "unit": "cups",
          "notes": "florets",
          "is_optional": false
        }
      ],
      "instructions": [
        {
          "id": "step-uuid-1",
          "step_number": 1,
          "instruction": "Heat oil in a large wok over high heat",
          "time_minutes": 2,
          "image_url": null,
          "timer_name": "Heat Oil"
        },
        {
          "id": "step-uuid-2",
          "step_number": 2,
          "instruction": "Add chicken and cook until golden brown",
          "time_minutes": 8,
          "image_url": null,
          "timer_name": "Cook Chicken"
        }
      ],
      "prep_time_minutes": 15,
      "cook_time_minutes": 10,
      "total_time_minutes": 25,
      "servings": 4,
      "difficulty": "beginner",
      "cuisine": "Asian",
      "image_url": "https://example.com/images/chicken-stir-fry.jpg",
      "nutrition": {
        "calories": 320,
        "protein": 35.5,
        "carbohydrates": 28.0,
        "fat": 8.5,
        "fiber": 4.0,
        "sugar": 3.0,
        "sodium": 480.0
      },
      "tags": ["quick", "healthy", "weeknight", "gluten-free"],
      "matched_ingredients": ["chicken", "broccoli", "rice"],
      "missing_ingredients": ["soy sauce"],
      "match_score": 0.85
    }
  ],
  "total_recipes": 5,
  "match_score": 0.85
}
```

**Business Logic:**
1. Parse ingredient list and normalize names (e.g., "chicken breast" = "chicken")
2. Search recipe database or use AI to generate recipes matching criteria
3. Calculate match score: (matched_ingredients / total_required_ingredients)
4. Filter by dietary restrictions (MUST exclude allergens/restricted ingredients)
5. Filter by cuisine preferences if specified
6. Filter by difficulty level if specified
7. Filter by time limit if specified
8. Sort recipes by match_score (highest first)
9. Return top 5-10 recipes

**Error Scenarios:**
- 400: Invalid ingredients list (empty or malformed)
- 400: Invalid dietary restriction value
- 400: Invalid difficulty level
- 500: AI service unavailable
- 503: Recipe database temporarily unavailable

---

### Endpoint 2: Generate Meal Plan

**POST** `/api/ai/recipes/meal-plan`

**Request Body:**
```json
{
  "ingredients": ["chicken", "rice", "pasta", "vegetables", "eggs"],
  "days": 7,
  "dietary_restrictions": ["vegetarian"],
  "budget": 50.00,
  "meals_per_day": 3
}
```

**Response:**
```json
{
  "meal_plan": [
    {
      "id": "day-uuid-1",
      "day": "Monday",
      "meals": [
        {
          "id": "meal-uuid-1",
          "meal_type": "breakfast",
          "recipe": { /* full recipe object */ }
        },
        {
          "id": "meal-uuid-2",
          "meal_type": "lunch",
          "recipe": { /* full recipe object */ }
        },
        {
          "id": "meal-uuid-3",
          "meal_type": "dinner",
          "recipe": { /* full recipe object */ }
        }
      ]
    },
    {
      "id": "day-uuid-2",
      "day": "Tuesday",
      "meals": [ /* ... */ ]
    }
    // ... 5 more days
  ],
  "shopping_list": [
    "2 lbs chicken breast",
    "1 box pasta",
    "3 cups broccoli",
    "6 eggs",
    "1 lb rice"
  ],
  "estimated_cost": 48.50,
  "nutrition_summary": {
    "calories": 2100,
    "protein": 125.0,
    "carbohydrates": 220.0,
    "fat": 65.0,
    "fiber": 35.0,
    "sugar": 40.0,
    "sodium": 2200.0
  }
}
```

**Business Logic:**
1. Calculate total meals needed: `days * meals_per_day`
2. Distribute meal types appropriately (breakfast, lunch, dinner, snacks)
3. Optimize for ingredient reuse across days (batch cooking optimization)
4. Ensure variety: no same recipe within 3 days
5. Balance nutrition across the week
6. Stay within budget if specified
7. Respect dietary restrictions for ALL meals
8. Generate consolidated shopping list (remove duplicates, combine quantities)
9. Calculate total estimated cost
10. Calculate average daily nutrition

**Error Scenarios:**
- 400: Invalid days value (must be 3-7)
- 400: Invalid meals_per_day (must be 2-3)
- 400: Budget too low for requested meals
- 500: Unable to generate balanced meal plan

---

### Endpoint 3: Recipe Suggestions with Substitutions

**POST** `/api/ai/recipes/suggest-substitutions`

**Request Body:**
```json
{
  "ingredients": ["chicken", "pasta"],
  "recipe_type": "italian"
}
```

**Response:**
```json
{
  "recipes": [
    {
      /* full recipe object */
      "substitution_suggestions": [
        {
          "original_ingredient": "heavy cream",
          "substitutes": ["milk", "coconut milk", "cashew cream"],
          "reason": "Lower fat or dairy-free alternatives"
        }
      ]
    }
  ],
  "total_recipes": 3,
  "match_score": 0.60
}
```

**Business Logic:**
1. Generate recipes that partially match available ingredients
2. Suggest substitutions for missing ingredients
3. Prioritize common household substitutes
4. Consider dietary restrictions when suggesting substitutes
5. Provide rationale for each substitution
6. Return recipes with match score >= 0.5

---

### Endpoint 4: Analyze Ingredients

**POST** `/api/ai/recipes/analyze-ingredients`

**Request Body:**
```json
{
  "ingredients": ["chicken", "tomatoes", "pasta", "garlic", "olive oil"]
}
```

**Response:**
```json
{
  "extracted_ingredients": [
    "chicken",
    "tomatoes",
    "pasta",
    "garlic",
    "olive oil"
  ],
  "categories": [
    {
      "id": "cat-uuid-1",
      "name": "Proteins",
      "ingredients": ["chicken"]
    },
    {
      "id": "cat-uuid-2",
      "name": "Vegetables",
      "ingredients": ["tomatoes", "garlic"]
    },
    {
      "id": "cat-uuid-3",
      "name": "Grains",
      "ingredients": ["pasta"]
    },
    {
      "id": "cat-uuid-4",
      "name": "Pantry",
      "ingredients": ["olive oil"]
    }
  ],
  "suggestions": [
    "Add cheese for a complete Italian meal",
    "Consider basil or oregano for seasoning",
    "Onions would complement these flavors"
  ]
}
```

**Business Logic:**
1. Parse and normalize ingredient names
2. Remove duplicate ingredients (case-insensitive)
3. Categorize ingredients (proteins, vegetables, grains, dairy, pantry, etc.)
4. Identify cuisine patterns (e.g., tomatoes + pasta + garlic = Italian)
5. Suggest complementary ingredients
6. Flag potential allergen combinations

---

## Data Models

### Recipe Object Structure

```typescript
interface Recipe {
  id: string;
  name: string;
  description: string;
  ingredients: Ingredient[];
  instructions: CookingStep[];
  prep_time_minutes: number;
  cook_time_minutes: number;
  total_time_minutes: number;
  servings: number;
  difficulty: "beginner" | "intermediate" | "advanced" | "expert";
  cuisine: string | null;
  image_url: string | null;
  nutrition: NutritionInfo | null;
  tags: string[];
  matched_ingredients: string[] | null;
  missing_ingredients: string[] | null;
  match_score: number | null;
}

interface Ingredient {
  id: string;
  name: string;
  amount: string;
  unit: string | null;
  notes: string | null;
  is_optional: boolean;
}

interface CookingStep {
  id: string;
  step_number: number;
  instruction: string;
  time_minutes: number | null;
  image_url: string | null;
  timer_name: string | null;
}

interface NutritionInfo {
  calories: number;
  protein: number;
  carbohydrates: number;
  fat: number;
  fiber: number | null;
  sugar: number | null;
  sodium: number | null;
}
```

### Dietary Restrictions (Enum)
```
vegetarian
vegan
gluten_free
dairy_free
nut_free
kosher
halal
low_carb
low_fat
paleo
keto
```

### Difficulty Levels (Enum)
```
beginner
intermediate
advanced
expert
```

### Meal Types (Enum)
```
breakfast
lunch
dinner
snack
dessert
```

---

## State Management Requirements

### iOS Local State
- Generated recipes are cached in memory during session
- Meal plans are temporarily stored
- Favorite recipes should be persisted to local storage
- Recipe collections stored locally with sync capability

### Backend State
- No session state required (stateless API)
- User preferences (dietary restrictions, favorite cuisines) stored in user profile
- Saved recipes linked to user account
- Recipe collections managed per user

---

## Validation Rules

### Ingredients
- Minimum 1 ingredient required
- Maximum 50 ingredients per request
- Each ingredient name: 1-100 characters
- Trim whitespace, lowercase normalization

### Recipe Generation
- Time limit: 15-240 minutes
- Servings: 1-12
- Days for meal plan: 3-7
- Meals per day: 1-4

### Nutrition Calculation
- All values in metric units
- Calories: positive integer
- Macros (protein, carbs, fat): rounded to 1 decimal place
- Fiber, sugar, sodium: optional but recommended

---

## Performance Requirements

### Response Times
- Recipe generation: < 5 seconds for 5 recipes
- Meal plan generation: < 10 seconds for 7-day plan
- Ingredient analysis: < 2 seconds

### Caching Strategy
- Cache popular recipes (accessed 100+ times)
- Cache recipe database queries for 1 hour
- Invalidate cache on recipe updates

### Rate Limiting
- Authenticated users: 100 requests/hour
- Recipe generation: 20 requests/hour per user
- Meal plan generation: 10 requests/hour per user

---

## Security Considerations

### Data Privacy
- Ingredient lists may contain personal dietary information
- Saved recipes belong to individual users
- Shopping lists may reveal household information

### Input Sanitization
- Sanitize all ingredient names (prevent SQL injection)
- Validate all enum values
- Limit text field lengths
- Prevent recipe prompt injection attacks

### API Authentication
- All endpoints require valid Bearer token
- Token validated against user session
- User ID extracted from token for personalization

---

## Testing Criteria for Feature Parity

### Backend Tests
1. Recipe generation returns valid recipe objects
2. Dietary restrictions properly filter recipes
3. Match score calculation is accurate
4. Meal plan generates balanced meals
5. Shopping list consolidates ingredients correctly
6. Substitution suggestions are relevant
7. Nutrition calculations are accurate
8. Time/difficulty filters work correctly

### Web Tests
1. Recipe cards render with all information
2. Ingredient selector works across browsers
3. Recipe detail view displays all sections
4. Meal plan calendar layout is responsive
5. Shopping list export works
6. Recipe scaling recalculates properly
7. Save/favorite functionality persists
8. Share recipe generates correct format

### Cross-Platform Consistency
1. Same ingredients generate same recipes
2. Nutritional information matches across platforms
3. Recipe instructions are identical
4. Meal plans have same structure
5. Shopping lists match format
6. Difficulty ratings consistent
7. Time estimates match
8. Cuisine classifications align

---

## AI Integration Notes

### LLM Requirements
- Model must understand culinary terminology
- Should recognize ingredient variations (e.g., "tomato" = "tomatoes")
- Must respect dietary restrictions strictly (safety critical)
- Should provide creative but realistic recipes
- Needs to understand cooking techniques and times

### Prompt Engineering Guidelines
```
System: You are a professional chef AI assistant. Generate recipes that are:
1. Safe and respect ALL dietary restrictions
2. Realistic with accurate cooking times
3. Nutritionally balanced
4. Use ingredients efficiently
5. Provide clear, step-by-step instructions

User: Create 3 recipes using: [ingredients]
Restrictions: [dietary_restrictions]
Difficulty: [difficulty_level]
Time limit: [time_limit_minutes] minutes
```

### Fallback Strategy
- If AI unavailable, use pre-generated recipe database
- Implement recipe template system for common combinations
- Cache successful AI responses for reuse
- Provide manual recipe input option

---

## Future Enhancements

### Phase 2 Features
1. **Photo Recognition**: Scan fridge/pantry to detect ingredients
2. **Voice Input**: "Hey Siri, find recipes for chicken and rice"
3. **Recipe Ratings**: User reviews and ratings
4. **Social Sharing**: Share recipes with other users
5. **Cooking Mode**: Step-by-step timer-guided cooking
6. **Leftover Management**: "What can I make with leftover chicken?"
7. **Nutritional Goals**: Match recipes to calorie/macro targets
8. **Grocery Store Integration**: Direct ordering from recipe

### Platform-Specific Features

**iOS Unique:**
- Live Activities: Show cooking progress on lock screen
- Widgets: Today's recipe on home screen
- Handoff: Start recipe on iPhone, continue on iPad
- Shortcuts: Siri recipe generation
- Focus Mode: "Cooking Mode" silences notifications

**Web Unique:**
- Print-friendly recipe format
- Recipe video embedding
- Bulk recipe import/export
- Advanced filtering/search
- Recipe blog integration

---

## Example Use Cases

### Use Case 1: Quick Weeknight Dinner
**Input:**
- Ingredients: ["chicken", "pasta", "tomatoes"]
- Time limit: 30 minutes
- Difficulty: beginner

**Expected Output:**
- 5 recipes under 30 minutes
- All using provided ingredients
- Beginner-friendly instructions
- Match score > 0.8

### Use Case 2: Weekly Meal Prep
**Input:**
- Ingredients: ["chicken", "rice", "vegetables", "eggs"]
- Days: 7
- Meals per day: 3
- Dietary: ["low_carb"]

**Expected Output:**
- 21 meals (7 days × 3 meals)
- Varied recipes (no repeats within 3 days)
- Shopping list with quantities
- Estimated cost
- Low-carb recipes only

### Use Case 3: Dietary Restrictions
**Input:**
- Ingredients: ["pasta", "vegetables", "cheese"]
- Dietary: ["vegan", "gluten_free"]
- Cuisine: ["Italian"]

**Expected Output:**
- No cheese (vegan)
- Gluten-free pasta
- Italian-style recipes
- Vegan substitutes suggested

---

## Support Contact

**iOS Team:** ios-dev@halext.org
**Backend Team:** backend-dev@halext.org
**Product Team:** product@halext.org

**Documentation Version:** 1.0
**Last Updated:** 2025-01-19
**iOS Implementation:** Complete
**Backend Implementation:** Required
**Web Implementation:** Required

---

## API Endpoint Summary

| Endpoint | Method | Purpose | Priority |
|----------|--------|---------|----------|
| `/api/ai/recipes/generate` | POST | Generate recipes from ingredients | Critical |
| `/api/ai/recipes/meal-plan` | POST | Create weekly meal plans | High |
| `/api/ai/recipes/suggest-substitutions` | POST | Suggest ingredient substitutions | Medium |
| `/api/ai/recipes/analyze-ingredients` | POST | Categorize and analyze ingredients | Low |

All endpoints require Bearer token authentication and return JSON responses.
