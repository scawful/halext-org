"""
AI-powered features for tasks, events, and notes
"""
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from app.ai import AiGateway


class AiTaskHelper:
    """AI assistant for task management"""

    def __init__(self, ai_gateway: AiGateway, user_id: Optional[int] = None, db=None):
        self.ai = ai_gateway
        self.user_id = user_id
        self.db = db

    async def suggest_subtasks(self, task_title: str, task_description: Optional[str] = None, model_identifier: Optional[str] = None) -> List[str]:
        """Break down a task into suggested subtasks"""
        prompt = f"""Break down this task into 3-5 concrete, actionable subtasks:

Task: {task_title}
{f'Description: {task_description}' if task_description else ''}

Return only the subtask titles, one per line, without numbers or bullets."""

        response, _ = await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)
        # Parse response into list of subtasks
        subtasks = [line.strip() for line in response.split('\n') if line.strip() and not line.strip().startswith('#')]
        return subtasks[:5]  # Limit to 5

    async def suggest_subtasks_stream(self, task_title: str, task_description: Optional[str] = None, model_identifier: Optional[str] = None):
        """Stream suggested subtasks for a task"""
        prompt = f"""Break down this task into 3-5 concrete, actionable subtasks:

Task: {task_title}
{f'Description: {task_description}' if task_description else ''}

Return only the subtask titles, one per line, without numbers or bullets."""

        stream, _ = await self.ai.generate_stream(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)
        return stream

    async def estimate_time(self, task_title: str, task_description: Optional[str] = None, model_identifier: Optional[str] = None) -> Dict[str, Any]:
        """Estimate time required for a task"""
        prompt = f"""Estimate the time required to complete this task. Provide:
1. Estimated hours (as a number)
2. Confidence level (low/medium/high)
3. Key factors affecting the estimate

Task: {task_title}
{f'Description: {task_description}' if task_description else ''}

Return in this format:
Hours: X
Confidence: [low/medium/high]
Factors: [brief explanation]"""

        response = await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)

        # Parse the response
        hours = 2.0  # default
        confidence = "medium"
        factors = response

        try:
            for line in response.split('\n'):
                if line.startswith('Hours:'):
                    hours = float(line.split(':')[1].strip().split()[0])
                elif line.startswith('Confidence:'):
                    confidence = line.split(':')[1].strip().lower()
                elif line.startswith('Factors:'):
                    factors = line.split(':', 1)[1].strip()
        except (ValueError, IndexError):
            pass

        return {
            "estimated_hours": hours,
            "confidence": confidence,
            "factors": factors
        }

    async def suggest_priority(self, task_title: str, task_description: Optional[str] = None, due_date: Optional[datetime] = None, model_identifier: Optional[str] = None) -> Dict[str, Any]:
        """Suggest task priority based on content and due date"""
        due_info = ""
        if due_date:
            days_until = (due_date - datetime.utcnow()).days
            due_info = f"\nDue in {days_until} days ({due_date.strftime('%Y-%m-%d')})"

        prompt = f"""Analyze this task and suggest a priority level (high/medium/low) with reasoning:

Task: {task_title}
{f'Description: {task_description}' if task_description else ''}{due_info}

Return in this format:
Priority: [high/medium/low]
Reasoning: [brief explanation]"""

        response = await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)

        priority = "medium"
        reasoning = response

        try:
            for line in response.split('\n'):
                if line.startswith('Priority:'):
                    priority = line.split(':')[1].strip().lower()
                elif line.startswith('Reasoning:'):
                    reasoning = line.split(':', 1)[1].strip()
        except (ValueError, IndexError):
            pass

        return {
            "priority": priority,
            "reasoning": reasoning
        }

    async def suggest_labels(self, task_title: str, task_description: Optional[str] = None, model_identifier: Optional[str] = None) -> List[str]:
        """Suggest appropriate labels for a task"""
        prompt = f"""Suggest 2-4 relevant labels/tags for this task. Choose from common categories like:
work, personal, urgent, research, development, design, meeting, email, documentation, etc.

Task: {task_title}
{f'Description: {task_description}' if task_description else ''}

Return only the labels, comma-separated."""

        response = await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)
        # Parse labels
        labels = [label.strip().lower() for label in response.replace('\n', ',').split(',') if label.strip()]
        return labels[:4]  # Limit to 4


class AiEventHelper:
    """AI assistant for event management"""

    def __init__(self, ai_gateway: AiGateway, user_id: Optional[int] = None, db=None):
        self.ai = ai_gateway
        self.user_id = user_id
        self.db = db

    async def summarize_event(self, event_title: str, event_description: Optional[str] = None, duration_minutes: Optional[int] = None, model_identifier: Optional[str] = None) -> str:
        """Generate a concise summary of an event"""
        duration_info = f"\nDuration: {duration_minutes} minutes" if duration_minutes else ""

        prompt = f"""Provide a concise 1-2 sentence summary of this event:

Event: {event_title}
{f'Description: {event_description}' if event_description else ''}{duration_info}

Return only the summary."""

        return await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)

    async def suggest_preparation(self, event_title: str, event_description: Optional[str] = None, event_type: Optional[str] = None, model_identifier: Optional[str] = None) -> List[str]:
        """Suggest preparation steps for an event"""
        type_info = f"\nType: {event_type}" if event_type else ""

        prompt = f"""Suggest 3-5 preparation steps for this event:

Event: {event_title}
{f'Description: {event_description}' if event_description else ''}{type_info}

Return only the preparation steps, one per line."""

        response = await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)
        steps = [line.strip() for line in response.split('\n') if line.strip() and not line.strip().startswith('#')]
        return steps[:5]

    async def detect_conflicts(self, event_title: str, start_time: datetime, end_time: datetime, existing_events: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Detect potential scheduling conflicts"""
        conflicts = []

        for event in existing_events:
            event_start = event.get('start_time')
            event_end = event.get('end_time')

            if not event_start or not event_end:
                continue

            # Check for time overlap
            if (start_time < event_end and end_time > event_start):
                conflicts.append({
                    "event_id": event.get('id'),
                    "event_title": event.get('title'),
                    "start_time": event_start.isoformat() if isinstance(event_start, datetime) else event_start,
                    "end_time": event_end.isoformat() if isinstance(event_end, datetime) else event_end,
                })

        return {
            "has_conflicts": len(conflicts) > 0,
            "conflict_count": len(conflicts),
            "conflicts": conflicts
        }

    async def suggest_optimal_time(self, event_title: str, duration_minutes: int, preferred_date: datetime, existing_events: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Suggest optimal time slots for an event"""
        # Find free slots on the preferred date
        day_start = preferred_date.replace(hour=9, minute=0, second=0, microsecond=0)
        day_end = preferred_date.replace(hour=17, minute=0, second=0, microsecond=0)

        # Sort existing events by start time
        events_on_day = [
            e for e in existing_events
            if e.get('start_time') and day_start <= e['start_time'] < day_end
        ]
        events_on_day.sort(key=lambda e: e['start_time'])

        # Find gaps
        suggestions = []
        current_time = day_start

        for event in events_on_day:
            gap_minutes = (event['start_time'] - current_time).total_seconds() / 60
            if gap_minutes >= duration_minutes:
                suggestions.append({
                    "start_time": current_time.isoformat(),
                    "end_time": (current_time + timedelta(minutes=duration_minutes)).isoformat(),
                })
            current_time = max(current_time, event['end_time'])

        # Check if there's time after last event
        gap_minutes = (day_end - current_time).total_seconds() / 60
        if gap_minutes >= duration_minutes:
            suggestions.append({
                "start_time": current_time.isoformat(),
                "end_time": (current_time + timedelta(minutes=duration_minutes)).isoformat(),
            })

        return suggestions[:3]  # Return top 3 suggestions


class AiNoteHelper:
    """AI assistant for note-taking and management"""

    def __init__(self, ai_gateway: AiGateway, user_id: Optional[int] = None, db=None):
        self.ai = ai_gateway
        self.user_id = user_id
        self.db = db

    async def summarize_note(self, note_content: str, max_length: int = 200, model_identifier: Optional[str] = None) -> str:
        """Generate a summary of note content"""
        prompt = f"""Summarize this note in {max_length} characters or less:

{note_content}

Return only the summary."""

        return await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)

    async def extract_tasks(self, note_content: str, model_identifier: Optional[str] = None) -> List[str]:
        """Extract actionable tasks from note content"""
        prompt = f"""Extract actionable tasks from this note. Look for action items, TODOs, or things that need to be done:

{note_content}

Return only the task titles, one per line."""

        response, _ = await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)
        tasks = [line.strip() for line in response.split('\n') if line.strip() and not line.strip().startswith('#')]
        return tasks

    async def suggest_formatting(self, note_content: str, model_identifier: Optional[str] = None) -> str:
        """Suggest improved formatting for note content"""
        prompt = f"""Improve the formatting and structure of this note using markdown. Add headers, bullets, and emphasis where appropriate:

{note_content}

Return the reformatted note."""

        return await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)

    async def generate_tags(self, note_content: str, model_identifier: Optional[str] = None) -> List[str]:
        """Generate relevant tags for a note"""
        prompt = f"""Generate 3-5 relevant tags for this note based on its content:

{note_content}

Return only the tags, comma-separated."""

        response, _ = await self.ai.generate_reply(prompt, user_id=self.user_id, model_identifier=model_identifier, db=self.db)
        tags = [tag.strip().lower() for tag in response.replace('\n', ',').split(',') if tag.strip()]
        return tags[:5]


class AiHiveMindHelper:
    """AI assistant for Hive Mind conversations"""

    def __init__(self, ai_gateway: AiGateway, user_id: Optional[int] = None, db=None):
        self.ai = ai_gateway
        self.user_id = user_id
        self.db = db

    async def summarize_conversation(self, conversation_history: List[Dict[str, str]], goal: str) -> str:
        """Summarize the conversation so far"""
        history = "\n".join([f"{msg['role']}: {msg['content']}" for msg in conversation_history])
        prompt = f"""Given the following conversation history and the overall goal, provide a concise summary of the key points and progress so far.

Goal: {goal}

Conversation:
{history}

Summary:"""
        summary, _ = await self.ai.generate_reply(prompt, user_id=self.user_id, db=self.db)
        return summary

    async def identify_action_items(self, conversation_history: List[Dict[str, str]], goal: str) -> List[str]:
        """Identify key decisions and action items"""
        history = "\n".join([f"{msg['role']}: {msg['content']}" for msg in conversation_history])
        prompt = f"""Given the following conversation history and the overall goal, identify any clear action items or decisions that have been made.

Goal: {goal}

Conversation:
{history}

Return only the action items, one per line."""
        response, _ = await self.ai.generate_reply(prompt, user_id=self.user_id, db=self.db)
        action_items = [line.strip() for line in response.split('\n') if line.strip()]
        return action_items

    async def suggest_next_steps(self, conversation_history: List[Dict[str, str]], goal: str) -> List[str]:
        """Suggest next steps to move the conversation towards its goal"""
        history = "\n".join([f"{msg['role']}: {msg['content']}" for msg in conversation_history])
        prompt = f"""Given the following conversation history and the overall goal, suggest 2-3 concrete next steps to help achieve the goal.

Goal: {goal}

Conversation:
{history}

Return only the suggested next steps, one per line."""
        response, _ = await self.ai.generate_reply(prompt, user_id=self.user_id, db=self.db)
        next_steps = [line.strip() for line in response.split('\n') if line.strip()]
        return next_steps
