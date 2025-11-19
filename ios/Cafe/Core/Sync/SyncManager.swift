//
//  SyncManager.swift
//  Cafe
//
//  Manages synchronization between local storage and API
//

import Foundation
import SwiftData

@MainActor
@Observable
class SyncManager {
    static let shared = SyncManager()

    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncError: String?

    private let storage = StorageManager.shared
    private let api = APIClient.shared
    private let network = NetworkMonitor.shared

    private var syncTask: _Concurrency.Task<Void, Never>?

    private init() {
        setupNetworkObservers()
    }

    // MARK: - Network Observers

    private func setupNetworkObservers() {
        NotificationCenter.default.addObserver(
            forName: .networkConnected,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor [weak self] in
                await self?.syncAll()
            }
        }
    }

    // MARK: - Full Sync

    func syncAll() async {
        guard !isSyncing else {
            print("⚠️ Sync already in progress")
            return
        }

        guard network.isConnected else {
            print("📴 Cannot sync: No network connection")
            return
        }

        isSyncing = true
        syncError = nil
        print("🔄 Starting full sync...")

        do {
            // First, process pending actions
            try await processPendingActions()

            // Then sync down from server
            try await syncTasksFromServer()
            try await syncEventsFromServer()

            lastSyncDate = Date()
            print("✅ Full sync completed")
        } catch {
            syncError = error.localizedDescription
            print("❌ Sync failed: \(error.localizedDescription)")
        }

        isSyncing = false
    }

    // MARK: - Process Pending Actions

    private func processPendingActions() async throws {
        let pendingActions = try storage.fetchPendingActions()

        guard !pendingActions.isEmpty else {
            print("✅ No pending actions to process")
            return
        }

        print("📋 Processing \(pendingActions.count) pending actions...")

        for action in pendingActions {
            do {
                try await processAction(action)
                try storage.deletePendingAction(action)
            } catch {
                // If failed and retry count < 3, increment and keep
                if action.retryCount < 3 {
                    try storage.incrementRetryCount(action)
                    print("⚠️ Action failed, will retry: \(action.actionType) (retry \(action.retryCount + 1)/3)")
                } else {
                    // Max retries reached, delete action
                    try storage.deletePendingAction(action)
                    print("❌ Action failed after 3 retries, discarding: \(action.actionType)")
                }
            }
        }
    }

    private func processAction(_ action: PendingActionModel) async throws {
        print("⚙️ Processing action: \(action.actionType)")

        switch action.actionType {
        case "createTask":
            guard let payload = action.payload,
                  let taskCreate = try? JSONDecoder().decode(TaskCreate.self, from: payload) else {
                throw SyncError.invalidPayload
            }
            _ = try await api.createTask(taskCreate)

        case "updateTask":
            guard let entityId = action.entityId,
                  let payload = action.payload,
                  let completed = try? JSONDecoder().decode(Bool.self, from: payload) else {
                throw SyncError.invalidPayload
            }
            _ = try await api.updateTask(id: entityId, completed: completed)

        case "deleteTask":
            guard let entityId = action.entityId else {
                throw SyncError.invalidPayload
            }
            try await api.deleteTask(id: entityId)

        case "createEvent":
            guard let payload = action.payload,
                  let eventCreate = try? JSONDecoder().decode(EventCreate.self, from: payload) else {
                throw SyncError.invalidPayload
            }
            _ = try await api.createEvent(eventCreate)

        default:
            print("⚠️ Unknown action type: \(action.actionType)")
        }

        print("✅ Completed action: \(action.actionType)")
    }

    // MARK: - Sync from Server

    private func syncTasksFromServer() async throws {
        print("📥 Syncing tasks from server...")
        let tasks = try await api.getTasks()
        try storage.saveTasks(tasks)

        // Update Spotlight index
        SpotlightManager.shared.indexTasks(tasks)

        print("✅ Synced \(tasks.count) tasks")
    }

    private func syncEventsFromServer() async throws {
        print("📥 Syncing events from server...")
        let events = try await api.getEvents()
        try storage.saveEvents(events)

        // Update Spotlight index
        SpotlightManager.shared.indexEvents(events)

        print("✅ Synced \(events.count) events")
    }

    // MARK: - Offline Operations

    func createTaskOffline(_ taskCreate: TaskCreate) async throws -> Task {
        // Generate temporary ID
        let tempId = -Int(Date().timeIntervalSince1970)

        // Create temporary task object
        let task = Task(
            id: tempId,
            title: taskCreate.title,
            description: taskCreate.description,
            completed: false,
            dueDate: taskCreate.dueDate,
            createdAt: Date(),
            ownerId: 0, // Will be set by server
            labels: []
        )

        // Save to local storage
        try storage.saveTask(task)

        // Queue for sync
        let payload = try JSONEncoder().encode(taskCreate)
        try storage.savePendingAction(
            actionType: "createTask",
            entityType: "task",
            entityId: tempId,
            payload: payload
        )

        print("📱 Created task offline: \(task.title)")
        return task
    }

    func updateTaskOffline(id: Int, completed: Bool) async throws {
        // Update local storage
        guard let task = try storage.fetchTask(id: id) else {
            throw SyncError.taskNotFound
        }

        // Create updated task with new completed status
        let updatedTask = Task(
            id: task.id,
            title: task.title,
            description: task.description,
            completed: completed,
            dueDate: task.dueDate,
            createdAt: task.createdAt,
            ownerId: task.ownerId,
            labels: task.labels
        )

        try storage.updateTask(updatedTask)

        // Queue for sync
        let payload = try JSONEncoder().encode(completed)
        try storage.savePendingAction(
            actionType: "updateTask",
            entityType: "task",
            entityId: id,
            payload: payload
        )

        print("📱 Updated task offline: \(task.title)")
    }

    func deleteTaskOffline(id: Int) async throws {
        // Delete from local storage
        try storage.deleteTask(id: id)

        // Queue for sync
        try storage.savePendingAction(
            actionType: "deleteTask",
            entityType: "task",
            entityId: id
        )

        // Remove from Spotlight
        SpotlightManager.shared.removeTask(id: id)

        print("📱 Deleted task offline: \(id)")
    }

    func createEventOffline(_ eventCreate: EventCreate) async throws -> Event {
        let tempId = -Int(Date().timeIntervalSince1970)

        let event = Event(
            id: tempId,
            title: eventCreate.title,
            description: eventCreate.description,
            startTime: eventCreate.startTime,
            endTime: eventCreate.endTime,
            location: eventCreate.location,
            recurrenceType: eventCreate.recurrenceType,
            recurrenceInterval: eventCreate.recurrenceInterval,
            recurrenceEndDate: eventCreate.recurrenceEndDate,
            ownerId: 0
        )

        try storage.saveEvent(event)

        let payload = try JSONEncoder().encode(eventCreate)
        try storage.savePendingAction(
            actionType: "createEvent",
            entityType: "event",
            entityId: tempId,
            payload: payload
        )

        print("📱 Created event offline: \(event.title)")
        return event
    }

    // MARK: - Load from Cache

    func loadTasksFromCache() throws -> [Task] {
        return try storage.fetchTasks()
    }

    func loadEventsFromCache() throws -> [Event] {
        return try storage.fetchEvents()
    }

    // MARK: - Cleanup

    func clearCache() async throws {
        try storage.clearAllData()
        lastSyncDate = nil
        print("🗑️ Cleared local cache")
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case invalidPayload
    case taskNotFound
    case eventNotFound
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidPayload:
            return "Invalid action payload"
        case .taskNotFound:
            return "Task not found in local storage"
        case .eventNotFound:
            return "Event not found in local storage"
        case .networkUnavailable:
            return "Network connection unavailable"
        }
    }
}
