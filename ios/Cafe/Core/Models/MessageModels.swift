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
    let title: String?
    let mode: String?
    let withAI: Bool?
    let defaultModelId: String?
    let hiveMindGoal: String?
    let participants: [User]
    let participantUsernames: [String]
    let lastMessage: Message?
    let unreadCount: Int
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, mode
        case withAI = "with_ai"
        case defaultModelId = "default_model_id"
        case hiveMindGoal = "hive_mind_goal"
        case participants
        case participantUsernames = "participant_usernames"
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    private enum AdditionalKeys: String, CodingKey {
        case participantDetails = "participant_details"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        mode = try container.decodeIfPresent(String.self, forKey: .mode)
        withAI = try container.decodeIfPresent(Bool.self, forKey: .withAI)
        defaultModelId = try container.decodeIfPresent(String.self, forKey: .defaultModelId)
        hiveMindGoal = try container.decodeIfPresent(String.self, forKey: .hiveMindGoal)
        lastMessage = try container.decodeIfPresent(Message.self, forKey: .lastMessage)
        unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        let detailsContainer = try? decoder.container(keyedBy: AdditionalKeys.self)

        if let users = try detailsContainer?.decodeIfPresent([User].self, forKey: .participantDetails) {
            participants = users
            participantUsernames = users.map { $0.username }
        } else if let users = try container.decodeIfPresent([User].self, forKey: .participants) {
            participants = users
            participantUsernames = users.map { $0.username }
        } else if let usernames = try container.decodeIfPresent([String].self, forKey: .participantUsernames) {
            participantUsernames = usernames
            participants = usernames.map {
                User(id: -1, username: $0, email: "", fullName: nil, createdAt: Date(), isAdmin: false)
            }
        } else {
            let usernames = try container.decodeIfPresent([String].self, forKey: .participants) ?? []
            participantUsernames = usernames
            participants = usernames.map {
                User(id: -1, username: $0, email: "", fullName: nil, createdAt: Date(), isAdmin: false)
            }
        }
    }

    var currentUsername: String? {
        UserDefaults.standard.string(forKey: "currentUsername")
    }

    var otherParticipantUsername: String? {
        participantUsernames.first { $0 != currentUsername }
    }

    var displayName: String {
        if let user = participants.first(where: { $0.username != currentUsername }) {
            return user.fullName ?? user.username
        }
        return otherParticipantUsername ?? title ?? "Conversation"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(mode, forKey: .mode)
        try container.encodeIfPresent(withAI, forKey: .withAI)
        try container.encodeIfPresent(defaultModelId, forKey: .defaultModelId)
        try container.encodeIfPresent(hiveMindGoal, forKey: .hiveMindGoal)
        try container.encode(participantUsernames, forKey: .participantUsernames)
        try container.encode(participants, forKey: .participants)
        try container.encodeIfPresent(lastMessage, forKey: .lastMessage)
        try container.encode(unreadCount, forKey: .unreadCount)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)

        var detailsContainer = encoder.container(keyedBy: AdditionalKeys.self)
        try detailsContainer.encode(participants, forKey: .participantDetails)
    }

    init(
        id: Int,
        title: String?,
        mode: String?,
        withAI: Bool?,
        defaultModelId: String?,
        hiveMindGoal: String? = nil,
        participants: [User],
        participantUsernames: [String],
        lastMessage: Message?,
        unreadCount: Int,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.mode = mode
        self.withAI = withAI
        self.defaultModelId = defaultModelId
        self.hiveMindGoal = hiveMindGoal
        self.participants = participants
        self.participantUsernames = participantUsernames
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Message

struct Message: Codable, Identifiable {
    let id: Int
    let conversationId: Int
    let senderId: Int?
    let authorType: String?
    let content: String
    let createdAt: Date
    let updatedAt: Date?
    let modelUsed: String?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case authorType = "author_type"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case modelUsed = "model_used"
    }

    private enum AdditionalKeys: String, CodingKey {
        case authorId = "author_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        conversationId = try container.decode(Int.self, forKey: .conversationId)
        let authorContainer = try? decoder.container(keyedBy: AdditionalKeys.self)
        let authorId = try authorContainer?.decodeIfPresent(Int.self, forKey: .authorId)
        let sender = try container.decodeIfPresent(Int.self, forKey: .senderId)
        senderId = sender ?? authorId
        authorType = try container.decodeIfPresent(String.self, forKey: .authorType)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        modelUsed = try container.decodeIfPresent(String.self, forKey: .modelUsed)
    }

    var isFromCurrentUser: Bool {
        guard let senderId else { return false }
        return senderId == KeychainManager.shared.getUserId()
    }

    var isFromAI: Bool {
        (authorType ?? "") == "ai" || modelUsed != nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encodeIfPresent(senderId, forKey: .senderId)
        try container.encodeIfPresent(authorType, forKey: .authorType)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(modelUsed, forKey: .modelUsed)
    }
    
    // Convenience initializer for testing/previews
    init(
        id: Int,
        conversationId: Int,
        senderId: Int? = nil,
        authorType: String? = nil,
        content: String,
        createdAt: Date,
        updatedAt: Date? = nil,
        modelUsed: String? = nil
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.authorType = authorType
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.modelUsed = modelUsed
    }
}

// MARK: - Create Models

struct ConversationCreate: Codable {
    let title: String
    let mode: String
    let withAI: Bool
    let defaultModelId: String?
    let participantUsernames: [String]

    enum CodingKeys: String, CodingKey {
        case title, mode
        case withAI = "with_ai"
        case defaultModelId = "default_model_id"
        case participantUsernames = "participant_usernames"
    }
}

struct MessageCreate: Codable {
    let content: String
    let model: String?
}

extension Conversation: Equatable {
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.updatedAt == rhs.updatedAt &&
        lhs.unreadCount == rhs.unreadCount &&
        lhs.defaultModelId == rhs.defaultModelId &&
        lhs.hiveMindGoal == rhs.hiveMindGoal &&
        lhs.lastMessage?.id == rhs.lastMessage?.id
    }
}

extension Conversation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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

// MARK: - Conversation helpers

extension Conversation {
    var isAIEnabled: Bool {
        withAI ?? false
    }
    
    var hasHiveMindGoal: Bool {
        hiveMindGoal != nil && !(hiveMindGoal?.isEmpty ?? true)
    }

    var participantDisplayNames: String {
        let others = participants.filter { $0.username != currentUsername }
        if others.isEmpty {
            return participantUsernames.filter { $0 != currentUsername }.joined(separator: ", ")
        }
        return others
            .map { $0.fullName ?? $0.username }
            .joined(separator: ", ")
    }

    func participantName(for userId: Int?) -> String? {
        guard let userId else { return nil }
        if let match = participants.first(where: { $0.id == userId }) {
            return match.fullName ?? match.username
        }
        return nil
    }

    func updating(
        lastMessage: Message? = nil,
        unreadCount: Int? = nil,
        participants: [User]? = nil,
        defaultModelId: String? = nil,
        hiveMindGoal: String? = nil,
        updatedAt: Date? = nil
    ) -> Conversation {
        Conversation(
            id: id,
            title: title,
            mode: mode,
            withAI: withAI,
            defaultModelId: defaultModelId ?? self.defaultModelId,
            hiveMindGoal: hiveMindGoal ?? self.hiveMindGoal,
            participants: participants ?? self.participants,
            participantUsernames: participantUsernames,
            lastMessage: lastMessage ?? self.lastMessage,
            unreadCount: unreadCount ?? self.unreadCount,
            createdAt: createdAt,
            updatedAt: updatedAt ?? self.updatedAt
        )
    }
}

// MARK: - Message helpers

extension Message {
    var authorId: Int? { senderId }

    func senderName(in participants: [User]) -> String {
        if isFromAI { return "AI" }

        if let authorId,
           let match = participants.first(where: { $0.id == authorId }) {
            return match.fullName ?? match.username
        }

        if isFromCurrentUser {
            return "You"
        }

        return "User"
    }
}
