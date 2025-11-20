//
//  MessageModels.swift
//  Cafe
//
//  User-to-user messaging models
//

import Foundation

// MARK: - Conversation

struct Conversation: Codable, Identifiable {
    let id: Int
    let participants: [User]
    let lastMessage: Message?
    let unreadCount: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, participants
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var otherParticipant: User? {
        // Assuming two-person conversations
        participants.first { $0.id != KeychainManager.shared.getUserId() }
    }

    var displayName: String {
        otherParticipant?.fullName ?? otherParticipant?.username ?? "Unknown"
    }
}

// MARK: - Message

struct Message: Codable, Identifiable {
    let id: Int
    let conversationId: Int
    let senderId: Int
    let content: String
    let messageType: MessageType
    let isRead: Bool
    let createdAt: Date
    let updatedAt: Date
    let modelUsed: String?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case content
        case messageType = "message_type"
        case isRead = "is_read"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case modelUsed = "model_used"
    }

    var isFromCurrentUser: Bool {
        senderId == KeychainManager.shared.getUserId()
    }

    var isFromAI: Bool {
        modelUsed != nil
    }
}

enum MessageType: String, Codable {
    case text = "text"
    case image = "image"
    case file = "file"
    case system = "system"
}

// MARK: - Create Models

struct ConversationCreate: Codable {
    let participantIds: [Int]

    enum CodingKeys: String, CodingKey {
        case participantIds = "participant_ids"
    }
}

struct MessageCreate: Codable {
    let conversationId: Int
    let content: String
    let messageType: String

    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case content
        case messageType = "message_type"
    }
}

// Keychain extension for user ID
extension KeychainManager {
    func getUserId() -> Int? {
        // Try to get from stored current user data or return nil
        // This will need to be set when user logs in
        return UserDefaults.standard.value(forKey: "currentUserId") as? Int
    }

    func saveUserId(_ userId: Int) {
        UserDefaults.standard.set(userId, forKey: "currentUserId")
    }
}
