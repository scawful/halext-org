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
    let status: String? // "online", "away", "busy", "offline"
    let currentActivity: String?
    let statusMessage: String?
    let lastSeen: Date?
    
    enum CodingKeys: String, CodingKey {
        case username
        case isOnline = "is_online"
        case status
        case currentActivity = "current_activity"
        case statusMessage = "status_message"
        case lastSeen = "last_seen"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        currentActivity = try container.decodeIfPresent(String.self, forKey: .currentActivity)
        statusMessage = try container.decodeIfPresent(String.self, forKey: .statusMessage)
        
        // Custom date decoding for lastSeen (handles dates with/without 'Z')
        if let dateString = try container.decodeIfPresent(String.self, forKey: .lastSeen) {
            var decodedDate: Date?
            
            // Try ISO8601 formatters first
            let isoFormatter1 = ISO8601DateFormatter()
            if let date = isoFormatter1.date(from: dateString) {
                decodedDate = date
            } else {
                let isoFormatter2 = ISO8601DateFormatter()
                isoFormatter2.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = isoFormatter2.date(from: dateString) {
                    decodedDate = date
                } else {
                    // Try DateFormatter for dates without 'Z'
                    let dateFormatter1 = DateFormatter()
                    dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                    dateFormatter1.timeZone = TimeZone(secondsFromGMT: 0)
                    if let date = dateFormatter1.date(from: dateString) {
                        decodedDate = date
                    } else {
                        let dateFormatter2 = DateFormatter()
                        dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        dateFormatter2.timeZone = TimeZone(secondsFromGMT: 0)
                        decodedDate = dateFormatter2.date(from: dateString)
                    }
                }
            }
            lastSeen = decodedDate
        } else {
            lastSeen = nil
        }
    }
}

