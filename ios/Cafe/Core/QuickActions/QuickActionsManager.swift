//
//  QuickActionsManager.swift
//  Cafe
//
//  Quick Actions (3D Touch / Haptic Touch) on home screen icon
//

import UIKit

class QuickActionsManager {
    static let shared = QuickActionsManager()

    // Quick action types
    enum ActionType: String {
        case newTask = "org.halext.cafe.newTask"
        case newEvent = "org.halext.cafe.newEvent"
        case todaysTasks = "org.halext.cafe.todaysTasks"
        case chat = "org.halext.cafe.chat"
        case messageChris = "org.halext.cafe.messageChris"
        case sharedCalendar = "org.halext.cafe.sharedCalendar"
        case sharedEvent = "org.halext.cafe.sharedEvent"
    }

    private init() {}

    // MARK: - Setup Quick Actions

    func setupQuickActions() {
        let newTaskAction = UIApplicationShortcutItem(
            type: ActionType.newTask.rawValue,
            localizedTitle: "New Task",
            localizedSubtitle: "Create a task",
            icon: UIApplicationShortcutIcon(systemImageName: "plus.circle"),
            userInfo: nil
        )

        let newEventAction = UIApplicationShortcutItem(
            type: ActionType.newEvent.rawValue,
            localizedTitle: "New Event",
            localizedSubtitle: "Schedule an event",
            icon: UIApplicationShortcutIcon(systemImageName: "calendar.badge.plus"),
            userInfo: nil
        )

        let todaysTasksAction = UIApplicationShortcutItem(
            type: ActionType.todaysTasks.rawValue,
            localizedTitle: "Today's Tasks",
            localizedSubtitle: "View tasks for today",
            icon: UIApplicationShortcutIcon(systemImageName: "checkmark.circle"),
            userInfo: nil
        )

        let chatAction = UIApplicationShortcutItem(
            type: ActionType.chat.rawValue,
            localizedTitle: "AI Assistant",
            localizedSubtitle: "Chat with AI",
            icon: UIApplicationShortcutIcon(systemImageName: "sparkles"),
            userInfo: nil
        )

        let messageChrisAction = UIApplicationShortcutItem(
            type: ActionType.messageChris.rawValue,
            localizedTitle: "Message Chris",
            localizedSubtitle: "Send a message",
            icon: UIApplicationShortcutIcon(systemImageName: "sparkles"),
            userInfo: nil
        )

        let sharedCalendarAction = UIApplicationShortcutItem(
            type: ActionType.sharedCalendar.rawValue,
            localizedTitle: "Shared Calendar",
            localizedSubtitle: "View shared events",
            icon: UIApplicationShortcutIcon(systemImageName: "person.2.fill"),
            userInfo: nil
        )

        UIApplication.shared.shortcutItems = [
            newTaskAction,
            newEventAction,
            messageChrisAction,
            sharedCalendarAction,
            todaysTasksAction,
            chatAction
        ]

        print("✅ Quick Actions configured")
    }

    // MARK: - Handle Quick Action

    func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) -> QuickActionResult? {
        guard let actionType = ActionType(rawValue: shortcutItem.type) else {
            return nil
        }

        print("🔷 Handling quick action: \(actionType.rawValue)")

        switch actionType {
        case .newTask:
            return .newTask

        case .newEvent:
            return .newEvent

        case .todaysTasks:
            return .todaysTasks

        case .chat:
            return .chat
            
        case .messageChris:
            return .messageChris
            
        case .sharedCalendar:
            return .sharedCalendar
            
        case .sharedEvent:
            return .sharedEvent
        }
    }

    // MARK: - Dynamic Quick Actions

    func updateDynamicQuickActions(taskCount: Int) {
        // Keep static actions and add dynamic ones
        var actions = UIApplication.shared.shortcutItems ?? []

        // Remove old dynamic actions
        actions.removeAll { $0.type.contains("dynamic") }

        // Add dynamic action based on context
        if taskCount > 0 {
            let viewTasksAction = UIApplicationShortcutItem(
                type: "org.halext.cafe.dynamic.viewTasks",
                localizedTitle: "View \(taskCount) Tasks",
                localizedSubtitle: "See all your tasks",
                icon: UIApplicationShortcutIcon(systemImageName: "list.bullet"),
                userInfo: nil
            )
            actions.append(viewTasksAction)
        }

        // Update actions (max 4 items)
        UIApplication.shared.shortcutItems = Array(actions.prefix(4))
    }
}

// MARK: - Quick Action Result

enum QuickActionResult {
    case newTask
    case newEvent
    case todaysTasks
    case chat
    case messageChris
    case sharedCalendar
    case sharedEvent
}
