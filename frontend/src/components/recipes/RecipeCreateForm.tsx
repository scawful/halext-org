import { useState, useCallback } from 'react';
import {
  MdArrowBack,
  MdSave,
  MdAdd,
  MdDelete,
  MdDragIndicator
} from 'react-icons/md';
import type { Recipe, RecipeIngredient, RecipeInstruction, DifficultyLevel } from '../../types/models';
import { CUISINE_OPTIONS } from '../../stores/useRecipeStore';
import './RecipeCreateForm.css';

interface RecipeCreateFormProps {
  initialRecipe?: Recipe;
  onSave: (recipe: Recipe) => void;
  onCancel: () => void;
  isEditing?: boolean;
}

const generateId = () => Math.random().toString(36).substring(2, 11);

const createEmptyIngredient = (): RecipeIngredient => ({
  id: generateId(),
  name: '',
  amount: '',
  unit: '',
});

const createEmptyInstruction = (stepNumber: number): RecipeInstruction => ({
  id: generateId(),
  step_number: stepNumber,
  instruction: '',
});

const DIFFICULTY_OPTIONS: { value: DifficultyLevel; label: string }[] = [
  { value: 'beginner', label: 'Easy' },
  { value: 'intermediate', label: 'Medium' },
  { value: 'advanced', label: 'Hard' },
  { value: 'expert', label: 'Expert' },
];

const UNIT_OPTIONS = [
  '', 'cup', 'cups', 'tbsp', 'tsp', 'oz', 'lb', 'g', 'kg', 'ml', 'L',
  'piece', 'pieces', 'slice', 'slices', 'clove', 'cloves', 'pinch', 'dash', 'to taste'
];

export const RecipeCreateForm = ({
  initialRecipe,
  onSave,
  onCancel,
  isEditing = false
}: RecipeCreateFormProps) => {
  const [name, setName] = useState(initialRecipe?.name || '');
  const [description, setDescription] = useState(initialRecipe?.description || '');
  const [prepTime, setPrepTime] = useState(initialRecipe?.prep_time_minutes?.toString() || '');
  const [cookTime, setCookTime] = useState(initialRecipe?.cook_time_minutes?.toString() || '');
  const [servings, setServings] = useState(initialRecipe?.servings?.toString() || '4');
  const [difficulty, setDifficulty] = useState<DifficultyLevel>(initialRecipe?.difficulty || 'intermediate');
  const [cuisine, setCuisine] = useState(initialRecipe?.cuisine || '');
  const [tags, setTags] = useState(initialRecipe?.tags?.join(', ') || '');
  const [imageUrl, setImageUrl] = useState(initialRecipe?.image_url || '');

  const [ingredients, setIngredients] = useState<RecipeIngredient[]>(
    initialRecipe?.ingredients?.length ? initialRecipe.ingredients : [createEmptyIngredient()]
  );

  const [instructions, setInstructions] = useState<RecipeInstruction[]>(
    initialRecipe?.instructions?.length ? initialRecipe.instructions : [createEmptyInstruction(1)]
  );

  const [errors, setErrors] = useState<Record<string, string>>({});

  const addIngredient = useCallback(() => {
    setIngredients(prev => [...prev, createEmptyIngredient()]);
  }, []);

  const removeIngredient = useCallback((id: string) => {
    setIngredients(prev => prev.filter(ing => ing.id !== id));
  }, []);

  const updateIngredient = useCallback((id: string, field: keyof RecipeIngredient, value: string) => {
    setIngredients(prev => prev.map(ing =>
      ing.id === id ? { ...ing, [field]: value } : ing
    ));
  }, []);

  const addInstruction = useCallback(() => {
    setInstructions(prev => [...prev, createEmptyInstruction(prev.length + 1)]);
  }, []);

  const removeInstruction = useCallback((id: string) => {
    setInstructions(prev => {
      const filtered = prev.filter(inst => inst.id !== id);
      return filtered.map((inst, idx) => ({ ...inst, step_number: idx + 1 }));
    });
  }, []);

  const updateInstruction = useCallback((id: string, field: keyof RecipeInstruction, value: string | number) => {
    setInstructions(prev => prev.map(inst =>
      inst.id === id ? { ...inst, [field]: value } : inst
    ));
  }, []);

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!name.trim()) {
      newErrors.name = 'Recipe name is required';
    }

    const validIngredients = ingredients.filter(ing => ing.name.trim());
    if (validIngredients.length === 0) {
      newErrors.ingredients = 'At least one ingredient is required';
    }

    const validInstructions = instructions.filter(inst => inst.instruction.trim());
    if (validInstructions.length === 0) {
      newErrors.instructions = 'At least one instruction is required';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!validate()) return;

    const prepTimeNum = parseInt(prepTime) || 0;
    const cookTimeNum = parseInt(cookTime) || 0;

    const recipe: Recipe = {
      id: initialRecipe?.id || generateId(),
      name: name.trim(),
      description: description.trim() || undefined,
      prep_time_minutes: prepTimeNum || undefined,
      cook_time_minutes: cookTimeNum || undefined,
      total_time_minutes: (prepTimeNum + cookTimeNum) || undefined,
      servings: parseInt(servings) || 4,
      difficulty,
      cuisine: cuisine || undefined,
      image_url: imageUrl.trim() || undefined,
      tags: tags.split(',').map(t => t.trim()).filter(Boolean),
      ingredients: ingredients
        .filter(ing => ing.name.trim())
        .map(ing => ({
          ...ing,
          name: ing.name.trim(),
          amount: ing.amount?.trim() || undefined,
          unit: ing.unit?.trim() || undefined,
        })),
      instructions: instructions
        .filter(inst => inst.instruction.trim())
        .map((inst, idx) => ({
          ...inst,
          step_number: idx + 1,
          instruction: inst.instruction.trim(),
        })),
      is_saved: true,
      created_at: initialRecipe?.created_at || new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    onSave(recipe);
  };

  return (
    <div className="recipe-create-form">
      <header className="form-header">
        <button className="back-btn" onClick={onCancel} type="button" aria-label="Cancel">
          <MdArrowBack />
        </button>
        <h2>{isEditing ? 'Edit Recipe' : 'Create Recipe'}</h2>
        <button
          type="submit"
          form="recipe-form"
          className="save-btn"
          aria-label="Save recipe"
        >
          <MdSave /> Save
        </button>
      </header>

      <form id="recipe-form" className="form-content" onSubmit={handleSubmit}>
        {/* Basic Info Section */}
        <section className="form-section">
          <h3>Basic Information</h3>

          <div className="form-group">
            <label htmlFor="recipe-name">Recipe Name *</label>
            <input
              id="recipe-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g., Classic Chicken Stir Fry"
              className={errors.name ? 'error' : ''}
            />
            {errors.name && <span className="error-text">{errors.name}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="recipe-description">Description</label>
            <textarea
              id="recipe-description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="A brief description of your recipe..."
              rows={3}
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="prep-time">Prep Time (min)</label>
              <input
                id="prep-time"
                type="number"
                value={prepTime}
                onChange={(e) => setPrepTime(e.target.value)}
                placeholder="15"
                min={0}
              />
            </div>

            <div className="form-group">
              <label htmlFor="cook-time">Cook Time (min)</label>
              <input
                id="cook-time"
                type="number"
                value={cookTime}
                onChange={(e) => setCookTime(e.target.value)}
                placeholder="30"
                min={0}
              />
            </div>

            <div className="form-group">
              <label htmlFor="servings">Servings</label>
              <input
                id="servings"
                type="number"
                value={servings}
                onChange={(e) => setServings(e.target.value)}
                placeholder="4"
                min={1}
              />
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="difficulty">Difficulty</label>
              <select
                id="difficulty"
                value={difficulty}
                onChange={(e) => setDifficulty(e.target.value as DifficultyLevel)}
              >
                {DIFFICULTY_OPTIONS.map(opt => (
                  <option key={opt.value} value={opt.value}>{opt.label}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label htmlFor="cuisine">Cuisine</label>
              <select
                id="cuisine"
                value={cuisine}
                onChange={(e) => setCuisine(e.target.value)}
              >
                <option value="">Select cuisine</option>
                {CUISINE_OPTIONS.map(c => (
                  <option key={c} value={c}>{c}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="image-url">Image URL (optional)</label>
            <input
              id="image-url"
              type="url"
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
              placeholder="https://example.com/image.jpg"
            />
          </div>

          <div className="form-group">
            <label htmlFor="tags">Tags (comma separated)</label>
            <input
              id="tags"
              type="text"
              value={tags}
              onChange={(e) => setTags(e.target.value)}
              placeholder="quick, healthy, weeknight, comfort food"
            />
          </div>
        </section>

        {/* Ingredients Section */}
        <section className="form-section">
          <div className="section-header">
            <h3>Ingredients</h3>
            <button type="button" className="add-btn" onClick={addIngredient}>
              <MdAdd /> Add Ingredient
            </button>
          </div>

          {errors.ingredients && <span className="error-text">{errors.ingredients}</span>}

          <div className="ingredients-list">
            {ingredients.map((ing, index) => (
              <div key={ing.id} className="ingredient-row">
                <span className="row-number">{index + 1}</span>
                <input
                  type="text"
                  value={ing.amount || ''}
                  onChange={(e) => updateIngredient(ing.id, 'amount', e.target.value)}
                  placeholder="1"
                  className="amount-input"
                />
                <select
                  value={ing.unit || ''}
                  onChange={(e) => updateIngredient(ing.id, 'unit', e.target.value)}
                  className="unit-select"
                >
                  {UNIT_OPTIONS.map(u => (
                    <option key={u} value={u}>{u || 'unit'}</option>
                  ))}
                </select>
                <input
                  type="text"
                  value={ing.name}
                  onChange={(e) => updateIngredient(ing.id, 'name', e.target.value)}
                  placeholder="Ingredient name"
                  className="name-input"
                />
                <button
                  type="button"
                  className="delete-btn"
                  onClick={() => removeIngredient(ing.id)}
                  disabled={ingredients.length === 1}
                  aria-label="Remove ingredient"
                >
                  <MdDelete />
                </button>
              </div>
            ))}
          </div>
        </section>

        {/* Instructions Section */}
        <section className="form-section">
          <div className="section-header">
            <h3>Instructions</h3>
            <button type="button" className="add-btn" onClick={addInstruction}>
              <MdAdd /> Add Step
            </button>
          </div>

          {errors.instructions && <span className="error-text">{errors.instructions}</span>}

          <div className="instructions-list">
            {instructions.map((inst, index) => (
              <div key={inst.id} className="instruction-row">
                <div className="step-header">
                  <MdDragIndicator className="drag-handle" />
                  <span className="step-number">Step {index + 1}</span>
                  <button
                    type="button"
                    className="delete-btn"
                    onClick={() => removeInstruction(inst.id)}
                    disabled={instructions.length === 1}
                    aria-label="Remove step"
                  >
                    <MdDelete />
                  </button>
                </div>
                <textarea
                  value={inst.instruction}
                  onChange={(e) => updateInstruction(inst.id, 'instruction', e.target.value)}
                  placeholder="Describe this step..."
                  rows={2}
                />
                <div className="step-time">
                  <label>
                    Time (optional):
                    <input
                      type="number"
                      value={inst.time_minutes || ''}
                      onChange={(e) => updateInstruction(inst.id, 'time_minutes', parseInt(e.target.value) || 0)}
                      placeholder="min"
                      min={0}
                    />
                  </label>
                </div>
              </div>
            ))}
          </div>
        </section>
      </form>
    </div>
  );
};
