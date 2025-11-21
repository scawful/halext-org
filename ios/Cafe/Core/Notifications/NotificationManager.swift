//
//  NotificationManager.swift
//  Cafe
//
//  Push and local notifications management
//

import Foundation
import UserNotifications
import UIKit

@MainActor
@Observable
class NotificationManager: NSObject {
    static let shared = NotificationManager()

    var isAuthorized = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        notificationCenter.delegate = self
        _Concurrency.Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            await checkAuthorizationStatus()

            if granted {
                // Register for remote notifications
                await UIApplication.shared.registerForRemoteNotifications()
            }

            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Task Reminders

    func scheduleTaskReminder(taskId: Int, title: String, dueDate: Date) async {
        guard isAuthorized else {
            print("⚠️ Notifications not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Task Due Soon"
        content.body = title
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TASK_REMINDER"
        content.userInfo = ["taskId": taskId, "type": "task_due"]

        // Schedule 1 hour before due date
        let reminderDate = dueDate.addingTimeInterval(-3600)

        if reminderDate > Date() {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "task_\(taskId)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                print("✅ Scheduled task reminder for: \(reminderDate)")
            } catch {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelTaskReminder(taskId: Int) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["task_\(taskId)"])
        print("🗑️ Cancelled task reminder for task \(taskId)")
    }

    // MARK: - Event Reminders

    func scheduleEventReminder(eventId: Int, title: String, startTime: Date, minutesBefore: Int = 15) async {
        guard isAuthorized else {
            print("⚠️ Notifications not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = title
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "EVENT_REMINDER"
        content.userInfo = ["eventId": eventId, "type": "event_reminder"]

        let reminderDate = startTime.addingTimeInterval(-Double(minutesBefore * 60))

        if reminderDate > Date() {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let request = UNNotificationRequest(
                identifier: "event_\(eventId)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                print("✅ Scheduled event reminder for: \(reminderDate)")
            } catch {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelEventReminder(eventId: Int) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["event_\(eventId)"])
        print("🗑️ Cancelled event reminder for event \(eventId)")
    }

    // MARK: - Daily Summary

    func scheduleDailySummary(hour: Int = 8, minute: Int = 0) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Check your tasks and events for today"
        content.sound = .default
        content.categoryIdentifier = "DAILY_SUMMARY"
        content.userInfo = ["type": "daily_summary"]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("✅ Scheduled daily summary at \(hour):\(minute)")
        } catch {
            print("❌ Failed to schedule daily summary: \(error)")
        }
    }

    func cancelDailySummary() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_summary"])
    }

    // MARK: - Local Notifications

    func showLocalNotification(title: String, body: String, identifier: String? = nil) async {
        guard isAuthorized else {
            print("⚠️ Notifications not authorized")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let id = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: nil // Show immediately
        )

        do {
            try await notificationCenter.add(request)
            print("✅ Showed local notification: \(title)")
        } catch {
            print("❌ Failed to show notification: \(error)")
        }
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    // MARK: - Notification Categories

    func setupNotificationCategories() {
        // Task actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_TASK",
            title: "Mark Complete",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_TASK",
            title: "Snooze 1 Hour",
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Event actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_EVENT",
            title: "View Event",
            options: [.foreground]
        )

        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [viewAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Daily summary
        let openAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "Open App",
            options: [.foreground]
        )

        let summaryCategory = UNNotificationCategory(
            identifier: "DAILY_SUMMARY",
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([taskCategory, eventCategory, summaryCategory])
    }

    // MARK: - Pending Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Removed all pending notifications")
    }
    
    // MARK: - Collaboration Notifications
    
    func scheduleMessageFromChrisNotification(messageId: Int, content: String) async {
        guard isAuthorized else { return }
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Message from Chris"
        notificationContent.body = content
        notificationContent.sound = .default
        notificationContent.badge = 1
        notificationContent.categoryIdentifier = "MESSAGE_FROM_CHRIS"
        notificationContent.userInfo = ["messageId": messageId, "type": "message_chris", "from": "magicalgirl"]
        notificationContent.threadIdentifier = "chris_messages"
        
        let request = UNNotificationRequest(
            identifier: "message_chris_\(messageId)",
            content: notificationContent,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("❌ Failed to schedule message notification: \(error)")
        }
    }
    
    func scheduleSharedEventNotification(eventId: Int, title: String, startTime: Date) async {
        guard isAuthorized else { return }
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Shared Event: \(title)"
        notificationContent.body = "Starting at \(startTime.formatted(.dateTime.hour().minute()))"
        notificationContent.sound = .default
        notificationContent.badge = 1
        notificationContent.categoryIdentifier = "SHARED_EVENT"
        notificationContent.userInfo = ["eventId": eventId, "type": "shared_event"]
        
        let reminderDate = startTime.addingTimeInterval(-900)
        
        if reminderDate > Date() {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "shared_event_\(eventId)",
                content: notificationContent,
                trigger: trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                print("❌ Failed to schedule shared event notification: \(error)")
            }
        }
    }
    
    func scheduleSharedTaskCompletedNotification(taskId: Int, taskTitle: String, completedBy: String) async {
        guard isAuthorized else { return }
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Task Completed!"
        notificationContent.body = "\(completedBy) completed: \(taskTitle)"
        notificationContent.sound = .default
        notificationContent.badge = 1
        notificationContent.categoryIdentifier = "SHARED_TASK_COMPLETED"
        notificationContent.userInfo = ["taskId": taskId, "type": "shared_task_completed"]
        
        let request = UNNotificationRequest(
            identifier: "shared_task_completed_\(taskId)",
            content: notificationContent,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("❌ Failed to schedule task completion notification: \(error)")
        }
    }
    
    func setupCollaborationNotificationCategories() {
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE_FROM_CHRIS",
            actions: [
                UNNotificationAction(identifier: "REPLY", title: "Reply", options: [.foreground]),
                UNNotificationAction(identifier: "VIEW", title: "View", options: [.foreground])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let sharedEventCategory = UNNotificationCategory(
            identifier: "SHARED_EVENT",
            actions: [
                UNNotificationAction(identifier: "VIEW_EVENT", title: "View Event", options: [.foreground]),
                UNNotificationAction(identifier: "SNOOZE", title: "Snooze 15 min", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let taskCompletedCategory = UNNotificationCategory(
            identifier: "SHARED_TASK_COMPLETED",
            actions: [
                UNNotificationAction(identifier: "VIEW_TASK", title: "View Task", options: [.foreground]),
                UNNotificationAction(identifier: "CELEBRATE", title: "Celebrate!", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            messageCategory,
            sharedEventCategory,
            taskCompletedCategory
        ])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notifications when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        _Concurrency.Task { @MainActor in
            await handleNotificationResponse(response: response, userInfo: userInfo)
        }

        completionHandler()
    }

    @MainActor
    private func handleNotificationResponse(response: UNNotificationResponse, userInfo: [AnyHashable: Any]) {
        print("📲 Notification tapped: \(response.actionIdentifier)")

        switch response.actionIdentifier {
        case "COMPLETE_TASK":
            if let taskId = userInfo["taskId"] as? Int {
                print("✅ Complete task: \(taskId)")
                _Concurrency.Task {
                    do {
                        _ = try await APIClient.shared.updateTask(id: taskId, completed: true)
                        print("✅ Task \(taskId) marked as completed")
                        // Cancel the notification since task is complete
                        cancelTaskReminder(taskId: taskId)
                    } catch {
                        print("❌ Failed to complete task \(taskId): \(error)")
                    }
                }
            }

        case "SNOOZE_TASK":
            if let taskId = userInfo["taskId"] as? Int {
                print("⏰ Snooze task: \(taskId)")
                // Reschedule notification for 1 hour from now
                let snoozeDate = Date().addingTimeInterval(3600) // 1 hour from now
                // Get task title from userInfo or use a generic title
                let taskTitle = userInfo["taskTitle"] as? String ?? "Task"
                _Concurrency.Task {
                    await scheduleTaskReminder(taskId: taskId, title: taskTitle, dueDate: snoozeDate)
                    print("⏰ Task \(taskId) snoozed until \(snoozeDate)")
                }
            }

        case "VIEW_EVENT":
            if let eventId = userInfo["eventId"] as? Int {
                print("📅 View event: \(eventId)")
                // Post notification to navigate to event
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToEvent"),
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped notification
            print("👆 Default tap action")
            // Handle default tap - navigate based on notification type
            if let taskId = userInfo["taskId"] as? Int {
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToTask"),
                    object: nil,
                    userInfo: ["taskId": taskId]
                )
            } else if let eventId = userInfo["eventId"] as? Int {
                NotificationCenter.default.post(
                    name: Notification.Name("NavigateToEvent"),
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            }

        default:
            break
        }

        // Clear badge when notification is handled
        clearBadge()
    }
}
