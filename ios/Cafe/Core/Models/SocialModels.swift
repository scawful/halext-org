//
//  SocialModels.swift
//  Cafe
//
//  Models for social features and collaboration
//

import Foundation
import SwiftUI

// MARK: - Social Profile

struct SocialProfile: Codable, Identifiable, Equatable {
    let id: String // CloudKit recordID or UUID
    let userId: Int // Backend user ID
    let username: String
    let displayName: String?
    let avatarURL: String?
    let statusMessage: String?
    let currentActivity: String?
    let isOnline: Bool
    let lastSeen: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, username, displayName, avatarURL, statusMessage
        case currentActivity, isOnline, lastSeen, createdAt, updatedAt
    }

    init(
        id: String = UUID().uuidString,
        userId: Int,
        username: String,
        displayName: String? = nil,
        avatarURL: String? = nil,
        statusMessage: String? = nil,
        currentActivity: String? = nil,
        isOnline: Bool = false,
        lastSeen: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.statusMessage = statusMessage
        self.currentActivity = currentActivity
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Connection

struct Connection: Codable, Identifiable, Equatable {
    let id: String
    let profileId: String
    let partnerProfileId: String
    let status: ConnectionStatus
    let inviteCode: String?
    let createdAt: Date
    let acceptedAt: Date?

    enum ConnectionStatus: String, Codable {
        case pending
        case accepted
        case blocked
    }

    init(
        id: String = UUID().uuidString,
        profileId: String,
        partnerProfileId: String,
        status: ConnectionStatus = .pending,
        inviteCode: String? = nil,
        createdAt: Date = Date(),
        acceptedAt: Date? = nil
    ) {
        self.id = id
        self.profileId = profileId
        self.partnerProfileId = partnerProfileId
        self.status = status
        self.inviteCode = inviteCode
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
    }
}

// MARK: - Shared Task

struct SharedTask: Codable, Identifiable, Equatable {
    let id: String
    let taskId: Int // Reference to backend task
    let title: String
    let description: String?
    let completed: Bool
    let dueDate: Date?
    let assignedToProfileId: String?
    let createdByProfileId: String
    let connectionId: String
    let labels: [String]
    let createdAt: Date
    let updatedAt: Date
    let completedAt: Date?
    let completedByProfileId: String?

    init(
        id: String = UUID().uuidString,
        taskId: Int,
        title: String,
        description: String? = nil,
        completed: Bool = false,
        dueDate: Date? = nil,
        assignedToProfileId: String? = nil,
        createdByProfileId: String,
        connectionId: String,
        labels: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        completedByProfileId: String? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.title = title
        self.description = description
        self.completed = completed
        self.dueDate = dueDate
        self.assignedToProfileId = assignedToProfileId
        self.createdByProfileId = createdByProfileId
        self.connectionId = connectionId
        self.labels = labels
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.completedByProfileId = completedByProfileId
    }
}

// MARK: - Activity Item

struct ActivityItem: Codable, Identifiable, Equatable {
    let id: String
    let connectionId: String
    let profileId: String
    let activityType: ActivityType
    let title: String
    let description: String?
    let relatedTaskId: String?
    let relatedEventId: Int?
    let timestamp: Date
    let metadata: [String: String]?

    enum ActivityType: String, Codable {
        case taskCreated
        case taskCompleted
        case taskAssigned
        case taskCommented
        case eventCreated
        case eventUpdated
        case statusChanged
        case connectionAccepted
    }

    init(
        id: String = UUID().uuidString,
        connectionId: String,
        profileId: String,
        activityType: ActivityType,
        title: String,
        description: String? = nil,
        relatedTaskId: String? = nil,
        relatedEventId: Int? = nil,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.connectionId = connectionId
        self.profileId = profileId
        self.activityType = activityType
        self.title = title
        self.description = description
        self.relatedTaskId = relatedTaskId
        self.relatedEventId = relatedEventId
        self.timestamp = timestamp
        self.metadata = metadata
    }

    var icon: String {
        switch activityType {
        case .taskCreated:
            return "plus.circle.fill"
        case .taskCompleted:
            return "checkmark.circle.fill"
        case .taskAssigned:
            return "person.crop.circle.badge.plus"
        case .taskCommented:
            return "bubble.left.fill"
        case .eventCreated:
            return "calendar.badge.plus"
        case .eventUpdated:
            return "calendar.badge.clock"
        case .statusChanged:
            return "circle.fill"
        case .connectionAccepted:
            return "person.2.fill"
        }
    }

    var iconColor: Color {
        switch activityType {
        case .taskCreated:
            return .blue
        case .taskCompleted:
            return .green
        case .taskAssigned:
            return .orange
        case .taskCommented:
            return .purple
        case .eventCreated:
            return .blue
        case .eventUpdated:
            return .cyan
        case .statusChanged:
            return .gray
        case .connectionAccepted:
            return .green
        }
    }
}

// MARK: - Task Comment

struct TaskComment: Codable, Identifiable, Equatable {
    let id: String
    let sharedTaskId: String
    let profileId: String
    let content: String
    let createdAt: Date
    let updatedAt: Date?

    init(
        id: String = UUID().uuidString,
        sharedTaskId: String,
        profileId: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.sharedTaskId = sharedTaskId
        self.profileId = profileId
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Social Presence Status

struct SocialPresenceStatus: Codable, Equatable {
    let profileId: String
    let isOnline: Bool
    let currentActivity: String?
    let statusMessage: String?
    let lastUpdated: Date

    init(
        profileId: String,
        isOnline: Bool = false,
        currentActivity: String? = nil,
        statusMessage: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.profileId = profileId
        self.isOnline = isOnline
        self.currentActivity = currentActivity
        self.statusMessage = statusMessage
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Invite Code

struct InviteCode: Codable, Identifiable, Equatable {
    let id: String
    let code: String
    let profileId: String
    let expiresAt: Date
    let createdAt: Date
    let maxUses: Int
    let currentUses: Int

    init(
        id: String = UUID().uuidString,
        code: String,
        profileId: String,
        expiresAt: Date,
        createdAt: Date = Date(),
        maxUses: Int = 1,
        currentUses: Int = 0
    ) {
        self.id = id
        self.code = code
        self.profileId = profileId
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.maxUses = maxUses
        self.currentUses = currentUses
    }

    var isValid: Bool {
        currentUses < maxUses && expiresAt > Date()
    }
}
