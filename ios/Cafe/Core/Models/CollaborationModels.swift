//
//  CollaborationModels.swift
//  Cafe
//
//  Models for collaboration features (memories, goals, etc.)
//

import Foundation

// MARK: - Memory

struct Memory: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String?
    let photos: [String]? // URLs to photos
    let location: String?
    let sharedWith: [String]
    let createdAt: Date
    let updatedAt: Date
    let createdBy: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, photos, location
        case sharedWith = "shared_with"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
    }
}

struct MemoryCreate: Codable {
    let title: String
    let content: String?
    let photos: [String]?
    let location: String?
    let sharedWith: [String]
    
    enum CodingKeys: String, CodingKey {
        case title, content, photos, location
        case sharedWith = "shared_with"
    }
}

struct MemoryUpdate: Codable {
    let title: String?
    let content: String?
    let photos: [String]?
    let location: String?
    let sharedWith: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title, content, photos, location
        case sharedWith = "shared_with"
    }
}

// MARK: - Goal

struct Goal: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let progress: Double // 0.0 to 1.0
    let sharedWith: [String]
    let milestones: [Milestone]
    let createdAt: Date
    let updatedAt: Date
    let createdBy: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, progress, milestones
        case sharedWith = "shared_with"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
    }
}

struct GoalCreate: Codable {
    let title: String
    let description: String?
    let sharedWith: [String]
    
    enum CodingKeys: String, CodingKey {
        case title, description
        case sharedWith = "shared_with"
    }
}

// MARK: - Milestone

struct Milestone: Codable, Identifiable {
    let id: Int
    let goalId: Int
    let title: String
    let description: String?
    let completed: Bool
    let completedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, completed
        case goalId = "goal_id"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
}

struct MilestoneCreate: Codable {
    let title: String
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case title, description
    }
}

// MARK: - Partner Presence

struct PartnerPresence: Codable {
    let username: String
    let isOnline: Bool
    let currentActivity: String?
    let statusMessage: String?
    let lastSeen: Date?
    
    enum CodingKeys: String, CodingKey {
        case username
        case isOnline = "is_online"
        case currentActivity = "current_activity"
        case statusMessage = "status_message"
        case lastSeen = "last_seen"
    }
}

