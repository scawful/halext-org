//
//  AdminModels.swift
//  Cafe
//
//  Admin-specific data models
//

import Foundation

// MARK: - System Statistics

struct SystemStats: Codable {
    let totalUsers: Int
    let totalTasks: Int
    let totalEvents: Int
    let totalMessages: Int
    let activeUsers: Int
    let tasksCompletedToday: Int
    let eventsToday: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case totalTasks = "total_tasks"
        case totalEvents = "total_events"
        case totalMessages = "total_messages"
        case activeUsers = "active_users"
        case tasksCompletedToday = "tasks_completed_today"
        case eventsToday = "events_today"
    }
}

// MARK: - Server Health

struct ServerHealth: Codable {
    let status: String
    let apiStatus: String
    let databaseStatus: String
    let aiServiceStatus: String
    let averageResponseTime: Double
    let uptime: Int
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case status
        case apiStatus = "api_status"
        case databaseStatus = "database_status"
        case aiServiceStatus = "ai_service_status"
        case averageResponseTime = "average_response_time"
        case uptime
        case timestamp
    }

    var statusColor: String {
        switch status.lowercased() {
        case "healthy": return "green"
        case "degraded": return "yellow"
        case "down": return "red"
        default: return "gray"
        }
    }
}

// MARK: - User Management

struct AdminUser: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let fullName: String?
    let isAdmin: Bool
    let isActive: Bool
    let createdAt: Date
    let lastLoginAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case fullName = "full_name"
        case isAdmin = "is_admin"
        case isActive = "is_active"
        case createdAt = "created_at"
        case lastLoginAt = "last_login_at"
    }
}

struct UserRoleUpdate: Codable {
    let isAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case isAdmin = "is_admin"
    }
}

struct UserStatusUpdate: Codable {
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

// MARK: - AI Client Management

struct AIClientNode: Codable, Identifiable {
    let id: Int
    let name: String
    let nodeType: String
    let hostname: String
    let port: Int
    let isActive: Bool
    let isPublic: Bool
    let status: String
    let lastSeenAt: String?
    let capabilities: [String: String]
    let nodeMetadata: [String: String]
    let baseUrl: String
    let ownerId: Int

    enum CodingKeys: String, CodingKey {
        case id, name, hostname, port, status, capabilities
        case nodeType = "node_type"
        case isActive = "is_active"
        case isPublic = "is_public"
        case lastSeenAt = "last_seen_at"
        case nodeMetadata = "node_metadata"
        case baseUrl = "base_url"
        case ownerId = "owner_id"
    }

    var statusColor: String {
        switch status.lowercased() {
        case "online": return "green"
        case "offline": return "red"
        case "degraded": return "yellow"
        default: return "gray"
        }
    }
}

struct AIClientNodeCreate: Codable {
    let name: String
    let nodeType: String
    let hostname: String
    let port: Int
    let isPublic: Bool
    let nodeMetadata: [String: String]

    enum CodingKeys: String, CodingKey {
        case name, hostname, port
        case nodeType = "node_type"
        case isPublic = "is_public"
        case nodeMetadata = "node_metadata"
    }
}

struct AIClientNodeUpdate: Codable {
    let name: String?
    let isActive: Bool?
    let isPublic: Bool?
    let nodeMetadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case name
        case isActive = "is_active"
        case isPublic = "is_public"
        case nodeMetadata = "node_metadata"
    }
}

struct ConnectionTestResponse: Codable {
    let status: String
    let online: Bool
    let message: String?
    let models: [String]?
    let modelCount: Int?
    let responseTimeMs: Int?

    enum CodingKeys: String, CodingKey {
        case status, online, message, models
        case modelCount = "model_count"
        case responseTimeMs = "response_time_ms"
    }
}

// MARK: - Content Management (CMS)

struct SitePage: Codable, Identifiable {
    let id: Int
    let slug: String
    let title: String
    let summary: String?
    let heroImageUrl: String?
    let sections: [[String: String]]
    let navLinks: [[String: String]]
    let theme: String
    let isPublished: Bool
    let ownerId: Int
    let updatedById: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, slug, title, summary, sections, theme
        case heroImageUrl = "hero_image_url"
        case navLinks = "nav_links"
        case isPublished = "is_published"
        case ownerId = "owner_id"
        case updatedById = "updated_by_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PhotoAlbum: Codable, Identifiable {
    let id: Int
    let slug: String
    let title: String
    let description: String?
    let coverImageUrl: String?
    let heroText: String?
    let photos: [[String: String]]
    let isPublic: Bool
    let ownerId: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, slug, title, description, photos
        case coverImageUrl = "cover_image_url"
        case heroText = "hero_text"
        case isPublic = "is_public"
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct BlogPost: Codable, Identifiable {
    let id: Int
    let slug: String
    let title: String
    let excerpt: String?
    let content: String
    let coverImageUrl: String?
    let authorName: String
    let isPublished: Bool
    let publishedAt: Date?
    let ownerId: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, slug, title, excerpt, content
        case coverImageUrl = "cover_image_url"
        case authorName = "author_name"
        case isPublished = "is_published"
        case publishedAt = "published_at"
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Admin Actions

struct CacheClearResponse: Codable {
    let status: String
    let message: String
    let itemsCleared: Int?

    enum CodingKeys: String, CodingKey {
        case status, message
        case itemsCleared = "items_cleared"
    }
}

struct RebuildResponse: Codable {
    let status: String
    let message: String
    let output: String?
}
