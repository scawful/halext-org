//
//  BackgroundTaskManager.swift
//  Cafe
//
//  Background App Refresh for syncing and widget updates
//

import Foundation
import BackgroundTasks
import UIKit

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    // Background task identifiers (must match Info.plist)
    static let refreshIdentifier = "org.halext.cafe.refresh"
    static let syncIdentifier = "org.halext.cafe.sync"

    private init() {}

    // MARK: - Register Tasks

    func registerBackgroundTasks() {
        // Register refresh task (runs more frequently)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager.refreshIdentifier,
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        // Register processing task (for heavy sync operations)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskManager.syncIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundSync(task: task as! BGProcessingTask)
        }

        print("✅ Registered background tasks")
    }

    // MARK: - Schedule Tasks

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskManager.refreshIdentifier)

        // Schedule to run in 15 minutes
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Scheduled app refresh task")
        } catch {
            print("❌ Could not schedule app refresh: \(error.localizedDescription)")
        }
    }

    func scheduleBackgroundSync() {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskManager.syncIdentifier)

        // Require network connection
        request.requiresNetworkConnectivity = true

        // Don't require external power (allow on battery)
        request.requiresExternalPower = false

        // Schedule to run in 1 hour
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Scheduled background sync task")
        } catch {
            print("❌ Could not schedule background sync: \(error.localizedDescription)")
        }
    }

    // MARK: - Handle Refresh Task

    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("🔄 Handling app refresh task...")

        // Schedule next refresh
        scheduleAppRefresh()

        // Create operation for refresh
        let operation = RefreshOperation()

        task.expirationHandler = {
            // Handle task expiration
            operation.cancel()
            print("⏰ App refresh task expired")
        }

        operation.completionBlock = {
            let success = !operation.isCancelled
            task.setTaskCompleted(success: success)
            print(success ? "✅ App refresh completed" : "❌ App refresh cancelled")
        }

        // Execute refresh
        OperationQueue().addOperation(operation)
    }

    // MARK: - Handle Background Sync

    private func handleBackgroundSync(task: BGProcessingTask) {
        print("🔄 Handling background sync task...")

        // Schedule next sync
        scheduleBackgroundSync()

        // Create operation for sync
        let operation = SyncOperation()

        task.expirationHandler = {
            operation.cancel()
            print("⏰ Background sync task expired")
        }

        operation.completionBlock = {
            let success = !operation.isCancelled
            task.setTaskCompleted(success: success)
            print(success ? "✅ Background sync completed" : "❌ Background sync cancelled")
        }

        // Execute sync
        OperationQueue().addOperation(operation)
    }

    // MARK: - Cancel All Tasks

    func cancelAllTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundTaskManager.refreshIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundTaskManager.syncIdentifier)
        print("🚫 Cancelled all background tasks")
    }
}

// MARK: - Refresh Operation

class RefreshOperation: Operation {
    override func main() {
        guard !isCancelled else { return }

        print("📡 Refreshing widget data...")

        let semaphore = DispatchSemaphore(value: 0)

        // Fetch latest data
        _Concurrency.Task {
            do {
                // Quick data fetch for widgets
                let tasks = try await APIClient.shared.getTasks()
                let events = try await APIClient.shared.getEvents()

                guard !self.isCancelled else {
                    semaphore.signal()
                    return
                }

                // Update widget data
                WidgetUpdateManager.shared.updateAll(tasks: tasks, events: events)

                print("✅ Widget data refreshed: \(tasks.count) tasks, \(events.count) events")
            } catch {
                print("❌ Refresh failed: \(error.localizedDescription)")
            }

            semaphore.signal()
        }

        semaphore.wait()
    }
}

// MARK: - Sync Operation

class SyncOperation: Operation {
    override func main() {
        guard !isCancelled else { return }

        print("🔄 Performing background sync...")

        let semaphore = DispatchSemaphore(value: 0)

        // Full sync operation
        _Concurrency.Task {
            await SyncManager.shared.syncAll()
            semaphore.signal()
        }

        semaphore.wait()
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension BackgroundTaskManager {
    /// Simulate background fetch for testing
    func simulateBackgroundFetch() {
        print("🧪 Simulating background fetch...")

        _Concurrency.Task {
            do {
                let tasks = try await APIClient.shared.getTasks()
                let events = try await APIClient.shared.getEvents()

                WidgetUpdateManager.shared.updateAll(tasks: tasks, events: events)

                print("✅ Simulated background fetch completed")
            } catch {
                print("❌ Simulated background fetch failed: \(error.localizedDescription)")
            }
        }
    }
}
#endif
