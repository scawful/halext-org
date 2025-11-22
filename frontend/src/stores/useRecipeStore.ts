import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { Recipe, MealPlan, RecipeGenerationFilters, DifficultyLevel } from '../types/models';
import { generateRecipes as apiGenerateRecipes, generateMealPlan as apiGenerateMealPlan } from '../utils/aiApi';
import type { Recipe as ApiRecipe, MealPlanResponse } from '../utils/aiApi';

export type RecipeViewMode = 'list' | 'generate' | 'planner' | 'detail' | 'create' | 'edit';

// Helper to convert API recipe to our model type
const convertApiRecipe = (apiRecipe: ApiRecipe): Recipe => {
  const validDifficulties: DifficultyLevel[] = ['beginner', 'intermediate', 'advanced', 'expert'];
  const difficulty = apiRecipe.difficulty && validDifficulties.includes(apiRecipe.difficulty as DifficultyLevel)
    ? (apiRecipe.difficulty as DifficultyLevel)
    : undefined;

  return {
    ...apiRecipe,
    difficulty,
  };
};

// Helper to convert API meal plan response to our model type
const convertApiMealPlan = (apiResponse: MealPlanResponse): MealPlan => {
  return {
    meal_plan: apiResponse.meal_plan.map(day => ({
      ...day,
      meals: day.meals.map(meal => ({
        ...meal,
        recipe: convertApiRecipe(meal.recipe),
      })),
    })),
    shopping_list: apiResponse.shopping_list,
    estimated_cost: apiResponse.estimated_cost,
    nutrition_summary: apiResponse.nutrition_summary,
  };
};

interface RecipeState {
  // View State
  viewMode: RecipeViewMode;
  selectedRecipe: Recipe | null;
  editingRecipe: Recipe | null;

  // Generated Data
  generatedRecipes: Recipe[];
  mealPlan: MealPlan | null;

  // Saved Recipes
  savedRecipes: Recipe[];

  // Filter State
  ingredients: string;
  dietaryFilters: string[];
  cuisineFilters: string[];
  timeLimit: number | null;
  mealPlanDays: number;

  // Loading State
  isLoading: boolean;
  error: string | null;

  // Actions
  setViewMode: (mode: RecipeViewMode) => void;
  setSelectedRecipe: (recipe: Recipe | null) => void;
  setEditingRecipe: (recipe: Recipe | null) => void;
  setIngredients: (ingredients: string) => void;
  setDietaryFilters: (filters: string[]) => void;
  setCuisineFilters: (filters: string[]) => void;
  setTimeLimit: (limit: number | null) => void;
  setMealPlanDays: (days: number) => void;
  toggleDietaryFilter: (filter: string) => void;
  toggleCuisineFilter: (filter: string) => void;

  // Recipe Operations
  generateRecipes: (token: string, modelId?: string) => Promise<void>;
  generateMealPlan: (token: string, modelId?: string) => Promise<void>;
  saveRecipe: (recipe: Recipe) => void;
  unsaveRecipe: (recipeId: string) => void;
  updateSavedRecipe: (recipe: Recipe) => void;
  deleteSavedRecipe: (recipeId: string) => void;

  // Utility
  clearError: () => void;
  clearGeneratedRecipes: () => void;
  clearMealPlan: () => void;
  scaleRecipe: (recipe: Recipe, newServings: number) => Recipe;
}

// Dietary options that match iOS
export const DIETARY_OPTIONS = [
  'Vegetarian',
  'Vegan',
  'Gluten-Free',
  'Keto',
  'Paleo',
  'Low-Carb',
  'Dairy-Free',
  'Nut-Free',
  'Low-Sodium',
  'Halal',
  'Kosher'
];

// Cuisine options that match iOS
export const CUISINE_OPTIONS = [
  'Italian',
  'Asian',
  'Mexican',
  'Indian',
  'Mediterranean',
  'American',
  'French',
  'Japanese',
  'Chinese',
  'Thai',
  'Greek',
  'Middle Eastern'
];

export const useRecipeStore = create<RecipeState>()(
  persist(
    (set, get) => ({
      // Initial State
      viewMode: 'generate',
      selectedRecipe: null,
      editingRecipe: null,
      generatedRecipes: [],
      mealPlan: null,
      savedRecipes: [],
      ingredients: '',
      dietaryFilters: [],
      cuisineFilters: [],
      timeLimit: null,
      mealPlanDays: 7,
      isLoading: false,
      error: null,

      // View Actions
      setViewMode: (mode) => set({ viewMode: mode }),
      setSelectedRecipe: (recipe) => set({ selectedRecipe: recipe }),
      setEditingRecipe: (recipe) => set({ editingRecipe: recipe }),

      // Filter Actions
      setIngredients: (ingredients) => set({ ingredients }),
      setDietaryFilters: (filters) => set({ dietaryFilters: filters }),
      setCuisineFilters: (filters) => set({ cuisineFilters: filters }),
      setTimeLimit: (limit) => set({ timeLimit: limit }),
      setMealPlanDays: (days) => set({ mealPlanDays: days }),

      toggleDietaryFilter: (filter) => {
        const current = get().dietaryFilters;
        if (current.includes(filter)) {
          set({ dietaryFilters: current.filter(f => f !== filter) });
        } else {
          set({ dietaryFilters: [...current, filter] });
        }
      },

      toggleCuisineFilter: (filter) => {
        const current = get().cuisineFilters;
        if (current.includes(filter)) {
          set({ cuisineFilters: current.filter(f => f !== filter) });
        } else {
          set({ cuisineFilters: [...current, filter] });
        }
      },

      // Recipe Generation
      generateRecipes: async (token, modelId) => {
        const { ingredients, dietaryFilters, cuisineFilters, timeLimit } = get();

        if (!ingredients.trim()) {
          set({ error: 'Please enter some ingredients first' });
          return;
        }

        set({ isLoading: true, error: null });

        try {
          const ingredientList = ingredients.split(',').map(i => i.trim()).filter(Boolean);
          const filters: RecipeGenerationFilters = {
            dietary_restrictions: dietaryFilters.length > 0 ? dietaryFilters : undefined,
            cuisine_preferences: cuisineFilters.length > 0 ? cuisineFilters : undefined,
            time_limit_minutes: timeLimit || undefined,
          };

          const response = await apiGenerateRecipes(token, ingredientList, filters, modelId);
          set({ generatedRecipes: response.recipes.map(convertApiRecipe), viewMode: 'list' });
        } catch (err) {
          set({ error: err instanceof Error ? err.message : 'Failed to generate recipes' });
        } finally {
          set({ isLoading: false });
        }
      },

      generateMealPlan: async (token, modelId) => {
        const { ingredients, dietaryFilters, mealPlanDays } = get();

        if (!ingredients.trim()) {
          set({ error: 'Please enter some ingredients first' });
          return;
        }

        set({ isLoading: true, error: null });

        try {
          const ingredientList = ingredients.split(',').map(i => i.trim()).filter(Boolean);
          const response = await apiGenerateMealPlan(
            token,
            ingredientList,
            {
              days: mealPlanDays,
              dietary_restrictions: dietaryFilters.length > 0 ? dietaryFilters : undefined,
              meals_per_day: 3,
            },
            modelId
          );
          set({ mealPlan: convertApiMealPlan(response) });
        } catch (err) {
          set({ error: err instanceof Error ? err.message : 'Failed to generate meal plan' });
        } finally {
          set({ isLoading: false });
        }
      },

      // Saved Recipe Management
      saveRecipe: (recipe) => {
        const saved = get().savedRecipes;
        if (!saved.some(r => r.id === recipe.id)) {
          const recipeToSave = { ...recipe, is_saved: true, created_at: new Date().toISOString() };
          set({ savedRecipes: [recipeToSave, ...saved] });
        }
      },

      unsaveRecipe: (recipeId) => {
        set({ savedRecipes: get().savedRecipes.filter(r => r.id !== recipeId) });
      },

      updateSavedRecipe: (recipe) => {
        set({
          savedRecipes: get().savedRecipes.map(r =>
            r.id === recipe.id ? { ...recipe, updated_at: new Date().toISOString() } : r
          ),
        });
      },

      deleteSavedRecipe: (recipeId) => {
        set({ savedRecipes: get().savedRecipes.filter(r => r.id !== recipeId) });
      },

      // Utility Actions
      clearError: () => set({ error: null }),
      clearGeneratedRecipes: () => set({ generatedRecipes: [] }),
      clearMealPlan: () => set({ mealPlan: null }),

      // Scale recipe ingredients based on servings
      scaleRecipe: (recipe, newServings) => {
        if (!recipe.servings || recipe.servings === newServings) {
          return recipe;
        }

        const ratio = newServings / recipe.servings;

        return {
          ...recipe,
          servings: newServings,
          ingredients: recipe.ingredients.map(ing => {
            if (!ing.amount) return ing;

            // Parse the amount and scale it
            const numericAmount = parseFloat(ing.amount);
            if (isNaN(numericAmount)) return ing;

            const scaledAmount = numericAmount * ratio;
            // Format to reasonable precision
            const formattedAmount = scaledAmount % 1 === 0
              ? scaledAmount.toString()
              : scaledAmount.toFixed(2).replace(/\.?0+$/, '');

            return { ...ing, amount: formattedAmount };
          }),
          nutrition: recipe.nutrition ? {
            ...recipe.nutrition,
            calories: recipe.nutrition.calories ? Math.round(recipe.nutrition.calories * ratio) : undefined,
            protein: recipe.nutrition.protein ? Math.round(recipe.nutrition.protein * ratio) : undefined,
            carbohydrates: recipe.nutrition.carbohydrates ? Math.round(recipe.nutrition.carbohydrates * ratio) : undefined,
            fat: recipe.nutrition.fat ? Math.round(recipe.nutrition.fat * ratio) : undefined,
            fiber: recipe.nutrition.fiber ? Math.round(recipe.nutrition.fiber * ratio) : undefined,
            sugar: recipe.nutrition.sugar ? Math.round(recipe.nutrition.sugar * ratio) : undefined,
            sodium: recipe.nutrition.sodium ? Math.round(recipe.nutrition.sodium * ratio) : undefined,
          } : undefined,
        };
      },
    }),
    {
      name: 'halext-recipes',
      partialize: (state) => ({
        savedRecipes: state.savedRecipes,
        dietaryFilters: state.dietaryFilters,
        cuisineFilters: state.cuisineFilters,
      }),
    }
  )
);
