//
//  StorageManager.swift
//  Cafe
//
//  Local storage manager using SwiftData
//

import Foundation
import SwiftData

@MainActor
class StorageManager {
    static let shared = StorageManager()

    private(set) var modelContainer: ModelContainer!
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        do {
            let schema = Schema([
                TaskModel.self,
                EventModel.self,
                LabelModel.self,
                PendingActionModel.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("✅ SwiftData container initialized")
        } catch {
            print("❌ Failed to initialize SwiftData: \(error)")
            fatalError("Could not initialize SwiftData container")
        }
    }

    // MARK: - Task Operations

    func saveTasks(_ tasks: [Task]) throws {
        // Clear existing tasks
        try modelContext.delete(model: TaskModel.self)

        // Insert new tasks
        for task in tasks {
            let taskModel = TaskModel.from(task)
            modelContext.insert(taskModel)
        }

        try modelContext.save()
        print("✅ Saved \(tasks.count) tasks to local storage")
    }

    func saveTask(_ task: Task) throws {
        let taskModel = TaskModel.from(task)
        modelContext.insert(taskModel)
        try modelContext.save()
        print("✅ Saved task to local storage: \(task.title)")
    }

    func updateTask(_ task: Task) throws {
        let descriptor = FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.id == task.id }
        )

        guard let existingTask = try modelContext.fetch(descriptor).first else {
            // Task doesn't exist, create it
            try saveTask(task)
            return
        }

        // Update properties
        existingTask.title = task.title
        existingTask.taskDescription = task.description
        existingTask.completed = task.completed
        existingTask.dueDate = task.dueDate
        existingTask.updatedAt = Date()
        // Don't update labels to avoid SwiftData validation errors
        // existingTask.labels = task.labels.map { LabelModel.from($0) }
        existingTask.isSynced = true
        existingTask.lastSyncedAt = Date()

        try modelContext.save()
        print("✅ Updated task in local storage: \(task.title)")
    }

    func deleteTask(id: Int) throws {
        let descriptor = FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.id == id }
        )

        guard let task = try modelContext.fetch(descriptor).first else {
            print("⚠️ Task \(id) not found in local storage")
            return
        }

        modelContext.delete(task)
        try modelContext.save()
        print("🗑️ Deleted task from local storage: \(id)")
    }

    func fetchTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<TaskModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let taskModels = try modelContext.fetch(descriptor)
        return taskModels.map { $0.toTask() }
    }

    func fetchTask(id: Int) throws -> Task? {
        let descriptor = FetchDescriptor<TaskModel>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first?.toTask()
    }

    // MARK: - Event Operations

    func saveEvents(_ events: [Event]) throws {
        // Clear existing events
        try modelContext.delete(model: EventModel.self)

        // Insert new events
        for event in events {
            let eventModel = EventModel.from(event)
            modelContext.insert(eventModel)
        }

        try modelContext.save()
        print("✅ Saved \(events.count) events to local storage")
    }

    func saveEvent(_ event: Event) throws {
        let eventModel = EventModel.from(event)
        modelContext.insert(eventModel)
        try modelContext.save()
        print("✅ Saved event to local storage: \(event.title)")
    }

    func updateEvent(_ event: Event) throws {
        let descriptor = FetchDescriptor<EventModel>(
            predicate: #Predicate { $0.id == event.id }
        )

        guard let existingEvent = try modelContext.fetch(descriptor).first else {
            try saveEvent(event)
            return
        }

        existingEvent.title = event.title
        existingEvent.eventDescription = event.description
        existingEvent.startTime = event.startTime
        existingEvent.endTime = event.endTime
        existingEvent.location = event.location
        existingEvent.recurrenceType = event.recurrenceType
        existingEvent.isSynced = true
        existingEvent.lastSyncedAt = Date()

        try modelContext.save()
        print("✅ Updated event in local storage: \(event.title)")
    }

    func deleteEvent(id: Int) throws {
        let descriptor = FetchDescriptor<EventModel>(
            predicate: #Predicate { $0.id == id }
        )

        guard let event = try modelContext.fetch(descriptor).first else {
            print("⚠️ Event \(id) not found in local storage")
            return
        }

        modelContext.delete(event)
        try modelContext.save()
        print("🗑️ Deleted event from local storage: \(id)")
    }

    func fetchEvents() throws -> [Event] {
        let descriptor = FetchDescriptor<EventModel>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )

        let eventModels = try modelContext.fetch(descriptor)
        return eventModels.map { $0.toEvent() }
    }

    // MARK: - Pending Actions

    func savePendingAction(
        actionType: String,
        entityType: String,
        entityId: Int? = nil,
        payload: Data? = nil
    ) throws {
        let action = PendingActionModel(
            actionType: actionType,
            entityType: entityType,
            entityId: entityId,
            payload: payload
        )

        modelContext.insert(action)
        try modelContext.save()
        print("📋 Saved pending action: \(actionType)")
    }

    func fetchPendingActions() throws -> [PendingActionModel] {
        let descriptor = FetchDescriptor<PendingActionModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        return try modelContext.fetch(descriptor)
    }

    func deletePendingAction(_ action: PendingActionModel) throws {
        modelContext.delete(action)
        try modelContext.save()
        print("✅ Completed pending action: \(action.actionType)")
    }

    func incrementRetryCount(_ action: PendingActionModel) throws {
        action.retryCount += 1
        try modelContext.save()
    }

    // MARK: - Cleanup

    func clearAllData() throws {
        try modelContext.delete(model: TaskModel.self)
        try modelContext.delete(model: EventModel.self)
        try modelContext.delete(model: LabelModel.self)
        try modelContext.delete(model: PendingActionModel.self)
        try modelContext.save()
        print("🗑️ Cleared all local data")
    }

    func clearPendingActions() throws {
        try modelContext.delete(model: PendingActionModel.self)
        try modelContext.save()
        print("🗑️ Cleared all pending actions")
    }
}
