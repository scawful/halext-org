//
//  Models.swift
//  Cafe
//
//  Data models matching the backend API
//

import Foundation

// MARK: - Authentication

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }
}

struct UserCreate: Codable {
    let username: String
    let email: String
    let password: String
    let fullName: String?

    enum CodingKeys: String, CodingKey {
        case username, email, password
        case fullName = "full_name"
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let fullName: String?
    let createdAt: Date
    let isAdmin: Bool

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case fullName = "full_name"
        case createdAt = "created_at"
        case isAdmin = "is_admin"
    }
}

// MARK: - Tasks

struct TaskCreate: Codable {
    let title: String
    let description: String?
    let dueDate: Date?
    let labels: [String]

    enum CodingKeys: String, CodingKey {
        case title, description, labels
        case dueDate = "due_date"
    }

    init(title: String, description: String? = nil, dueDate: Date? = nil, labels: [String] = []) {
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.labels = labels
    }
}

struct TaskUpdate: Codable {
    let completed: Bool
}

struct Task: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let completed: Bool
    let dueDate: Date?
    let createdAt: Date
    let ownerId: Int
    let labels: [TaskLabel]

    enum CodingKeys: String, CodingKey {
        case id, title, description, completed, labels
        case dueDate = "due_date"
        case createdAt = "created_at"
        case ownerId = "owner_id"
    }
}

struct TaskLabel: Codable, Identifiable {
    let id: Int
    let name: String
    let color: String?
}

// MARK: - Events

struct EventCreate: Codable {
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let location: String?
    let recurrenceType: String
    let recurrenceInterval: Int
    let recurrenceEndDate: Date?

    enum CodingKeys: String, CodingKey {
        case title, description, location
        case startTime = "start_time"
        case endTime = "end_time"
        case recurrenceType = "recurrence_type"
        case recurrenceInterval = "recurrence_interval"
        case recurrenceEndDate = "recurrence_end_date"
    }

    init(title: String, description: String? = nil, startTime: Date, endTime: Date, location: String? = nil) {
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.recurrenceType = "none"
        self.recurrenceInterval = 1
        self.recurrenceEndDate = nil
    }
}

struct Event: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let location: String?
    let recurrenceType: String
    let recurrenceInterval: Int
    let recurrenceEndDate: Date?
    let ownerId: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, location
        case startTime = "start_time"
        case endTime = "end_time"
        case recurrenceType = "recurrence_type"
        case recurrenceInterval = "recurrence_interval"
        case recurrenceEndDate = "recurrence_end_date"
        case ownerId = "owner_id"
    }
}

// MARK: - AI Models

// Note: Using AiChatMessage from AiChatMessage.swift for typed chat messages
// This ChatMessage is for API compatibility with backend
struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct AIChatRequest: Codable {
    let prompt: String
    let history: [ChatMessage]
    let model: String?

    init(prompt: String, history: [ChatMessage] = [], model: String? = nil) {
        self.prompt = prompt
        self.history = history
        self.model = model
    }
}

struct AIChatResponse: Codable {
    let response: String
    let model: String
    let provider: String
}

/// Represents a chunk of streamed content from the AI
struct StreamChunk: Codable {
    let content: String
    let isDone: Bool?

    enum CodingKeys: String, CodingKey {
        case content
        case isDone = "is_done"
    }

    init(content: String, isDone: Bool? = nil) {
        self.content = content
        self.isDone = isDone
    }
}

struct AITaskSuggestionsRequest: Codable {
    let title: String
    let description: String?
}

struct AITaskSuggestions: Codable {
    let subtasks: [String]
    let labels: [String]
    let estimatedHours: Double
    let priority: String
    let priorityReasoning: String

    enum CodingKeys: String, CodingKey {
        case subtasks, labels, priority
        case estimatedHours = "estimated_hours"
        case priorityReasoning = "priority_reasoning"
    }
}
