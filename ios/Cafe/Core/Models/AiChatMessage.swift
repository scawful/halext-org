//
//  AiChatMessage.swift
//  Cafe
//
//  Created by Langley on 2025-11-18.
//

import Foundation

struct AiChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    var modelIdentifier: String?

    enum Role: String, Codable {
        case user
        case assistant
    }

    init(id: UUID = UUID(), role: Role, content: String, modelIdentifier: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.modelIdentifier = modelIdentifier
    }

    /// Convert to API-compatible ChatMessage
    func toChatMessage() -> ChatMessage {
        ChatMessage(role: role.rawValue, content: content)
    }

    /// Convert array of AiChatMessage to ChatMessage for API calls
    static func toHistory(_ messages: [AiChatMessage]) -> [ChatMessage] {
        messages.map { $0.toChatMessage() }
    }
}
