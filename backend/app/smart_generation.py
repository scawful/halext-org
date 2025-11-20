"""
AI-powered smart generation for tasks, events, and smart lists
"""
import json
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from app.ai import AiGateway
import uuid


class AiSmartGenerator:
    """AI assistant for generating tasks, events, and smart lists from natural language"""

    def __init__(self, ai_gateway: AiGateway, user_id: Optional[int] = None):
        self.ai = ai_gateway
        self.user_id = user_id

    async def generate_from_prompt(
        self,
        prompt: str,
        timezone: str,
        current_date: datetime,
        existing_task_titles: Optional[List[str]] = None,
        upcoming_event_dates: Optional[List[datetime]] = None
    ) -> Dict[str, Any]:
        """
        Generate tasks, events, and smart lists from a natural language prompt.

        Args:
            prompt: The user's natural language request
            timezone: User's timezone (e.g., "America/New_York")
            current_date: Current datetime for context
            existing_task_titles: List of existing task titles to avoid duplicates
            upcoming_event_dates: List of upcoming event dates for scheduling context

        Returns:
            Dictionary with tasks, events, smart_lists, and metadata
        """
        # Build context for the AI
        context_info = self._build_context_string(
            timezone,
            current_date,
            existing_task_titles or [],
            upcoming_event_dates or []
        )

        # Create the system prompt
        system_prompt = self._create_system_prompt()

        # Create the user prompt with context
        user_prompt = f"""{context_info}

User Request: {prompt}

Generate a comprehensive response with tasks, events, and smart lists as needed. Return ONLY valid JSON matching the schema."""

        # Call AI to generate the response
        response = await self.ai.generate_reply(
            user_prompt,
            [
                {"role": "system", "content": system_prompt}
            ],
            user_id=self.user_id
        )

        # Parse the AI response
        parsed = self._parse_ai_response(response, prompt, current_date)

        return parsed

    def _create_system_prompt(self) -> str:
        """Create the system prompt that defines the AI's role and output format"""
        return """You are a productivity planning assistant. Your role is to help users plan their work by generating structured tasks, events, and smart lists from natural language requests.

When given a user request, analyze it and generate:
1. **Tasks** - Individual action items with due dates, priorities, labels, and time estimates
2. **Events** - Calendar events with start/end times and locations
3. **Smart Lists** - Organized collections of related items or checklists

Return your response as a JSON object with this EXACT structure:

{
  "tasks": [
    {
      "title": "string",
      "description": "string",
      "due_date": "ISO8601 datetime or null",
      "priority": "high|medium|low",
      "labels": ["string"],
      "estimated_minutes": number or null,
      "subtasks": ["string"],
      "reasoning": "Brief explanation of why this task was generated"
    }
  ],
  "events": [
    {
      "title": "string",
      "description": "string",
      "start_time": "ISO8601 datetime",
      "end_time": "ISO8601 datetime",
      "location": "string or null",
      "recurrence_type": "none|daily|weekly|monthly",
      "reasoning": "Brief explanation of scheduling decisions"
    }
  ],
  "smart_lists": [
    {
      "name": "string",
      "description": "string",
      "category": "project|checklist|reference|goals",
      "items": ["string"],
      "reasoning": "Brief explanation of why this list was created"
    }
  ]
}

IMPORTANT RULES:
- Use ISO 8601 format for all dates/times (e.g., "2025-11-19T14:00:00Z")
- Set realistic due dates based on the current date provided in context
- Assign appropriate priorities (high for urgent/important, medium for normal, low for nice-to-have)
- Break complex requests into multiple smaller tasks
- Include estimated_minutes for tasks when possible (be realistic)
- Add relevant labels like "work", "personal", "urgent", "research", etc.
- Events should have clear start and end times (default to 1 hour if not specified)
- Smart lists should group related items logically
- Provide reasoning for each item to explain your decisions
- Return ONLY the JSON object, no additional text or markdown formatting"""

    def _build_context_string(
        self,
        timezone: str,
        current_date: datetime,
        existing_tasks: List[str],
        upcoming_events: List[datetime]
    ) -> str:
        """Build context string to provide to the AI"""
        context_parts = [
            f"Current Date/Time: {current_date.isoformat()}",
            f"Timezone: {timezone}",
            f"Day of Week: {current_date.strftime('%A')}",
        ]

        if existing_tasks:
            context_parts.append(f"\nExisting Tasks (avoid duplicates):")
            context_parts.extend([f"- {task}" for task in existing_tasks[:10]])

        if upcoming_events:
            context_parts.append(f"\nUpcoming Events (for scheduling context):")
            for event_date in upcoming_events[:5]:
                context_parts.append(f"- {event_date.strftime('%Y-%m-%d %H:%M')}")

        return "\n".join(context_parts)

    def _parse_ai_response(
        self,
        response: str,
        original_prompt: str,
        current_date: datetime
    ) -> Dict[str, Any]:
        """Parse the AI response and structure it into the expected format"""
        try:
            # Try to extract JSON from the response
            # Sometimes the AI adds markdown code blocks
            cleaned = response.strip()

            # Remove markdown code blocks if present
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            elif cleaned.startswith("```"):
                cleaned = cleaned[3:]

            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]

            cleaned = cleaned.strip()

            # Parse the JSON
            parsed = json.loads(cleaned)

            # Validate and clean the data
            tasks = self._validate_tasks(parsed.get("tasks", []), current_date)
            events = self._validate_events(parsed.get("events", []), current_date)
            smart_lists = self._validate_smart_lists(parsed.get("smart_lists", []))

            # Create metadata
            metadata = {
                "original_prompt": original_prompt,
                "model": self.ai.model,
                "summary": self._generate_summary(tasks, events, smart_lists)
            }

            return {
                "tasks": tasks,
                "events": events,
                "smart_lists": smart_lists,
                "metadata": metadata
            }

        except json.JSONDecodeError as e:
            # If JSON parsing fails, return empty but valid structure
            print(f"Failed to parse AI response as JSON: {e}")
            print(f"Response was: {response[:500]}")

            return {
                "tasks": [],
                "events": [],
                "smart_lists": [],
                "metadata": {
                    "original_prompt": original_prompt,
                    "model": self.ai.model,
                    "summary": "Failed to parse AI response. Please try rephrasing your request."
                }
            }

    def _validate_tasks(self, tasks: List[Dict], current_date: datetime) -> List[Dict]:
        """Validate and clean task data"""
        validated = []

        for task in tasks:
            try:
                # Ensure required fields
                if not task.get("title"):
                    continue

                # Parse due date if present
                due_date = None
                if task.get("due_date"):
                    if isinstance(task["due_date"], str):
                        due_date = task["due_date"]
                    elif isinstance(task["due_date"], datetime):
                        due_date = task["due_date"].isoformat()

                validated.append({
                    "title": str(task.get("title", "")).strip(),
                    "description": str(task.get("description", "")).strip(),
                    "due_date": due_date,
                    "priority": self._normalize_priority(task.get("priority", "medium")),
                    "labels": task.get("labels", [])[:10],  # Limit to 10 labels
                    "estimated_minutes": task.get("estimated_minutes"),
                    "subtasks": task.get("subtasks", [])[:20],  # Limit to 20 subtasks
                    "reasoning": str(task.get("reasoning", "")).strip()
                })
            except Exception as e:
                print(f"Error validating task: {e}")
                continue

        return validated

    def _validate_events(self, events: List[Dict], current_date: datetime) -> List[Dict]:
        """Validate and clean event data"""
        validated = []

        for event in events:
            try:
                # Ensure required fields
                if not event.get("title") or not event.get("start_time") or not event.get("end_time"):
                    continue

                # Ensure start_time and end_time are ISO strings
                start_time = event["start_time"]
                end_time = event["end_time"]

                if isinstance(start_time, datetime):
                    start_time = start_time.isoformat()
                if isinstance(end_time, datetime):
                    end_time = end_time.isoformat()

                validated.append({
                    "title": str(event.get("title", "")).strip(),
                    "description": str(event.get("description", "")).strip(),
                    "start_time": start_time,
                    "end_time": end_time,
                    "location": event.get("location"),
                    "recurrence_type": self._normalize_recurrence(event.get("recurrence_type", "none")),
                    "reasoning": str(event.get("reasoning", "")).strip()
                })
            except Exception as e:
                print(f"Error validating event: {e}")
                continue

        return validated

    def _validate_smart_lists(self, smart_lists: List[Dict]) -> List[Dict]:
        """Validate and clean smart list data"""
        validated = []

        for smart_list in smart_lists:
            try:
                # Ensure required fields
                if not smart_list.get("name"):
                    continue

                validated.append({
                    "name": str(smart_list.get("name", "")).strip(),
                    "description": str(smart_list.get("description", "")).strip(),
                    "category": self._normalize_category(smart_list.get("category", "checklist")),
                    "items": smart_list.get("items", [])[:50],  # Limit to 50 items
                    "reasoning": str(smart_list.get("reasoning", "")).strip()
                })
            except Exception as e:
                print(f"Error validating smart list: {e}")
                continue

        return validated

    def _normalize_priority(self, priority: str) -> str:
        """Normalize priority values"""
        priority_lower = str(priority).lower()
        if priority_lower in ["high", "urgent"]:
            return "high"
        elif priority_lower in ["low"]:
            return "low"
        else:
            return "medium"

    def _normalize_recurrence(self, recurrence: str) -> str:
        """Normalize recurrence type values"""
        recurrence_lower = str(recurrence).lower()
        if recurrence_lower in ["daily", "weekly", "monthly", "yearly"]:
            return recurrence_lower
        else:
            return "none"

    def _normalize_category(self, category: str) -> str:
        """Normalize smart list category values"""
        category_lower = str(category).lower()
        valid_categories = ["project", "checklist", "reference", "goals"]
        if category_lower in valid_categories:
            return category_lower
        else:
            return "checklist"

    def _generate_summary(self, tasks: List[Dict], events: List[Dict], smart_lists: List[Dict]) -> str:
        """Generate a summary of what was created"""
        parts = []

        if tasks:
            parts.append(f"{len(tasks)} task{'s' if len(tasks) != 1 else ''}")
        if events:
            parts.append(f"{len(events)} event{'s' if len(events) != 1 else ''}")
        if smart_lists:
            parts.append(f"{len(smart_lists)} smart list{'s' if len(smart_lists) != 1 else ''}")

        if not parts:
            return "No items generated"

        return f"Generated {', '.join(parts)}"
