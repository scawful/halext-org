import { useState, useMemo } from 'react';
import {
  MdArrowBack,
  MdFavorite,
  MdFavoriteBorder,
  MdTimer,
  MdPerson,
  MdAdd,
  MdRemove,
  MdCheckCircle,
  MdRadioButtonUnchecked,
  MdShare,
  MdShoppingCart,
  MdWarning
} from 'react-icons/md';
import type { Recipe, DifficultyLevel } from '../../types/models';
import { useRecipeStore } from '../../stores/useRecipeStore';
import './RecipeDetailView.css';

interface RecipeDetailViewProps {
  recipe: Recipe;
  onBack: () => void;
  onToggleSave?: () => void;
  isSaved?: boolean;
}

const getDifficultyColor = (difficulty?: DifficultyLevel): string => {
  switch (difficulty) {
    case 'beginner': return '#22c55e';
    case 'intermediate': return '#3b82f6';
    case 'advanced': return '#f97316';
    case 'expert': return '#ef4444';
    default: return '#888';
  }
};

const getDifficultyLabel = (difficulty?: DifficultyLevel): string => {
  switch (difficulty) {
    case 'beginner': return 'Easy';
    case 'intermediate': return 'Medium';
    case 'advanced': return 'Hard';
    case 'expert': return 'Expert';
    default: return 'Unknown';
  }
};

export const RecipeDetailView = ({
  recipe,
  onBack,
  onToggleSave,
  isSaved = false
}: RecipeDetailViewProps) => {
  const { scaleRecipe } = useRecipeStore();

  const [currentServings, setCurrentServings] = useState(recipe.servings || 4);
  const [checkedIngredients, setCheckedIngredients] = useState<Set<string>>(new Set());
  const [completedSteps, setCompletedSteps] = useState<Set<string>>(new Set());

  const scaledRecipe = useMemo(() => {
    return scaleRecipe(recipe, currentServings);
  }, [recipe, currentServings, scaleRecipe]);

  const toggleIngredient = (id: string) => {
    const newChecked = new Set(checkedIngredients);
    if (newChecked.has(id)) {
      newChecked.delete(id);
    } else {
      newChecked.add(id);
    }
    setCheckedIngredients(newChecked);
  };

  const toggleStep = (id: string) => {
    const newCompleted = new Set(completedSteps);
    if (newCompleted.has(id)) {
      newCompleted.delete(id);
    } else {
      newCompleted.add(id);
    }
    setCompletedSteps(newCompleted);
  };

  const handleShare = async () => {
    const shareText = generateShareText();
    if (navigator.share) {
      try {
        await navigator.share({
          title: recipe.name,
          text: shareText,
        });
      } catch (err) {
        // User cancelled or share failed
        console.log('Share cancelled');
      }
    } else {
      // Fallback: copy to clipboard
      await navigator.clipboard.writeText(shareText);
      alert('Recipe copied to clipboard!');
    }
  };

  const generateShareText = (): string => {
    let text = `${recipe.name}\n\n`;
    if (recipe.description) {
      text += `${recipe.description}\n\n`;
    }
    text += `Ingredients:\n`;
    for (const ing of scaledRecipe.ingredients) {
      const amount = ing.amount ? `${ing.amount} ` : '';
      const unit = ing.unit ? `${ing.unit} ` : '';
      text += `- ${amount}${unit}${ing.name}\n`;
    }
    text += `\nInstructions:\n`;
    for (const step of recipe.instructions) {
      text += `${step.step_number}. ${step.instruction}\n`;
    }
    return text;
  };

  const totalTime = recipe.total_time_minutes ||
    (recipe.prep_time_minutes || 0) + (recipe.cook_time_minutes || 0);

  return (
    <div className="recipe-detail">
      <header className="recipe-detail-header">
        <button className="back-btn" onClick={onBack} aria-label="Go back">
          <MdArrowBack />
        </button>
        <h2>{recipe.name}</h2>
        <div className="header-actions">
          <button className="action-btn" onClick={handleShare} aria-label="Share recipe">
            <MdShare />
          </button>
          {onToggleSave && (
            <button
              className={`action-btn save-btn ${isSaved ? 'saved' : ''}`}
              onClick={onToggleSave}
              aria-label={isSaved ? 'Remove from saved' : 'Save recipe'}
            >
              {isSaved ? <MdFavorite /> : <MdFavoriteBorder />}
            </button>
          )}
        </div>
      </header>

      <div className="recipe-detail-content">
        {/* Hero Section */}
        <section className="recipe-hero">
          {recipe.image_url ? (
            <img src={recipe.image_url} alt={recipe.name} className="recipe-image" />
          ) : (
            <div className="recipe-image-placeholder">
              <span>Recipe Image</span>
            </div>
          )}
        </section>

        {/* Recipe Info */}
        <section className="recipe-info-section">
          <h1 className="recipe-title">{recipe.name}</h1>
          {recipe.cuisine && (
            <span className="recipe-cuisine">{recipe.cuisine} Cuisine</span>
          )}
          {recipe.description && (
            <p className="recipe-description">{recipe.description}</p>
          )}
        </section>

        {/* Quick Stats */}
        <section className="recipe-stats">
          <div className="stat-item">
            <MdTimer className="stat-icon" />
            <div className="stat-content">
              <span className="stat-value">{totalTime}m</span>
              <span className="stat-label">Total Time</span>
            </div>
          </div>
          {recipe.prep_time_minutes && (
            <div className="stat-item">
              <span className="stat-icon-text">Prep</span>
              <div className="stat-content">
                <span className="stat-value">{recipe.prep_time_minutes}m</span>
                <span className="stat-label">Prep Time</span>
              </div>
            </div>
          )}
          {recipe.difficulty && (
            <div className="stat-item">
              <span
                className="stat-icon-text"
                style={{ color: getDifficultyColor(recipe.difficulty) }}
              >
                {getDifficultyLabel(recipe.difficulty)}
              </span>
              <div className="stat-content">
                <span className="stat-label">Difficulty</span>
              </div>
            </div>
          )}
        </section>

        {/* Match Info */}
        {(recipe.match_score !== undefined || (recipe.missing_ingredients && recipe.missing_ingredients.length > 0)) && (
          <section className="recipe-match-section">
            {recipe.match_score !== undefined && (
              <div className="match-score">
                <MdCheckCircle className="match-icon" />
                <span>You have {Math.round(recipe.match_score * 100)}% of ingredients</span>
              </div>
            )}
            {recipe.missing_ingredients && recipe.missing_ingredients.length > 0 && (
              <div className="missing-ingredients">
                <h4><MdWarning /> Missing Ingredients</h4>
                <ul>
                  {recipe.missing_ingredients.map((ing, i) => (
                    <li key={i}>
                      <MdShoppingCart /> {ing}
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </section>
        )}

        {/* Nutrition */}
        {recipe.nutrition && (
          <section className="recipe-nutrition">
            <h3>Nutrition per serving</h3>
            <div className="nutrition-grid">
              {recipe.nutrition.calories !== undefined && (
                <div className="nutrition-item">
                  <span className="nutrition-value">{recipe.nutrition.calories}</span>
                  <span className="nutrition-unit">kcal</span>
                  <span className="nutrition-label">Calories</span>
                </div>
              )}
              {recipe.nutrition.protein !== undefined && (
                <div className="nutrition-item">
                  <span className="nutrition-value">{recipe.nutrition.protein}</span>
                  <span className="nutrition-unit">g</span>
                  <span className="nutrition-label">Protein</span>
                </div>
              )}
              {recipe.nutrition.carbohydrates !== undefined && (
                <div className="nutrition-item">
                  <span className="nutrition-value">{recipe.nutrition.carbohydrates}</span>
                  <span className="nutrition-unit">g</span>
                  <span className="nutrition-label">Carbs</span>
                </div>
              )}
              {recipe.nutrition.fat !== undefined && (
                <div className="nutrition-item">
                  <span className="nutrition-value">{recipe.nutrition.fat}</span>
                  <span className="nutrition-unit">g</span>
                  <span className="nutrition-label">Fat</span>
                </div>
              )}
            </div>
          </section>
        )}

        {/* Ingredients */}
        <section className="recipe-ingredients">
          <div className="section-header">
            <h3>Ingredients</h3>
            <div className="servings-control">
              <button
                onClick={() => setCurrentServings(Math.max(1, currentServings - 1))}
                disabled={currentServings <= 1}
                aria-label="Decrease servings"
              >
                <MdRemove />
              </button>
              <span className="servings-display">
                <MdPerson />
                {currentServings} servings
              </span>
              <button
                onClick={() => setCurrentServings(currentServings + 1)}
                aria-label="Increase servings"
              >
                <MdAdd />
              </button>
            </div>
          </div>
          <ul className="ingredients-list">
            {scaledRecipe.ingredients.map((ing) => {
              const isChecked = checkedIngredients.has(ing.id);
              return (
                <li
                  key={ing.id}
                  className={`ingredient-item ${isChecked ? 'checked' : ''}`}
                  onClick={() => toggleIngredient(ing.id)}
                >
                  {isChecked ? <MdCheckCircle className="check-icon checked" /> : <MdRadioButtonUnchecked className="check-icon" />}
                  <span className="ingredient-text">
                    {ing.amount && <strong>{ing.amount}</strong>}
                    {ing.unit && <span className="unit">{ing.unit}</span>}
                    <span className="name">{ing.name}</span>
                    {ing.is_optional && <span className="optional">(optional)</span>}
                    {ing.notes && <span className="notes">- {ing.notes}</span>}
                  </span>
                </li>
              );
            })}
          </ul>
        </section>

        {/* Instructions */}
        <section className="recipe-instructions">
          <h3>Instructions</h3>
          <ol className="instructions-list">
            {recipe.instructions.map((step) => {
              const isCompleted = completedSteps.has(step.id);
              return (
                <li
                  key={step.id}
                  className={`instruction-step ${isCompleted ? 'completed' : ''}`}
                  onClick={() => toggleStep(step.id)}
                >
                  <div className="step-number">
                    {isCompleted ? (
                      <MdCheckCircle className="step-check" />
                    ) : (
                      <span>{step.step_number}</span>
                    )}
                  </div>
                  <div className="step-content">
                    <p className="step-instruction">{step.instruction}</p>
                    {step.time_minutes && (
                      <span className="step-time">
                        <MdTimer /> {step.time_minutes} minutes
                      </span>
                    )}
                  </div>
                </li>
              );
            })}
          </ol>
        </section>

        {/* Tags */}
        {recipe.tags && recipe.tags.length > 0 && (
          <section className="recipe-tags-section">
            <h3>Tags</h3>
            <div className="tags-list">
              {recipe.tags.map((tag) => (
                <span key={tag} className="tag">#{tag}</span>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
};
