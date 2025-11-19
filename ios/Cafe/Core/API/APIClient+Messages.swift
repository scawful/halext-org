//
//  APIClient+Messages.swift
//  Cafe
//
//  Messaging API endpoints
//

import Foundation

extension APIClient {
    // MARK: - Conversations

    func getConversations() async throws -> [Conversation] {
        let request = try authorizedRequest(path: "/conversations/", method: "GET")
        return try await performRequest(request)
    }

    func getConversation(id: Int) async throws -> Conversation {
        let request = try authorizedRequest(path: "/conversations/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func createConversation(participantIds: [Int]) async throws -> Conversation {
        var request = try authorizedRequest(path: "/conversations/", method: "POST")
        let body = ConversationCreate(participantIds: participantIds)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    func deleteConversation(id: Int) async throws {
        let request = try authorizedRequest(path: "/conversations/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Messages

    func getMessages(conversationId: Int, limit: Int = 50, offset: Int = 0) async throws -> [Message] {
        let path = "/conversations/\(conversationId)/messages?limit=\(limit)&offset=\(offset)"
        let request = try authorizedRequest(path: path, method: "GET")
        return try await performRequest(request)
    }

    func sendMessage(conversationId: Int, content: String, messageType: MessageType = .text) async throws -> Message {
        var request = try authorizedRequest(path: "/conversations/\(conversationId)/messages", method: "POST")
        let body = MessageCreate(
            conversationId: conversationId,
            content: content,
            messageType: messageType.rawValue
        )
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    func markMessageAsRead(id: Int) async throws {
        let request = try authorizedRequest(path: "/messages/\(id)/read", method: "POST")
        let _: EmptyResponse = try await performRequest(request)
    }

    func markConversationAsRead(conversationId: Int) async throws {
        let request = try authorizedRequest(path: "/messages/conversations/\(conversationId)/read", method: "POST")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Typing Indicators

    func sendTypingIndicator(conversationId: Int, isTyping: Bool) async throws {
        let request = try authorizedRequest(path: "/messages/conversations/\(conversationId)/typing", method: "POST")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Users (for starting conversations)

    func searchUsers(query: String) async throws -> [User] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let request = try authorizedRequest(path: "/users/search?q=\(encodedQuery)", method: "GET")
        return try await performRequest(request)
    }
}
