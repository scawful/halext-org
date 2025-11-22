import {
  MdTimer,
  MdLocalFireDepartment,
  MdCheckCircle,
  MdWarning,
  MdFavorite,
  MdFavoriteBorder
} from 'react-icons/md';
import type { Recipe, DifficultyLevel } from '../../types/models';
import './RecipeCard.css';

interface RecipeCardProps {
  recipe: Recipe;
  onSelect: () => void;
  onToggleSave?: () => void;
  isSaved?: boolean;
  compact?: boolean;
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

export const RecipeCard = ({
  recipe,
  onSelect,
  onToggleSave,
  isSaved = false,
  compact = false
}: RecipeCardProps) => {
  const totalTime = recipe.total_time_minutes ||
    (recipe.prep_time_minutes || 0) + (recipe.cook_time_minutes || 0);

  const matchPercentage = recipe.match_score ? Math.round(recipe.match_score * 100) : null;

  const handleSaveClick = (e: React.MouseEvent) => {
    e.stopPropagation();
    onToggleSave?.();
  };

  if (compact) {
    return (
      <button className="recipe-card-compact" onClick={onSelect}>
        <div className="recipe-card-compact-image">
          {recipe.image_url ? (
            <img src={recipe.image_url} alt={recipe.name} />
          ) : (
            <div className="recipe-card-placeholder">
              <span>Fork and knife icon</span>
            </div>
          )}
        </div>
        <div className="recipe-card-compact-info">
          <h4>{recipe.name}</h4>
          <div className="recipe-card-compact-meta">
            <span><MdTimer /> {totalTime}m</span>
          </div>
        </div>
      </button>
    );
  }

  return (
    <article className="recipe-card" onClick={onSelect} role="button" tabIndex={0}>
      <div className="recipe-card-image">
        {recipe.image_url ? (
          <img src={recipe.image_url} alt={recipe.name} loading="lazy" />
        ) : (
          <div className="recipe-card-placeholder-image">
            <div className="placeholder-content">
              <span className="placeholder-icon">Fork/Knife</span>
              <span className="placeholder-name">{recipe.name}</span>
            </div>
          </div>
        )}
        {onToggleSave && (
          <button
            className="recipe-card-save-btn"
            onClick={handleSaveClick}
            aria-label={isSaved ? 'Remove from saved' : 'Save recipe'}
          >
            {isSaved ? <MdFavorite className="saved" /> : <MdFavoriteBorder />}
          </button>
        )}
      </div>

      <div className="recipe-card-content">
        <h3 className="recipe-card-title">{recipe.name}</h3>

        {matchPercentage !== null && (
          <div
            className={`recipe-card-match ${
              matchPercentage >= 80 ? 'high' : matchPercentage >= 50 ? 'medium' : 'low'
            }`}
          >
            <MdCheckCircle />
            <span>{matchPercentage}% match</span>
          </div>
        )}

        <div className="recipe-card-metrics">
          <span className="metric">
            <MdTimer />
            {totalTime}m
          </span>
          {recipe.nutrition?.calories !== undefined && (
            <span className="metric">
              <MdLocalFireDepartment />
              {recipe.nutrition.calories} kcal
            </span>
          )}
          {recipe.difficulty && (
            <span
              className="metric difficulty"
              style={{ color: getDifficultyColor(recipe.difficulty) }}
            >
              {getDifficultyLabel(recipe.difficulty)}
            </span>
          )}
        </div>

        {recipe.description && (
          <p className="recipe-card-description">{recipe.description}</p>
        )}

        {recipe.cuisine && (
          <span className="recipe-card-cuisine">{recipe.cuisine}</span>
        )}

        {recipe.missing_ingredients && recipe.missing_ingredients.length > 0 && (
          <div className="recipe-card-missing">
            <MdWarning />
            <span>
              Missing {recipe.missing_ingredients.length} ingredient
              {recipe.missing_ingredients.length > 1 ? 's' : ''}
            </span>
          </div>
        )}

        {recipe.tags && recipe.tags.length > 0 && (
          <div className="recipe-card-tags">
            {recipe.tags.slice(0, 3).map((tag) => (
              <span key={tag} className="tag">
                #{tag}
              </span>
            ))}
            {recipe.tags.length > 3 && (
              <span className="tag more">+{recipe.tags.length - 3}</span>
            )}
          </div>
        )}
      </div>
    </article>
  );
};
