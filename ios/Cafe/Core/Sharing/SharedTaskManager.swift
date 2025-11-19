//
//  SharedTaskManager.swift
//  Cafe
//
//  Processes tasks shared from Share Extension
//

import Foundation

@MainActor
class SharedTaskManager {
    static let shared = SharedTaskManager()

    private let appGroupIdentifier = "group.org.halext.cafe"
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Process Pending Shared Tasks

    func processPendingSharedTasks() async {
        guard let userDefaults = userDefaults,
              let pendingTasks = userDefaults.array(forKey: "pendingSharedTasks") as? [[String: Any]],
              !pendingTasks.isEmpty else {
            return
        }

        print("📱 Processing \(pendingTasks.count) pending shared tasks...")

        for taskData in pendingTasks {
            await processSharedTask(taskData)
        }

        // Clear processed tasks
        userDefaults.removeObject(forKey: "pendingSharedTasks")
        userDefaults.synchronize()

        print("✅ Processed all shared tasks")
    }

    private func processSharedTask(_ taskData: [String: Any]) async {
        guard let title = taskData["title"] as? String else {
            return
        }

        let description = taskData["description"] as? String
        let url = taskData["url"] as? String

        // Combine description with URL if present
        var fullDescription = description ?? ""
        if let url = url, !url.isEmpty {
            if !fullDescription.isEmpty {
                fullDescription += "\n\n"
            }
            fullDescription += "Link: \(url)"
        }

        // Create task
        let taskCreate = TaskCreate(
            title: title,
            description: fullDescription.isEmpty ? nil : fullDescription,
            dueDate: nil,
            labels: ["shared"] // Add "shared" label to track these tasks
        )

        do {
            if NetworkMonitor.shared.isConnected {
                // Online: create via API
                let task = try await APIClient.shared.createTask(taskCreate)
                try? StorageManager.shared.saveTask(task)
                print("✅ Created shared task: \(task.title)")
            } else {
                // Offline: create locally
                let task = try await SyncManager.shared.createTaskOffline(taskCreate)
                print("📱 Created shared task offline: \(task.title)")
            }

            // Update widgets
            WidgetUpdateManager.shared.reloadTaskWidgets()

            // Show notification
            await NotificationManager.shared.showLocalNotification(
                title: "Task Created",
                body: "Created from shared content: \(title)"
            )
        } catch {
            print("❌ Failed to create shared task: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Share URL Scheme

    func handleShareURL(_ url: URL) async {
        guard url.scheme == "cafe",
              url.host == "share",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let dataParam = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let jsonData = Data(base64Encoded: dataParam),
              let taskData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }

        print("📱 Received shared task via URL scheme")
        await processSharedTask(taskData)
    }
}
