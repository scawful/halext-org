//
//  SwiftDataModels.swift
//  Cafe
//
//  SwiftData models for offline persistence
//

import Foundation
import SwiftData

// MARK: - Task Model

@Model
final class TaskModel {
    @Attribute(.unique) var id: Int
    var title: String
    var taskDescription: String?
    var completed: Bool
    var dueDate: Date?
    var createdAt: Date
    var updatedAt: Date
    var userId: Int

    // Relationships
    @Relationship(deleteRule: .cascade) var labels: [LabelModel]

    // Sync metadata
    var isSynced: Bool
    var lastSyncedAt: Date?
    var pendingAction: String? // "create", "update", "delete"

    init(
        id: Int,
        title: String,
        taskDescription: String? = nil,
        completed: Bool = false,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        userId: Int,
        labels: [LabelModel] = [],
        isSynced: Bool = false,
        lastSyncedAt: Date? = nil,
        pendingAction: String? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.completed = completed
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.userId = userId
        self.labels = labels
        self.isSynced = isSynced
        self.lastSyncedAt = lastSyncedAt
        self.pendingAction = pendingAction
    }

    // Convert to API model
    func toTask() -> Task {
        Task(
            id: id,
            title: title,
            description: taskDescription,
            completed: completed,
            dueDate: dueDate,
            createdAt: createdAt,
            ownerId: userId,
            labels: labels.map { $0.toTaskLabel() }
        )
    }

    // Create from API model
    static func from(_ task: Task) -> TaskModel {
        // Don't create any label relationships - labels cause SwiftData validation errors
        // Labels will be handled separately if needed
        TaskModel(
            id: task.id,
            title: task.title,
            taskDescription: task.description,
            completed: task.completed,
            dueDate: task.dueDate,
            createdAt: task.createdAt,
            updatedAt: Date(),
            userId: task.ownerId,
            labels: [], // Empty labels array to avoid SwiftData errors
            isSynced: true,
            lastSyncedAt: Date()
        )
    }
}

// MARK: - Event Model

@Model
final class EventModel {
    @Attribute(.unique) var id: Int
    var title: String
    var eventDescription: String?
    var startTime: Date
    var endTime: Date
    var location: String?
    var recurrenceType: String
    var recurrenceInterval: Int
    var recurrenceEndDate: Date?
    var ownerId: Int

    // Sync metadata
    var isSynced: Bool
    var lastSyncedAt: Date?
    var pendingAction: String?

    init(
        id: Int,
        title: String,
        eventDescription: String? = nil,
        startTime: Date,
        endTime: Date,
        location: String? = nil,
        recurrenceType: String = "none",
        recurrenceInterval: Int = 1,
        recurrenceEndDate: Date? = nil,
        ownerId: Int,
        isSynced: Bool = false,
        lastSyncedAt: Date? = nil,
        pendingAction: String? = nil
    ) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.recurrenceType = recurrenceType
        self.recurrenceInterval = recurrenceInterval
        self.recurrenceEndDate = recurrenceEndDate
        self.ownerId = ownerId
        self.isSynced = isSynced
        self.lastSyncedAt = lastSyncedAt
        self.pendingAction = pendingAction
    }

    func toEvent() -> Event {
        Event(
            id: id,
            title: title,
            description: eventDescription,
            startTime: startTime,
            endTime: endTime,
            location: location,
            recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval,
            recurrenceEndDate: recurrenceEndDate,
            ownerId: ownerId
        )
    }

    static func from(_ event: Event) -> EventModel {
        EventModel(
            id: event.id,
            title: event.title,
            eventDescription: event.description,
            startTime: event.startTime,
            endTime: event.endTime,
            location: event.location,
            recurrenceType: event.recurrenceType,
            recurrenceInterval: event.recurrenceInterval,
            recurrenceEndDate: event.recurrenceEndDate,
            ownerId: event.ownerId,
            isSynced: true,
            lastSyncedAt: Date()
        )
    }
}

// MARK: - Label Model

@Model
final class LabelModel {
    @Attribute(.unique) var id: Int
    var name: String
    var color: String?

    init(id: Int, name: String, color: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
    }

    func toTaskLabel() -> TaskLabel {
        TaskLabel(id: id, name: name, color: color)
    }

    static func from(_ label: TaskLabel) -> LabelModel {
        LabelModel(id: label.id, name: label.name, color: label.color)
    }
}

// MARK: - Pending Action Model

@Model
final class PendingActionModel {
    var id: UUID
    var actionType: String // "createTask", "updateTask", "deleteTask", etc.
    var entityType: String // "task", "event"
    var entityId: Int?
    var payload: Data? // JSON encoded data
    var createdAt: Date
    var retryCount: Int

    init(
        id: UUID = UUID(),
        actionType: String,
        entityType: String,
        entityId: Int? = nil,
        payload: Data? = nil,
        createdAt: Date = Date(),
        retryCount: Int = 0
    ) {
        self.id = id
        self.actionType = actionType
        self.entityType = entityType
        self.entityId = entityId
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = retryCount
    }
}
