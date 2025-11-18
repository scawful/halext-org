"""
Seed data for new users to showcase the UI and features
"""
from datetime import datetime, timedelta
from typing import List, Dict, Any


def get_demo_tasks() -> List[Dict[str, Any]]:
    """Get demo tasks to showcase the task management system"""
    now = datetime.utcnow()

    return [
        {
            "title": "Welcome to Halext Org! 👋",
            "description": "This is a sample task to show you around. Click the checkmark to complete it!",
            "completed": False,
            "labels": ["getting-started"],
            "due_date": None,
        },
        {
            "title": "Try the AI Task Assistant",
            "description": "Create a new task and click 'Get AI Suggestions' to see AI-powered task breakdown, time estimates, and priority suggestions.",
            "completed": False,
            "labels": ["ai", "tutorial"],
            "due_date": now + timedelta(days=2),
        },
        {
            "title": "Customize your dashboard",
            "description": "Drag and drop widgets, add new columns, and create multiple pages to organize your workspace.",
            "completed": False,
            "labels": ["customization", "getting-started"],
            "due_date": None,
        },
        {
            "title": "Set up calendar events",
            "description": "Add events to see them in your calendar view and get AI-powered conflict detection.",
            "completed": False,
            "labels": ["calendar"],
            "due_date": now + timedelta(days=3),
        },
        {
            "title": "Chat with AI Assistant",
            "description": "Click 'AI Chat' in the menu to have conversations with your AI assistant about tasks, planning, or anything else!",
            "completed": False,
            "labels": ["ai", "tutorial"],
            "due_date": None,
        },
        {
            "title": "Example: Plan weekend project",
            "description": "Build a new bookshelf for the home office. Need to measure space, buy materials, and assemble.",
            "completed": False,
            "labels": ["personal", "home"],
            "due_date": now + timedelta(days=5),
        },
        {
            "title": "Example: Review quarterly goals",
            "description": "Check progress on Q1 objectives and adjust Q2 planning accordingly.",
            "completed": False,
            "labels": ["work", "planning"],
            "due_date": now + timedelta(days=7),
        },
        {
            "title": "Completed example: Set up account",
            "description": "You've already done this! This shows what completed tasks look like.",
            "completed": True,
            "labels": ["getting-started"],
            "due_date": None,
        },
    ]


def get_demo_events() -> List[Dict[str, Any]]:
    """Get demo events to showcase the calendar system"""
    now = datetime.utcnow()
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    return [
        {
            "title": "Welcome Meeting",
            "description": "Quick intro to Halext Org features and capabilities",
            "start_time": today + timedelta(hours=14),
            "end_time": today + timedelta(hours=15),
            "location": "Virtual",
            "recurrence_type": "none",
        },
        {
            "title": "Team Standup",
            "description": "Daily sync with the team",
            "start_time": today + timedelta(days=1, hours=9),
            "end_time": today + timedelta(days=1, hours=9, minutes=30),
            "location": "Conference Room A",
            "recurrence_type": "daily",
            "recurrence_interval": 1,
            "recurrence_end_date": today + timedelta(days=30),
        },
        {
            "title": "Lunch Break",
            "description": "Time to recharge!",
            "start_time": today + timedelta(hours=12),
            "end_time": today + timedelta(hours=13),
            "location": None,
            "recurrence_type": "daily",
            "recurrence_interval": 1,
            "recurrence_end_date": today + timedelta(days=30),
        },
        {
            "title": "Project Review",
            "description": "Review current project status and next steps",
            "start_time": today + timedelta(days=2, hours=15),
            "end_time": today + timedelta(days=2, hours=16, minutes=30),
            "location": "Zoom",
            "recurrence_type": "none",
        },
        {
            "title": "Coffee Chat",
            "description": "Casual 1-on-1 with a colleague",
            "start_time": today + timedelta(days=3, hours=10),
            "end_time": today + timedelta(days=3, hours=10, minutes=30),
            "location": "Cafe",
            "recurrence_type": "none",
        },
        {
            "title": "Weekend Hike",
            "description": "Nature walk at the local trail",
            "start_time": today + timedelta(days=6, hours=8),
            "end_time": today + timedelta(days=6, hours=12),
            "location": "Mountain Trail Park",
            "recurrence_type": "none",
        },
    ]


def get_demo_labels() -> List[Dict[str, str]]:
    """Get demo labels to showcase the labeling system"""
    return [
        {"name": "getting-started", "color": "#9333ea"},  # purple
        {"name": "ai", "color": "#3b82f6"},  # blue
        {"name": "tutorial", "color": "#06b6d4"},  # cyan
        {"name": "work", "color": "#f59e0b"},  # amber
        {"name": "personal", "color": "#10b981"},  # green
        {"name": "urgent", "color": "#ef4444"},  # red
        {"name": "planning", "color": "#8b5cf6"},  # violet
        {"name": "home", "color": "#ec4899"},  # pink
        {"name": "health", "color": "#14b8a6"},  # teal
        {"name": "learning", "color": "#6366f1"},  # indigo
        {"name": "calendar", "color": "#f97316"},  # orange
        {"name": "customization", "color": "#a855f7"},  # purple-500
    ]


def get_demo_page_layout() -> List[Dict[str, Any]]:
    """Get a demo page layout showcasing various widgets"""
    return [
        {
            "id": "demo-col-1",
            "title": "🎯 Focus",
            "width": 1,
            "widgets": [
                {
                    "id": "demo-tasks-widget",
                    "type": "tasks",
                    "title": "My Tasks",
                    "config": {"filter": "active"}
                },
                {
                    "id": "demo-events-widget",
                    "type": "events",
                    "title": "Upcoming Events",
                    "config": {"range": "week"}
                },
            ]
        },
        {
            "id": "demo-col-2",
            "title": "📝 Notes & Ideas",
            "width": 1,
            "widgets": [
                {
                    "id": "demo-notes-widget",
                    "type": "notes",
                    "title": "Quick Notes",
                    "config": {
                        "content": "# Welcome to Halext Org!\n\n## Getting Started\n- Drag widgets to reorder them\n- Click + to add new widgets\n- Use AI Chat for assistance\n- Try the AI Task Assistant\n\n## Tips\n💡 Use labels to organize tasks\n📅 Set up recurring events\n🤖 Ask AI for help with planning\n"
                    }
                },
                {
                    "id": "demo-gift-widget",
                    "type": "gift-list",
                    "title": "Gift Ideas",
                    "config": {
                        "items": [
                            {"id": "gift-1", "name": "Smart Watch", "recipient": "Partner", "occasion": "Birthday", "purchased": False},
                            {"id": "gift-2", "name": "Coffee Maker", "recipient": "Parents", "occasion": "Anniversary", "purchased": False},
                            {"id": "gift-3", "name": "Book: Deep Work", "recipient": "Friend", "occasion": "Graduation", "purchased": True},
                        ]
                    }
                },
            ]
        },
        {
            "id": "demo-col-3",
            "title": "🤖 AI Tools",
            "width": 1,
            "widgets": [
                {
                    "id": "demo-openwebui-widget",
                    "type": "openwebui",
                    "title": "OpenWebUI",
                    "config": {}
                },
            ]
        }
    ]


def create_demo_content(user_id: int, db):
    """
    Create demo content for a new user

    Args:
        user_id: The user's database ID
        db: Database session
    """
    from app import crud, schemas, models

    # Create demo labels
    print(f"Creating demo labels for user {user_id}...")
    created_labels = {}
    for label_data in get_demo_labels():
        label = crud.create_label(
            db,
            user_id,
            schemas.LabelCreate(**label_data),
        )
        created_labels[label_data["name"]] = label

    # Create demo tasks
    print(f"Creating demo tasks for user {user_id}...")
    for task_data in get_demo_tasks():
        crud.create_user_task(
            db,
            schemas.TaskCreate(**task_data),
            user_id,
        )

    # Create demo events
    print(f"Creating demo events for user {user_id}...")
    for event_data in get_demo_events():
        crud.create_user_event(
            db,
            schemas.EventCreate(**event_data),
            user_id,
        )

    # Create demo page with layout
    print(f"Creating demo page for user {user_id}...")
    demo_page = crud.create_page(
        db,
        user_id,
        schemas.PageCreate(
            title="Welcome Dashboard",
            description="Your personalized dashboard with example widgets",
            visibility="private",
            layout=get_demo_page_layout()
        ),
    )

    print(f"✅ Demo content created successfully for user {user_id}")
    return {
        "labels_created": len(created_labels),
        "tasks_created": len(get_demo_tasks()),
        "events_created": len(get_demo_events()),
        "page_id": demo_page.id
    }
