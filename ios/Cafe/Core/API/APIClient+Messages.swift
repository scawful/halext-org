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

    func createConversation(
        title: String,
        participantUsernames: [String],
        withAI: Bool = true,
        defaultModelId: String? = nil,
        mode: String = "solo"
    ) async throws -> Conversation {
        var request = try authorizedRequest(path: "/conversations/", method: "POST")
        let body = ConversationCreate(
            title: title,
            mode: mode,
            withAI: withAI,
            defaultModelId: defaultModelId,
            participantUsernames: participantUsernames
        )
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

    func sendMessage(conversationId: Int, content: String, model: String? = nil) async throws -> [Message] {
        var request = try authorizedRequest(path: "/conversations/\(conversationId)/messages", method: "POST")
        let body = MessageCreate(content: content, model: model)
        request.httpBody = try JSONEncoder().encode(body)

        // Backend returns both the user message and optional AI reply.
        let (data, _) = try await executeRequest(request)

        // Try to decode an array first (ideal case: [userMessage, aiMessage]).
        if let messageList = try? decodeResponse([Message].self, from: data) {
            return messageList
        }

        // Fallback for single-message responses
        let singleMessage: Message = try decodeResponse(Message.self, from: data)
        return [singleMessage]
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
    
    // MARK: - Hive Mind
    
    func setHiveMindGoal(conversationId: Int, goal: String) async throws -> Conversation {
        struct HiveMindGoalRequest: Codable {
            let goal: String
        }
        
        var request = try authorizedRequest(path: "/conversations/\(conversationId)/hive-mind/goal", method: "POST")
        let body = HiveMindGoalRequest(goal: goal)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }
    
    func getHiveMindSummary(conversationId: Int) async throws -> String {
        let request = try authorizedRequest(path: "/conversations/\(conversationId)/hive-mind/summary", method: "GET")
        // Backend returns a plain string, not JSON
        let (data, _) = try await executeRequest(request)
        guard let summary = String(data: data, encoding: .utf8) else {
            throw APIError.decodingError
        }
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getHiveMindNextSteps(conversationId: Int) async throws -> [String] {
        let request = try authorizedRequest(path: "/conversations/\(conversationId)/hive-mind/next-steps", method: "GET")
        return try await performRequest(request)
    }
}
