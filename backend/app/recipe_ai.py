"""
AI-powered recipe generation, meal planning, and ingredient analysis
"""
import json
import uuid
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.ai import AiGateway


class AiRecipeGenerator:
    """AI assistant for generating recipes from ingredients"""

    def __init__(self, ai_gateway: AiGateway, user_id: Optional[int] = None):
        self.ai = ai_gateway
        self.user_id = user_id

    async def generate_recipes(
        self,
        ingredients: List[str],
        dietary_restrictions: Optional[List[str]] = None,
        cuisine_preferences: Optional[List[str]] = None,
        difficulty_level: Optional[str] = None,
        time_limit_minutes: Optional[int] = None,
        servings: Optional[int] = None,
        meal_type: Optional[str] = None,
        model_identifier: Optional[str] = None,
        db: Optional[Session] = None,
    ) -> Dict[str, Any]:
        """
        Generate recipes based on available ingredients.

        Args:
            ingredients: List of available ingredients
            dietary_restrictions: e.g., ["vegetarian", "gluten_free"]
            cuisine_preferences: e.g., ["Italian", "Mexican"]
            difficulty_level: "easy", "intermediate", or "advanced"
            time_limit_minutes: Maximum cooking time
            servings: Number of servings needed
            meal_type: e.g., "breakfast", "lunch", "dinner", "snack"

        Returns:
            Dictionary with recipes list and metadata
        """
        prompt = self._create_recipe_generation_prompt(
            ingredients,
            dietary_restrictions or [],
            cuisine_preferences or [],
            difficulty_level,
            time_limit_minutes,
            servings,
            meal_type
        )

        # Call AI
        response = await self.ai.generate_reply(
            prompt,
            user_id=self.user_id,
            model_identifier=model_identifier,
            db=db,
        )

        # Parse response
        parsed = self._parse_recipe_response(response, ingredients)

        return parsed

    async def generate_meal_plan(
        self,
        ingredients: List[str],
        days: int,
        dietary_restrictions: Optional[List[str]] = None,
        budget: Optional[float] = None,
        meals_per_day: int = 3,
        model_identifier: Optional[str] = None,
        db: Optional[Session] = None,
    ) -> Dict[str, Any]:
        """
        Generate a meal plan for multiple days.

        Args:
            ingredients: Available ingredients to use
            days: Number of days to plan (3-7)
            dietary_restrictions: Dietary requirements
            budget: Optional budget constraint
            meals_per_day: Number of meals per day (1-4)

        Returns:
            Dictionary with meal plan, shopping list, and nutrition summary
        """
        prompt = self._create_meal_plan_prompt(
            ingredients,
            days,
            dietary_restrictions or [],
            budget,
            meals_per_day
        )

        response = await self.ai.generate_reply(
            prompt,
            user_id=self.user_id,
            model_identifier=model_identifier,
            db=db,
        )
        parsed = self._parse_meal_plan_response(response, days)

        return parsed

    async def suggest_substitutions(
        self,
        ingredients: List[str],
        recipe_type: Optional[str] = None,
        model_identifier: Optional[str] = None,
        db: Optional[Session] = None,
    ) -> Dict[str, Any]:
        """
        Suggest ingredient substitutions and alternative recipes.

        Args:
            ingredients: Available ingredients
            recipe_type: Type of recipe (optional context)

        Returns:
            Dictionary with recipes and substitution suggestions
        """
        prompt = self._create_substitution_prompt(ingredients, recipe_type)
        response = await self.ai.generate_reply(
            prompt,
            user_id=self.user_id,
            model_identifier=model_identifier,
            db=db,
        )
        parsed = self._parse_recipe_response(response, ingredients, include_substitutions=True)

        return parsed

    async def analyze_ingredients(
        self,
        ingredients: List[str],
        model_identifier: Optional[str] = None,
        db: Optional[Session] = None,
    ) -> Dict[str, Any]:
        """
        Analyze and categorize ingredients.

        Args:
            ingredients: List of ingredient strings (may include quantities)

        Returns:
            Dictionary with categorized ingredients and suggestions
        """
        prompt = self._create_analysis_prompt(ingredients)
        response = await self.ai.generate_reply(
            prompt,
            user_id=self.user_id,
            model_identifier=model_identifier,
            db=db,
        )
        parsed = self._parse_analysis_response(response)

        return parsed

    def _create_recipe_generation_prompt(
        self,
        ingredients: List[str],
        dietary_restrictions: List[str],
        cuisine_preferences: List[str],
        difficulty: Optional[str],
        time_limit: Optional[int],
        servings: Optional[int],
        meal_type: Optional[str]
    ) -> str:
        """Create prompt for recipe generation"""
        constraints = []

        if dietary_restrictions:
            constraints.append(f"Dietary restrictions: {', '.join(dietary_restrictions)}")
        if cuisine_preferences:
            constraints.append(f"Cuisine preferences: {', '.join(cuisine_preferences)}")
        if difficulty:
            constraints.append(f"Difficulty level: {difficulty}")
        if time_limit:
            constraints.append(f"Maximum cooking time: {time_limit} minutes")
        if servings:
            constraints.append(f"Servings: {servings}")
        if meal_type:
            constraints.append(f"Meal type: {meal_type}")

        constraints_text = "\n".join(constraints) if constraints else "No specific constraints"

        return f"""Generate 2-3 recipes using the following available ingredients. Return ONLY valid JSON.

Available Ingredients:
{', '.join(ingredients)}

Constraints:
{constraints_text}

Return a JSON object with this structure:
{{
  "recipes": [
    {{
      "id": "unique-uuid",
      "name": "Recipe Name",
      "description": "Brief description",
      "ingredients": [
        {{
          "id": "uuid",
          "name": "ingredient name",
          "amount": "2",
          "unit": "cups",
          "notes": "optional notes",
          "is_optional": false
        }}
      ],
      "instructions": [
        {{
          "id": "uuid",
          "step_number": 1,
          "instruction": "Detailed step",
          "time_minutes": 10,
          "image_url": null,
          "timer_name": null
        }}
      ],
      "prep_time_minutes": 15,
      "cook_time_minutes": 30,
      "total_time_minutes": 45,
      "servings": 4,
      "difficulty": "easy|intermediate|advanced",
      "cuisine": "Italian",
      "image_url": null,
      "nutrition": {{
        "calories": 450,
        "protein": 25.5,
        "carbohydrates": 50.0,
        "fat": 15.0,
        "fiber": 5.0,
        "sugar": 8.0,
        "sodium": 600.0
      }},
      "tags": ["healthy", "quick"],
      "matched_ingredients": ["ingredient1", "ingredient2"],
      "missing_ingredients": ["ingredient3"],
      "match_score": 0.85
    }}
  ]
}}

IMPORTANT:
- Prioritize recipes that use the most available ingredients
- Calculate match_score as: (matched ingredients / total required ingredients)
- List matched_ingredients from the available list
- List missing_ingredients not in the available list
- Provide realistic nutrition estimates
- Include clear, step-by-step instructions
- Return ONLY the JSON, no markdown or extra text"""

    def _create_meal_plan_prompt(
        self,
        ingredients: List[str],
        days: int,
        dietary_restrictions: List[str],
        budget: Optional[float],
        meals_per_day: int
    ) -> str:
        """Create prompt for meal plan generation"""
        budget_text = f"Budget: ${budget}" if budget else "No budget constraint"
        restrictions_text = f"Dietary restrictions: {', '.join(dietary_restrictions)}" if dietary_restrictions else "No dietary restrictions"

        day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][:days]

        return f"""Generate a {days}-day meal plan with {meals_per_day} meals per day using these ingredients. Return ONLY valid JSON.

Available Ingredients:
{', '.join(ingredients)}

{restrictions_text}
{budget_text}

Return a JSON object with this structure:
{{
  "meal_plan": [
    {{
      "id": "uuid",
      "day": "Monday",
      "meals": [
        {{
          "id": "uuid",
          "meal_type": "breakfast|lunch|dinner|snack",
          "recipe": {{ <full recipe object as defined above> }}
        }}
      ]
    }}
  ],
  "shopping_list": ["ingredient1", "ingredient2"],
  "estimated_cost": 75.50,
  "nutrition_summary": {{
    "calories": 2000,
    "protein": 80.0,
    "carbohydrates": 250.0,
    "fat": 70.0,
    "fiber": 30.0,
    "sugar": 50.0,
    "sodium": 2000.0
  }}
}}

Days to plan: {', '.join(day_names)}
Meals per day: breakfast{', lunch' if meals_per_day >= 2 else ''}{', dinner' if meals_per_day >= 3 else ''}{', snack' if meals_per_day >= 4 else ''}

IMPORTANT:
- Avoid repeating the same recipe within the plan
- Consolidate shopping_list with unique ingredients needed
- Calculate nutrition_summary as average daily totals
- If budget provided, estimate total cost and stay within budget
- Return ONLY the JSON, no markdown or extra text"""

    def _create_substitution_prompt(
        self,
        ingredients: List[str],
        recipe_type: Optional[str]
    ) -> str:
        """Create prompt for ingredient substitution suggestions"""
        recipe_context = f" for {recipe_type} recipes" if recipe_type else ""

        return f"""Suggest recipes{recipe_context} using these ingredients, and provide substitution suggestions for any missing ingredients. Return ONLY valid JSON.

Available Ingredients:
{', '.join(ingredients)}

Return a JSON object with the same recipe structure as before, but also include a "substitutions" array in the response:

{{
  "recipes": [ <recipe objects> ],
  "substitutions": [
    {{
      "original": "butter",
      "substitute": "coconut oil",
      "ratio": "1:1",
      "notes": "Works well for baking, adds slight coconut flavor"
    }}
  ]
}}

IMPORTANT:
- Suggest common substitutions for missing ingredients
- Provide ratios for substitutions (e.g., "1:1", "1 cup = 3/4 cup")
- Include helpful notes about flavor/texture differences
- Return ONLY the JSON, no markdown or extra text"""

    def _create_analysis_prompt(self, ingredients: List[str]) -> str:
        """Create prompt for ingredient analysis"""
        return f"""Analyze these ingredients and categorize them. Extract clean ingredient names if quantities are included. Return ONLY valid JSON.

Ingredients:
{', '.join(ingredients)}

Return a JSON object with this structure:
{{
  "extracted_ingredients": ["flour", "chicken breast", "olive oil"],
  "categories": [
    {{
      "id": "uuid",
      "name": "Proteins",
      "ingredients": ["chicken breast", "eggs"]
    }},
    {{
      "id": "uuid",
      "name": "Grains & Starches",
      "ingredients": ["flour", "rice"]
    }},
    {{
      "id": "uuid",
      "name": "Vegetables",
      "ingredients": ["tomatoes", "onions"]
    }},
    {{
      "id": "uuid",
      "name": "Pantry Staples",
      "ingredients": ["olive oil", "salt"]
    }}
  ],
  "suggestions": [
    "Add vegetables for a balanced meal",
    "Consider adding spices for more flavor"
  ]
}}

Common categories: Proteins, Vegetables, Fruits, Grains & Starches, Dairy, Pantry Staples, Spices & Herbs, Fats & Oils

IMPORTANT:
- Extract ingredient names, removing quantities (e.g., "2 cups flour" -> "flour")
- Group into logical categories
- Provide helpful suggestions for meal planning
- Return ONLY the JSON, no markdown or extra text"""

    def _parse_recipe_response(
        self,
        response: str,
        available_ingredients: List[str],
        include_substitutions: bool = False
    ) -> Dict[str, Any]:
        """Parse AI response for recipe generation"""
        try:
            cleaned = self._clean_json_response(response)
            parsed = json.loads(cleaned)

            recipes = parsed.get("recipes", [])
            validated_recipes = self._validate_recipes(recipes, available_ingredients)

            result = {
                "recipes": validated_recipes,
                "total_recipes": len(validated_recipes),
                "match_score": self._calculate_average_match_score(validated_recipes)
            }

            if include_substitutions:
                result["substitutions"] = parsed.get("substitutions", [])

            return result

        except json.JSONDecodeError as e:
            print(f"Failed to parse recipe response: {e}")
            return {
                "recipes": [],
                "total_recipes": 0,
                "match_score": 0.0
            }

    def _parse_meal_plan_response(self, response: str, days: int) -> Dict[str, Any]:
        """Parse AI response for meal plan generation"""
        try:
            cleaned = self._clean_json_response(response)
            parsed = json.loads(cleaned)

            meal_plan = self._validate_meal_plan(parsed.get("meal_plan", []))
            shopping_list = parsed.get("shopping_list", [])
            estimated_cost = parsed.get("estimated_cost")
            nutrition_summary = self._validate_nutrition(parsed.get("nutrition_summary", {}))

            return {
                "meal_plan": meal_plan,
                "shopping_list": shopping_list,
                "estimated_cost": estimated_cost,
                "nutrition_summary": nutrition_summary
            }

        except json.JSONDecodeError as e:
            print(f"Failed to parse meal plan response: {e}")
            return {
                "meal_plan": [],
                "shopping_list": [],
                "estimated_cost": None,
                "nutrition_summary": {}
            }

    def _parse_analysis_response(self, response: str) -> Dict[str, Any]:
        """Parse AI response for ingredient analysis"""
        try:
            cleaned = self._clean_json_response(response)
            parsed = json.loads(cleaned)

            return {
                "extracted_ingredients": parsed.get("extracted_ingredients", []),
                "categories": self._validate_categories(parsed.get("categories", [])),
                "suggestions": parsed.get("suggestions", [])
            }

        except json.JSONDecodeError as e:
            print(f"Failed to parse analysis response: {e}")
            return {
                "extracted_ingredients": [],
                "categories": [],
                "suggestions": []
            }

    def _clean_json_response(self, response: str) -> str:
        """Clean AI response to extract JSON"""
        cleaned = response.strip()

        # Remove markdown code blocks
        if cleaned.startswith("```json"):
            cleaned = cleaned[7:]
        elif cleaned.startswith("```"):
            cleaned = cleaned[3:]

        if cleaned.endswith("```"):
            cleaned = cleaned[:-3]

        return cleaned.strip()

    def _validate_recipes(self, recipes: List[Dict], available: List[str]) -> List[Dict]:
        """Validate recipe data structure"""
        validated = []

        for recipe in recipes:
            try:
                # Ensure required fields
                if not recipe.get("name"):
                    continue

                # Generate UUID if missing
                recipe_id = recipe.get("id", str(uuid.uuid4()))

                # Validate ingredients
                ingredients = []
                for ing in recipe.get("ingredients", []):
                    ing_id = ing.get("id", str(uuid.uuid4()))
                    ingredients.append({
                        "id": ing_id,
                        "name": ing.get("name", ""),
                        "amount": str(ing.get("amount", "")),
                        "unit": ing.get("unit", ""),
                        "notes": ing.get("notes"),
                        "is_optional": bool(ing.get("is_optional", False))
                    })

                # Validate instructions
                instructions = []
                for idx, inst in enumerate(recipe.get("instructions", [])):
                    inst_id = inst.get("id", str(uuid.uuid4()))
                    instructions.append({
                        "id": inst_id,
                        "step_number": inst.get("step_number", idx + 1),
                        "instruction": inst.get("instruction", ""),
                        "time_minutes": inst.get("time_minutes"),
                        "image_url": inst.get("image_url"),
                        "timer_name": inst.get("timer_name")
                    })

                validated.append({
                    "id": recipe_id,
                    "name": recipe.get("name", ""),
                    "description": recipe.get("description", ""),
                    "ingredients": ingredients,
                    "instructions": instructions,
                    "prep_time_minutes": int(recipe.get("prep_time_minutes", 0)),
                    "cook_time_minutes": int(recipe.get("cook_time_minutes", 0)),
                    "total_time_minutes": int(recipe.get("total_time_minutes", 0)),
                    "servings": int(recipe.get("servings", 4)),
                    "difficulty": recipe.get("difficulty", "intermediate"),
                    "cuisine": recipe.get("cuisine"),
                    "image_url": recipe.get("image_url"),
                    "nutrition": self._validate_nutrition(recipe.get("nutrition", {})),
                    "tags": recipe.get("tags", []),
                    "matched_ingredients": recipe.get("matched_ingredients", []),
                    "missing_ingredients": recipe.get("missing_ingredients", []),
                    "match_score": float(recipe.get("match_score", 0.5))
                })

            except Exception as e:
                print(f"Error validating recipe: {e}")
                continue

        return validated

    def _validate_meal_plan(self, meal_plan: List[Dict]) -> List[Dict]:
        """Validate meal plan structure"""
        validated = []

        for day in meal_plan:
            try:
                day_id = day.get("id", str(uuid.uuid4()))
                meals = []

                for meal in day.get("meals", []):
                    meal_id = meal.get("id", str(uuid.uuid4()))
                    recipe = meal.get("recipe", {})

                    # Validate the recipe
                    if recipe:
                        validated_recipe = self._validate_recipes([recipe], [])[0] if recipe.get("name") else {}

                        meals.append({
                            "id": meal_id,
                            "meal_type": meal.get("meal_type", ""),
                            "recipe": validated_recipe
                        })

                validated.append({
                    "id": day_id,
                    "day": day.get("day", ""),
                    "meals": meals
                })

            except Exception as e:
                print(f"Error validating meal plan day: {e}")
                continue

        return validated

    def _validate_nutrition(self, nutrition: Dict) -> Dict:
        """Validate nutrition data"""
        return {
            "calories": nutrition.get("calories"),
            "protein": nutrition.get("protein"),
            "carbohydrates": nutrition.get("carbohydrates"),
            "fat": nutrition.get("fat"),
            "fiber": nutrition.get("fiber"),
            "sugar": nutrition.get("sugar"),
            "sodium": nutrition.get("sodium")
        }

    def _validate_categories(self, categories: List[Dict]) -> List[Dict]:
        """Validate ingredient categories"""
        validated = []

        for cat in categories:
            try:
                cat_id = cat.get("id", str(uuid.uuid4()))
                validated.append({
                    "id": cat_id,
                    "name": cat.get("name", ""),
                    "ingredients": cat.get("ingredients", [])
                })
            except Exception as e:
                print(f"Error validating category: {e}")
                continue

        return validated

    def _calculate_average_match_score(self, recipes: List[Dict]) -> float:
        """Calculate average match score across recipes"""
        if not recipes:
            return 0.0

        total_score = sum(r.get("match_score", 0.0) for r in recipes)
        return round(total_score / len(recipes), 2)
