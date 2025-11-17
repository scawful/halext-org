DEFAULT_LAYOUT_PRESETS = [
    {
        "name": "Focus Stack",
        "description": "Tasks, upcoming events, and a notes widget stacked for quick review.",
        "layout": [
            {
                "id": "col-focus",
                "title": "Today",
                "width": 1,
                "widgets": [
                    {"id": "w-tasks", "type": "tasks", "title": "Priority Tasks", "config": {"filter": "today"}},
                    {"id": "w-events", "type": "events", "title": "Next Events", "config": {"range": "week"}},
                    {"id": "w-notes", "type": "notes", "title": "Notes", "config": {"content": ""}},
                ],
            }
        ],
    },
    {
        "name": "Planning Grid",
        "description": "Two-column grid inspired by Apple widgets with tasks and gift ideas.",
        "layout": [
            {
                "id": "col-left",
                "title": "Work",
                "width": 1,
                "widgets": [
                    {"id": "w-left-tasks", "type": "tasks", "title": "Tasks", "config": {"filter": "all"}},
                    {"id": "w-chat", "type": "notes", "title": "Brain Dump", "config": {"content": ""}},
                ],
            },
            {
                "id": "col-right",
                "title": "Life",
                "width": 1,
                "widgets": [
                    {"id": "w-right-events", "type": "events", "title": "Upcoming", "config": {"range": "month"}},
                    {"id": "w-gifts", "type": "gift-list", "title": "Gift Ideas", "config": {"items": []}},
                ],
            },
        ],
    },
]
