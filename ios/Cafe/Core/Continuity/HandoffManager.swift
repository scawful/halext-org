//
//  HandoffManager.swift
//  Cafe
//
//  Handoff support for continuity between Apple devices
//

import Foundation
import UIKit

class HandoffManager {
    static let shared = HandoffManager()

    // Activity types
    static let viewTaskActivityType = "org.halext.cafe.view-task"
    static let viewEventActivityType = "org.halext.cafe.view-event"
    static let chatActivityType = "org.halext.cafe.chat"

    private var currentActivity: NSUserActivity?

    private init() {}

    // MARK: - Create User Activities

    func createTaskActivity(taskId: Int, taskTitle: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: HandoffManager.viewTaskActivityType)

        activity.title = "View Task: \(taskTitle)"
        activity.userInfo = [
            "taskId": taskId,
            "taskTitle": taskTitle
        ]

        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        // Web page for continuation on other platforms
        activity.webpageURL = URL(string: "https://org.halext.org/tasks/\(taskId)")

        // Keywords for Spotlight
        activity.keywords = Set(["task", taskTitle.lowercased()])

        // Content attributes for Spotlight
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = taskTitle
        attributes.contentDescription = "View task: \(taskTitle)"
        activity.contentAttributeSet = attributes

        currentActivity = activity
        activity.becomeCurrent()

        print("🔗 Created Handoff activity for task: \(taskTitle)")
        return activity
    }

    func createEventActivity(eventId: Int, eventTitle: String, startTime: Date) -> NSUserActivity {
        let activity = NSUserActivity(activityType: HandoffManager.viewEventActivityType)

        activity.title = "View Event: \(eventTitle)"
        activity.userInfo = [
            "eventId": eventId,
            "eventTitle": eventTitle,
            "startTime": startTime.timeIntervalSince1970
        ]

        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true

        activity.webpageURL = URL(string: "https://org.halext.org/events/\(eventId)")

        activity.keywords = Set(["event", eventTitle.lowercased()])

        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = eventTitle
        attributes.contentDescription = "Event starting at \(startTime.formatted())"
        attributes.startDate = startTime
        activity.contentAttributeSet = attributes

        currentActivity = activity
        activity.becomeCurrent()

        print("🔗 Created Handoff activity for event: \(eventTitle)")
        return activity
    }

    func createChatActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: HandoffManager.chatActivityType)

        activity.title = "AI Chat"
        activity.userInfo = ["view": "chat"]

        activity.isEligibleForHandoff = true
        activity.isEligibleForPrediction = true

        activity.webpageURL = URL(string: "https://org.halext.org/chat")

        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = "AI Assistant"
        attributes.contentDescription = "Chat with AI assistant"
        activity.contentAttributeSet = attributes

        currentActivity = activity
        activity.becomeCurrent()

        print("🔗 Created Handoff activity for chat")
        return activity
    }

    // MARK: - Invalidate Current Activity

    func invalidateCurrentActivity() {
        currentActivity?.invalidate()
        currentActivity = nil
        print("🔗 Invalidated current Handoff activity")
    }

    // MARK: - Handle Incoming Handoff

    func handleUserActivity(_ userActivity: NSUserActivity) -> HandoffAction? {
        print("🔗 Handling user activity: \(userActivity.activityType)")

        switch userActivity.activityType {
        case HandoffManager.viewTaskActivityType:
            guard let taskId = userActivity.userInfo?["taskId"] as? Int else { return nil }
            return .viewTask(taskId: taskId)

        case HandoffManager.viewEventActivityType:
            guard let eventId = userActivity.userInfo?["eventId"] as? Int else { return nil }
            return .viewEvent(eventId: eventId)

        case HandoffManager.chatActivityType:
            return .openChat

        case NSUserActivityTypeBrowsingWeb:
            // Handle universal links
            guard let url = userActivity.webpageURL else { return nil }
            return handleUniversalLink(url)

        default:
            return nil
        }
    }

    // MARK: - Universal Links

    private func handleUniversalLink(_ url: URL) -> HandoffAction? {
        let path = url.path

        // Match URL patterns
        if path.starts(with: "/tasks/"), let taskId = Int(path.replacingOccurrences(of: "/tasks/", with: "")) {
            return .viewTask(taskId: taskId)
        }

        if path.starts(with: "/events/"), let eventId = Int(path.replacingOccurrences(of: "/events/", with: "")) {
            return .viewEvent(eventId: eventId)
        }

        if path == "/chat" {
            return .openChat
        }

        return nil
    }
}

// MARK: - Handoff Actions

enum HandoffAction {
    case viewTask(taskId: Int)
    case viewEvent(eventId: Int)
    case openChat
}

// MARK: - Core Spotlight Support

import CoreSpotlight

extension HandoffManager {
    func indexForSpotlight(tasks: [Task]) {
        let activities = tasks.prefix(20).map { task in
            createTaskActivity(taskId: task.id, taskTitle: task.title)
        }

        print("🔍 Indexed \(activities.count) tasks for Spotlight")
    }

    func indexForSpotlight(events: [Event]) {
        let activities = events.prefix(20).map { event in
            createEventActivity(eventId: event.id, eventTitle: event.title, startTime: event.startTime)
        }

        print("🔍 Indexed \(activities.count) events for Spotlight")
    }
}
