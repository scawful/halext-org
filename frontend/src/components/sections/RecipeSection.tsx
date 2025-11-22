import { useEffect } from 'react';
import {
  MdRestaurantMenu,
  MdCalendarToday,
  MdAutoAwesome,
  MdFavorite,
  MdShoppingCart,
  MdAdd,
} from 'react-icons/md';
import { useAiProvider } from '../../contexts/AiProviderContext';
import { useRecipeStore, DIETARY_OPTIONS, CUISINE_OPTIONS } from '../../stores/useRecipeStore';
import { RecipeCard } from '../recipes/RecipeCard';
import { RecipeDetailView } from '../recipes/RecipeDetailView';
import { RecipeCreateForm } from '../recipes/RecipeCreateForm';
import type { Recipe } from '../../types/models';
import './RecipeSection.css';

interface RecipeSectionProps {
  token: string;
}

export const RecipeSection = ({ token }: RecipeSectionProps) => {
  const { selectedModelId } = useAiProvider();

  const {
    viewMode,
    setViewMode,
    selectedRecipe,
    setSelectedRecipe,
    editingRecipe,
    setEditingRecipe,
    generatedRecipes,
    mealPlan,
    savedRecipes,
    ingredients,
    setIngredients,
    dietaryFilters,
    toggleDietaryFilter,
    cuisineFilters,
    toggleCuisineFilter,
    timeLimit,
    setTimeLimit,
    mealPlanDays,
    setMealPlanDays,
    isLoading,
    error,
    clearError,
    generateRecipes,
    generateMealPlan,
    saveRecipe,
    unsaveRecipe,
  } = useRecipeStore();

  // Clear error on mount
  useEffect(() => {
    clearError();
  }, [clearError]);

  const handleGenerateRecipes = () => {
    generateRecipes(token, selectedModelId || undefined);
  };

  const handleGenerateMealPlan = () => {
    generateMealPlan(token, selectedModelId || undefined);
  };

  const handleSelectRecipe = (recipe: Recipe) => {
    setSelectedRecipe(recipe);
    setViewMode('detail');
  };

  const handleBackFromDetail = () => {
    setSelectedRecipe(null);
    // Go back to list if we have generated recipes, otherwise go to generate
    setViewMode(generatedRecipes.length > 0 ? 'list' : 'generate');
  };

  const handleToggleSave = (recipe: Recipe) => {
    const isSaved = savedRecipes.some((r) => r.id === recipe.id);
    if (isSaved) {
      unsaveRecipe(recipe.id);
    } else {
      saveRecipe(recipe);
    }
  };

  const isRecipeSaved = (recipe: Recipe): boolean => {
    return savedRecipes.some((r) => r.id === recipe.id);
  };

  const handleCreateRecipe = () => {
    setEditingRecipe(null);
    setViewMode('create');
  };

  const handleSaveCreatedRecipe = (recipe: Recipe) => {
    saveRecipe(recipe);
    setViewMode('list');
  };

  const handleCancelCreate = () => {
    setEditingRecipe(null);
    setViewMode(savedRecipes.length > 0 ? 'list' : 'generate');
  };

  // Detail view
  if (viewMode === 'detail' && selectedRecipe) {
    return (
      <RecipeDetailView
        recipe={selectedRecipe}
        onBack={handleBackFromDetail}
        onToggleSave={() => handleToggleSave(selectedRecipe)}
        isSaved={isRecipeSaved(selectedRecipe)}
      />
    );
  }

  // Create/Edit view
  if (viewMode === 'create' || viewMode === 'edit') {
    return (
      <RecipeCreateForm
        initialRecipe={editingRecipe || undefined}
        onSave={handleSaveCreatedRecipe}
        onCancel={handleCancelCreate}
        isEditing={viewMode === 'edit'}
      />
    );
  }

  // Main view with tabs
  return (
    <div className="recipe-section">
      <header className="recipe-header">
        <div className="header-info">
          <h2>AI Chef</h2>
          <p>Generate recipes and meal plans from your ingredients</p>
        </div>
        <div className="recipe-tabs">
          <button
            className={`tab-btn ${viewMode === 'generate' ? 'active' : ''}`}
            onClick={() => setViewMode('generate')}
          >
            <MdAutoAwesome /> Generate
          </button>
          <button
            className={`tab-btn ${viewMode === 'list' ? 'active' : ''}`}
            onClick={() => setViewMode('list')}
            disabled={generatedRecipes.length === 0 && savedRecipes.length === 0}
          >
            <MdRestaurantMenu /> Recipes
            {(generatedRecipes.length > 0 || savedRecipes.length > 0) && (
              <span className="tab-badge">
                {generatedRecipes.length + savedRecipes.length}
              </span>
            )}
          </button>
          <button
            className={`tab-btn ${viewMode === 'planner' ? 'active' : ''}`}
            onClick={() => setViewMode('planner')}
          >
            <MdCalendarToday /> Meal Planner
          </button>
        </div>
      </header>

      <div className="recipe-content">
        {/* Controls Panel */}
        <aside className="recipe-controls">
          <div className="control-group">
            <label>Ingredients (comma separated)</label>
            <textarea
              value={ingredients}
              onChange={(e) => setIngredients(e.target.value)}
              placeholder="chicken, rice, broccoli, garlic, soy sauce..."
              rows={3}
            />
          </div>

          <div className="filters-section">
            <div className="control-group">
              <label>Dietary Restrictions</label>
              <div className="tags-input">
                {DIETARY_OPTIONS.map((opt) => (
                  <button
                    key={opt}
                    type="button"
                    className={`tag-btn ${dietaryFilters.includes(opt) ? 'active' : ''}`}
                    onClick={() => toggleDietaryFilter(opt)}
                  >
                    {opt}
                  </button>
                ))}
              </div>
            </div>

            <div className="control-group">
              <label>Cuisine Preferences</label>
              <div className="tags-input">
                {CUISINE_OPTIONS.map((opt) => (
                  <button
                    key={opt}
                    type="button"
                    className={`tag-btn ${cuisineFilters.includes(opt) ? 'active' : ''}`}
                    onClick={() => toggleCuisineFilter(opt)}
                  >
                    {opt}
                  </button>
                ))}
              </div>
            </div>

            {viewMode === 'generate' || viewMode === 'list' ? (
              <div className="control-group">
                <label>Max Cooking Time (minutes)</label>
                <input
                  type="number"
                  value={timeLimit || ''}
                  onChange={(e) => setTimeLimit(e.target.value ? Number(e.target.value) : null)}
                  placeholder="e.g. 30"
                  min={5}
                  max={240}
                />
              </div>
            ) : (
              <div className="control-group">
                <label>Days to Plan</label>
                <select value={mealPlanDays} onChange={(e) => setMealPlanDays(Number(e.target.value))}>
                  <option value={3}>3 Days</option>
                  <option value={5}>5 Days</option>
                  <option value={7}>7 Days</option>
                  <option value={14}>2 Weeks</option>
                </select>
              </div>
            )}
          </div>

          <button
            className="action-btn primary"
            onClick={viewMode === 'planner' ? handleGenerateMealPlan : handleGenerateRecipes}
            disabled={isLoading || !ingredients.trim()}
          >
            {isLoading ? (
              <>
                <span className="spinner" /> Generating...
              </>
            ) : viewMode === 'planner' ? (
              <>
                <MdCalendarToday /> Generate Meal Plan
              </>
            ) : (
              <>
                <MdAutoAwesome /> Find Recipes
              </>
            )}
          </button>

          <p className="model-note">
            Using: {selectedModelId || 'system default model'}
          </p>

          {error && (
            <div className="error-msg">
              {error}
              <button onClick={clearError} className="dismiss-btn">
                Dismiss
              </button>
            </div>
          )}

          {/* Saved Recipes Quick Access */}
          {savedRecipes.length > 0 && (
            <div className="saved-recipes-panel">
              <h4>
                <MdFavorite /> Saved Recipes ({savedRecipes.length})
              </h4>
              <div className="saved-recipes-list">
                {savedRecipes.slice(0, 5).map((recipe) => (
                  <RecipeCard
                    key={recipe.id}
                    recipe={recipe}
                    onSelect={() => handleSelectRecipe(recipe)}
                    compact
                  />
                ))}
                {savedRecipes.length > 5 && (
                  <button
                    className="view-all-btn"
                    onClick={() => setViewMode('list')}
                  >
                    View all {savedRecipes.length} recipes
                  </button>
                )}
              </div>
            </div>
          )}

          <button className="action-btn secondary" onClick={handleCreateRecipe}>
            <MdAdd /> Create Custom Recipe
          </button>
        </aside>

        {/* Main Content Area */}
        <main className="results-area">
          {viewMode === 'generate' && (
            <div className="generate-view">
              {generatedRecipes.length > 0 ? (
                <>
                  <div className="results-header">
                    <h3>Generated Recipes ({generatedRecipes.length})</h3>
                    <button onClick={() => setViewMode('list')}>View All</button>
                  </div>
                  <div className="recipes-preview">
                    {generatedRecipes.slice(0, 4).map((recipe) => (
                      <RecipeCard
                        key={recipe.id}
                        recipe={recipe}
                        onSelect={() => handleSelectRecipe(recipe)}
                        onToggleSave={() => handleToggleSave(recipe)}
                        isSaved={isRecipeSaved(recipe)}
                      />
                    ))}
                  </div>
                  {generatedRecipes.length > 4 && (
                    <button className="view-more-btn" onClick={() => setViewMode('list')}>
                      View {generatedRecipes.length - 4} more recipes
                    </button>
                  )}
                </>
              ) : (
                <div className="empty-state">
                  <MdRestaurantMenu size={64} />
                  <h3>AI-Powered Recipe Generation</h3>
                  <p>
                    Enter the ingredients you have on hand, set your preferences,
                    and let AI generate personalized recipes for you.
                  </p>
                  <ul className="feature-list">
                    <li>Get recipes matched to your available ingredients</li>
                    <li>See what you're missing and match percentages</li>
                    <li>Filter by dietary needs and cuisine preferences</li>
                    <li>Save favorites for quick access later</li>
                  </ul>
                </div>
              )}
            </div>
          )}

          {viewMode === 'list' && (
            <div className="list-view">
              {generatedRecipes.length > 0 && (
                <section className="recipe-list-section">
                  <h3>Generated Recipes</h3>
                  <div className="recipes-grid">
                    {generatedRecipes.map((recipe) => (
                      <RecipeCard
                        key={recipe.id}
                        recipe={recipe}
                        onSelect={() => handleSelectRecipe(recipe)}
                        onToggleSave={() => handleToggleSave(recipe)}
                        isSaved={isRecipeSaved(recipe)}
                      />
                    ))}
                  </div>
                </section>
              )}

              {savedRecipes.length > 0 && (
                <section className="recipe-list-section">
                  <h3>
                    <MdFavorite /> Saved Recipes
                  </h3>
                  <div className="recipes-grid">
                    {savedRecipes.map((recipe) => (
                      <RecipeCard
                        key={recipe.id}
                        recipe={recipe}
                        onSelect={() => handleSelectRecipe(recipe)}
                        onToggleSave={() => handleToggleSave(recipe)}
                        isSaved={true}
                      />
                    ))}
                  </div>
                </section>
              )}

              {generatedRecipes.length === 0 && savedRecipes.length === 0 && (
                <div className="empty-state">
                  <MdRestaurantMenu size={64} />
                  <h3>No Recipes Yet</h3>
                  <p>Generate some recipes or create your own to get started.</p>
                </div>
              )}
            </div>
          )}

          {viewMode === 'planner' && (
            <div className="planner-view">
              {mealPlan ? (
                <>
                  <div className="meal-plan-grid">
                    {mealPlan.meal_plan.map((day) => (
                      <div key={day.id} className="day-card">
                        <h3>{day.day}</h3>
                        <div className="day-meals">
                          {day.meals.map((meal) => (
                            <div
                              key={meal.id}
                              className="meal-item"
                              onClick={() => handleSelectRecipe(meal.recipe)}
                            >
                              <span className="meal-type">{meal.meal_type}</span>
                              <span className="meal-name">{meal.recipe.name}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="shopping-list">
                    <h3>
                      <MdShoppingCart /> Shopping List
                    </h3>
                    <div className="shopping-items">
                      {mealPlan.shopping_list.map((item, i) => (
                        <div key={i} className="shop-item">
                          {item}
                        </div>
                      ))}
                    </div>
                    {mealPlan.estimated_cost !== undefined && (
                      <div className="estimated-cost">
                        Estimated Cost: ${mealPlan.estimated_cost.toFixed(2)}
                      </div>
                    )}
                    {mealPlan.nutrition_summary && (
                      <div className="nutrition-summary">
                        <span>Daily Averages: </span>
                        {mealPlan.nutrition_summary.calories && (
                          <span>{mealPlan.nutrition_summary.calories} cal</span>
                        )}
                        {mealPlan.nutrition_summary.protein && (
                          <span>{mealPlan.nutrition_summary.protein}g protein</span>
                        )}
                        {mealPlan.nutrition_summary.carbohydrates && (
                          <span>{mealPlan.nutrition_summary.carbohydrates}g carbs</span>
                        )}
                        {mealPlan.nutrition_summary.fat && (
                          <span>{mealPlan.nutrition_summary.fat}g fat</span>
                        )}
                      </div>
                    )}
                  </div>
                </>
              ) : (
                <div className="empty-state">
                  <MdCalendarToday size={64} />
                  <h3>AI Meal Planner</h3>
                  <p>
                    Plan your week's meals based on what you have. Get a complete
                    shopping list and nutrition summary.
                  </p>
                  <ul className="feature-list">
                    <li>Plan meals for 3-14 days</li>
                    <li>Balanced nutrition across days</li>
                    <li>Auto-generated shopping list</li>
                    <li>Estimated cost calculation</li>
                  </ul>
                </div>
              )}
            </div>
          )}
        </main>
      </div>
    </div>
  );
};
