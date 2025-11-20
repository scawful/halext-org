import { useState } from 'react'
import { MdRestaurantMenu, MdTimer, MdLocalFireDepartment, MdCalendarToday, MdShoppingCart } from 'react-icons/md'
import { generateRecipes, generateMealPlan } from '../../utils/aiApi'
import type { Recipe, MealPlanResponse } from '../../utils/aiApi'
import { useAiProvider } from '../../contexts/AiProviderContext'
import './RecipeSection.css'

interface RecipeSectionProps {
  token: string
}

export const RecipeSection = ({ token }: RecipeSectionProps) => {
  const { selectedModelId } = useAiProvider()
  const [activeTab, setActiveTab] = useState<'generate' | 'planner'>('generate')
  const [ingredients, setIngredients] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [generatedRecipes, setGeneratedRecipes] = useState<Recipe[]>([])
  const [mealPlan, setMealPlan] = useState<MealPlanResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  // Filters
  const [dietary, setDietary] = useState<string[]>([])
  const [cuisine, setCuisine] = useState<string[]>([])
  const [timeLimit, setTimeLimit] = useState<number | ''>('')
  const [days, setDays] = useState(7)

  const DIETARY_OPTIONS = ['Vegetarian', 'Vegan', 'Gluten-Free', 'Keto', 'Paleo', 'Low-Carb']
  const CUISINE_OPTIONS = ['Italian', 'Asian', 'Mexican', 'Indian', 'Mediterranean', 'American']

  const handleGenerateRecipes = async () => {
    if (!ingredients.trim()) return

    setIsLoading(true)
    setError(null)
    try {
      const response = await generateRecipes(
        token,
        ingredients.split(',').map(i => i.trim()),
        {
          dietary_restrictions: dietary,
          cuisine_preferences: cuisine,
          time_limit_minutes: timeLimit ? Number(timeLimit) : undefined
        },
        selectedModelId || undefined
      )
      setGeneratedRecipes(response.recipes)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate recipes')
    } finally {
      setIsLoading(false)
    }
  }

  const handleGenerateMealPlan = async () => {
    if (!ingredients.trim()) return

    setIsLoading(true)
    setError(null)
    try {
      const response = await generateMealPlan(
        token,
        ingredients.split(',').map(i => i.trim()),
        {
          days,
          dietary_restrictions: dietary,
          meals_per_day: 3
        },
        selectedModelId || undefined
      )
      setMealPlan(response)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate meal plan')
    } finally {
      setIsLoading(false)
    }
  }

  const toggleFilter = (list: string[], setList: (l: string[]) => void, item: string) => {
    if (list.includes(item)) {
      setList(list.filter(i => i !== item))
    } else {
      setList([...list, item])
    }
  }

  return (
    <div className="recipe-section">
      <div className="recipe-header">
        <div>
          <h2 className="text-2xl font-bold text-purple-300">AI Chef</h2>
          <p className="text-sm text-gray-400 mt-1">Generate recipes and meal plans from your ingredients</p>
        </div>
        <div className="recipe-tabs">
          <button
            className={`tab-btn ${activeTab === 'generate' ? 'active' : ''}`}
            onClick={() => setActiveTab('generate')}
          >
            <MdRestaurantMenu /> Recipes
          </button>
          <button
            className={`tab-btn ${activeTab === 'planner' ? 'active' : ''}`}
            onClick={() => setActiveTab('planner')}
          >
            <MdCalendarToday /> Meal Planner
          </button>
        </div>
      </div>

      <div className="recipe-content">
        <div className="recipe-controls">
          <div className="control-group">
            <label>Ingredients (comma separated)</label>
            <textarea
              value={ingredients}
              onChange={(e) => setIngredients(e.target.value)}
              placeholder="chicken, rice, broccoli, eggs, milk..."
              rows={3}
            />
          </div>

          <div className="filters-grid">
            <div className="control-group">
              <label>Dietary Restrictions</label>
              <div className="tags-input">
                {DIETARY_OPTIONS.map(opt => (
                  <button
                    key={opt}
                    className={`tag-btn ${dietary.includes(opt) ? 'active' : ''}`}
                    onClick={() => toggleFilter(dietary, setDietary, opt)}
                  >
                    {opt}
                  </button>
                ))}
              </div>
            </div>

            <div className="control-group">
              <label>Cuisine Preferences</label>
              <div className="tags-input">
                {CUISINE_OPTIONS.map(opt => (
                  <button
                    key={opt}
                    className={`tag-btn ${cuisine.includes(opt) ? 'active' : ''}`}
                    onClick={() => toggleFilter(cuisine, setCuisine, opt)}
                  >
                    {opt}
                  </button>
                ))}
              </div>
            </div>

            {activeTab === 'generate' ? (
              <div className="control-group">
                <label>Max Time (minutes)</label>
                <input
                  type="number"
                  value={timeLimit}
                  onChange={(e) => setTimeLimit(Number(e.target.value))}
                  placeholder="e.g. 30"
                />
              </div>
            ) : (
              <div className="control-group">
                <label>Days to Plan</label>
                <select value={days} onChange={(e) => setDays(Number(e.target.value))}>
                  <option value={3}>3 Days</option>
                  <option value={5}>5 Days</option>
                  <option value={7}>7 Days</option>
                </select>
              </div>
            )}
          </div>

          <button
            className="action-btn"
            onClick={activeTab === 'generate' ? handleGenerateRecipes : handleGenerateMealPlan}
            disabled={isLoading || !ingredients.trim()}
          >
            {isLoading ? (
              <>Generating...</>
            ) : activeTab === 'generate' ? (
              <>Find Recipes</>
            ) : (
              <>Generate Plan</>
            )}
          </button>
          <p className="model-note">
            Routed via {selectedModelId || 'system default model'}
          </p>

          {error && <div className="error-msg">{error}</div>}
        </div>

        <div className="results-area">
          {activeTab === 'generate' ? (
            <div className="recipes-grid">
              {generatedRecipes.map((recipe, i) => (
                <div key={i} className="recipe-card">
                  <div className="recipe-card-header">
                    <h3>{recipe.name}</h3>
                    <div className="recipe-metrics">
                      <span>
                        <MdTimer />{' '}
                        {recipe.total_time_minutes ||
                          (recipe.prep_time_minutes || 0) + (recipe.cook_time_minutes || 0)}
                        m
                      </span>
                      {typeof recipe.nutrition?.calories === 'number' && (
                        <span><MdLocalFireDepartment /> {recipe.nutrition?.calories} kcal</span>
                      )}
                    </div>
                  </div>
                  <p className="recipe-desc">{recipe.description}</p>
                  
                  {recipe.missing_ingredients && recipe.missing_ingredients.length > 0 && (
                    <div className="missing-ing">
                      <span className="label">Missing:</span>
                      {recipe.missing_ingredients.join(', ')}
                    </div>
                  )}

                  <div className="recipe-details">
                    <div className="ingredients-list">
                      <h4>Ingredients</h4>
                      <ul>
                        {recipe.ingredients.map((ing, j) => (
                          <li key={j}>
                            {ing.amount} {ing.unit} {ing.name}
                          </li>
                        ))}
                      </ul>
                    </div>
                    <div className="instructions-list">
                      <h4>Instructions</h4>
                      <ol>
                        {recipe.instructions.map((step, k) => (
                          <li key={k}>{step.instruction}</li>
                        ))}
                      </ol>
                    </div>
                  </div>
                </div>
              ))}
              {generatedRecipes.length === 0 && !isLoading && (
                <div className="empty-state">
                  <MdRestaurantMenu size={48} />
                  <p>Enter ingredients and find recipes!</p>
                </div>
              )}
            </div>
          ) : (
            <div className="meal-planner-view">
              {mealPlan ? (
                <>
                  <div className="plan-days">
                    {mealPlan.meal_plan.map((day) => (
                      <div key={day.id} className="day-card">
                        <h3>{day.day}</h3>
                        <div className="day-meals">
                          {day.meals.map((meal) => (
                            <div key={meal.id} className="meal-item">
                              <span className="meal-type">{meal.meal_type}</span>
                              <span className="meal-name">{meal.recipe.name}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                  <div className="shopping-list">
                    <h3><MdShoppingCart /> Shopping List</h3>
                    <div className="list-items">
                      {mealPlan.shopping_list.map((item, i) => (
                        <div key={i} className="shop-item">{item}</div>
                      ))}
                    </div>
                    {typeof mealPlan.estimated_cost === 'number' && (
                      <div className="estimated-cost">
                        Estimated cost: ${mealPlan.estimated_cost?.toFixed(2)}
                      </div>
                    )}
                    {mealPlan.nutrition_summary && (
                      <div className="nutrition-summary">
                        <span>Daily nutrition • </span>
                        {[
                          ['Calories', mealPlan.nutrition_summary.calories],
                          ['Protein', mealPlan.nutrition_summary.protein],
                          ['Carbs', mealPlan.nutrition_summary.carbohydrates],
                          ['Fat', mealPlan.nutrition_summary.fat],
                        ]
                          .filter(([, value]) => typeof value === 'number')
                          .map(([label, value]) => `${label}: ${value}`)
                          .join(' • ')}
                      </div>
                    )}
                  </div>
                </>
              ) : !isLoading && (
                <div className="empty-state">
                  <MdCalendarToday size={48} />
                  <p>Generate a weekly meal plan instantly.</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
