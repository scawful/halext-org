//
//  APIClient+Presence.swift
//  Cafe
//
//  Presence API endpoints for user online/offline status tracking
//
//  CROSS-PLATFORM DOCUMENTATION:
//  This extension provides presence management capabilities that should be
//  replicated on web and backend platforms for feature parity.
//

import Foundation

// MARK: - Presence Request/Response Models

/// Request model for updating user's presence status
struct PresenceStatusUpdate: Codable {
    let status: String // "online", "away", "offline"

    enum CodingKeys: String, CodingKey {
        case status
    }
}

/// Response model for presence status update
struct PresenceStatusResponse: Codable {
    let userId: Int
    let status: String
    let lastSeen: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case lastSeen = "last_seen"
    }
}

/// Response model for fetching multiple user presences
struct UserPresenceResponse: Codable {
    let userId: Int
    let status: String
    let lastSeen: Date
    let isTyping: Bool?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case lastSeen = "last_seen"
        case isTyping = "is_typing"
    }
}

/// Request model for typing indicator
struct TypingIndicatorRequest: Codable {
    let isTyping: Bool

    enum CodingKeys: String, CodingKey {
        case isTyping = "is_typing"
    }
}

// MARK: - APIClient Presence Extension

extension APIClient {

    // MARK: - Update Own Presence

    /// Updates the current user's presence status
    ///
    /// **Backend Endpoint:** `POST /api/presence/status`
    ///
    /// **Request Body:**
    /// ```json
    /// {
    ///     "status": "online" | "away" | "offline"
    /// }
    /// ```
    ///
    /// **Response:**
    /// ```json
    /// {
    ///     "user_id": 1,
    ///     "status": "online",
    ///     "last_seen": "2024-01-01T12:00:00Z"
    /// }
    /// ```
    ///
    /// **Error Handling:**
    /// - 401: Not authenticated
    /// - 422: Invalid status value
    /// - 500: Server error
    ///
    /// - Parameter status: The presence status to set (online, away, offline)
    /// - Returns: The updated presence status response
    /// - Throws: APIError if the request fails
    func updatePresenceStatus(_ status: PresenceStatus) async throws -> PresenceStatusResponse {
        let body = PresenceStatusUpdate(status: status.rawValue)
        var request = try authorizedRequest(path: "/presence/status", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    // MARK: - Fetch User Presences

    /// Fetches presence information for specified users
    ///
    /// **Backend Endpoint:** `GET /api/presence/users`
    ///
    /// **Query Parameters:**
    /// - `user_ids` (optional): Comma-separated list of user IDs. If not provided, returns presence for all connected users.
    ///
    /// **Response:**
    /// ```json
    /// [
    ///     {
    ///         "user_id": 1,
    ///         "status": "online",
    ///         "last_seen": "2024-01-01T12:00:00Z",
    ///         "is_typing": false
    ///     }
    /// ]
    /// ```
    ///
    /// - Parameter userIds: Optional array of user IDs to fetch presence for
    /// - Returns: Array of user presence responses
    /// - Throws: APIError if the request fails
    func getPresences(userIds: [Int]? = nil) async throws -> [UserPresenceResponse] {
        var path = "/presence/users"
        if let userIds = userIds, !userIds.isEmpty {
            let idsString = userIds.map { String($0) }.joined(separator: ",")
            path += "?user_ids=\(idsString)"
        }
        let request = try authorizedRequest(path: path, method: "GET")
        return try await performRequest(request)
    }

    /// Fetches presence for a single user
    ///
    /// **Backend Endpoint:** `GET /api/presence/users/{user_id}`
    ///
    /// **Response:**
    /// ```json
    /// {
    ///     "user_id": 1,
    ///     "status": "online",
    ///     "last_seen": "2024-01-01T12:00:00Z",
    ///     "is_typing": false
    /// }
    /// ```
    ///
    /// - Parameter userId: The ID of the user to fetch presence for
    /// - Returns: The user's presence information
    /// - Throws: APIError if the request fails
    func getPresence(for userId: Int) async throws -> UserPresenceResponse {
        let request = try authorizedRequest(path: "/presence/users/\(userId)", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - Typing Indicator

    /// Sends a typing indicator for a conversation
    ///
    /// **Backend Endpoint:** `POST /api/conversations/{conversation_id}/typing`
    ///
    /// **Request Body:**
    /// ```json
    /// {
    ///     "is_typing": true
    /// }
    /// ```
    ///
    /// **Note:** This should ideally be debounced client-side to avoid excessive requests.
    /// Recommended: Send typing=true on first keystroke, then stop after 3 seconds of inactivity.
    ///
    /// - Parameters:
    ///   - conversationId: The ID of the conversation
    ///   - isTyping: Whether the user is currently typing
    /// - Throws: APIError if the request fails
    func sendTypingIndicator(conversationId: Int, isTyping: Bool) async throws {
        let body = TypingIndicatorRequest(isTyping: isTyping)
        var request = try authorizedRequest(path: "/conversations/\(conversationId)/typing", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        let _: EmptyResponse = try await performRequest(request)
    }
}

// MARK: - WebSocket Presence Subscription

/// Manager for WebSocket-based real-time presence updates
///
/// **Backend WebSocket Endpoint:** `ws://[host]/api/presence/subscribe`
///
/// **Connection Protocol:**
/// 1. Client connects with authentication token in header or query param
/// 2. Server sends current presence states for all relevant users
/// 3. Server pushes presence updates as they occur
///
/// **Message Format (Server -> Client):**
/// ```json
/// {
///     "type": "presence_update",
///     "data": {
///         "user_id": 1,
///         "status": "online",
///         "last_seen": "2024-01-01T12:00:00Z"
///     }
/// }
/// ```
///
/// **Typing Indicator Message:**
/// ```json
/// {
///     "type": "typing_update",
///     "data": {
///         "user_id": 1,
///         "conversation_id": 123,
///         "is_typing": true
///     }
/// }
/// ```
///
/// **Reconnection Strategy:**
/// - Exponential backoff: 1s, 2s, 4s, 8s, 16s (max)
/// - Reset backoff on successful connection
/// - Stop reconnection attempts when app enters background
@MainActor
class PresenceWebSocketManager: NSObject {

    // MARK: - Singleton

    static let shared = PresenceWebSocketManager()

    // MARK: - Properties

    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let baseReconnectDelay: TimeInterval = 1.0

    /// Closure called when presence updates are received
    var onPresenceUpdate: ((Int, PresenceStatus, Date) -> Void)?

    /// Closure called when typing updates are received
    var onTypingUpdate: ((Int, Int, Bool) -> Void)?

    /// Closure called when connection state changes
    var onConnectionStateChanged: ((Bool) -> Void)?

    // MARK: - Connection Management

    /// Connects to the presence WebSocket endpoint
    ///
    /// - Note: Requires valid authentication token
    func connect() {
        guard !isConnected, webSocketTask == nil else {
            #if DEBUG
            print("[Presence WS] Already connected or connecting")
            #endif
            return
        }

        guard let token = KeychainManager.shared.getToken() else {
            #if DEBUG
            print("[Presence WS] No auth token available")
            #endif
            return
        }

        let environment = APIClient.shared.environment
        let wsScheme = environment == .development ? "ws" : "wss"
        let host = environment == .development ? "127.0.0.1:8000" : "org.halext.org"

        guard let url = URL(string: "\(wsScheme)://\(host)/api/presence/subscribe") else {
            #if DEBUG
            print("[Presence WS] Invalid WebSocket URL")
            #endif
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        receiveMessage()

        #if DEBUG
        print("[Presence WS] Connecting to \(url.absoluteString)")
        #endif
    }

    /// Disconnects from the WebSocket
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        reconnectAttempts = 0
        onConnectionStateChanged?(false)

        #if DEBUG
        print("[Presence WS] Disconnected")
        #endif
    }

    // MARK: - Message Handling

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            _Concurrency.Task { @MainActor in
                switch result {
                case .success(let message):
                    self?.handleMessage(message)
                    self?.receiveMessage() // Continue listening
                case .failure(let error):
                    #if DEBUG
                    print("[Presence WS] Receive error: \(error.localizedDescription)")
                    #endif
                    self?.handleDisconnection()
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseMessage(text)
            }
        @unknown default:
            break
        }
    }

    private func parseMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let message = try decoder.decode(WebSocketMessage.self, from: data)

            switch message.type {
            case "presence_update":
                if let presenceData = message.data as? PresenceUpdateData {
                    let status = PresenceStatus(rawValue: presenceData.status) ?? .offline
                    onPresenceUpdate?(presenceData.userId, status, presenceData.lastSeen)
                }
            case "typing_update":
                if let typingData = message.data as? TypingUpdateData {
                    onTypingUpdate?(typingData.userId, typingData.conversationId, typingData.isTyping)
                }
            default:
                #if DEBUG
                print("[Presence WS] Unknown message type: \(message.type)")
                #endif
            }
        } catch {
            #if DEBUG
            print("[Presence WS] Failed to parse message: \(error)")
            #endif
        }
    }

    private func handleDisconnection() {
        isConnected = false
        webSocketTask = nil
        onConnectionStateChanged?(false)

        // Attempt reconnection with exponential backoff
        guard reconnectAttempts < maxReconnectAttempts else {
            #if DEBUG
            print("[Presence WS] Max reconnection attempts reached")
            #endif
            return
        }

        let delay = baseReconnectDelay * pow(2.0, Double(reconnectAttempts))
        reconnectAttempts += 1

        #if DEBUG
        print("[Presence WS] Reconnecting in \(delay)s (attempt \(reconnectAttempts))")
        #endif

        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await MainActor.run {
                self.connect()
            }
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension PresenceWebSocketManager: URLSessionWebSocketDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        _Concurrency.Task { @MainActor in
            self.isConnected = true
            self.reconnectAttempts = 0
            self.onConnectionStateChanged?(true)

            #if DEBUG
            print("[Presence WS] Connected successfully")
            #endif
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        _Concurrency.Task { @MainActor in
            #if DEBUG
            let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason"
            print("[Presence WS] Closed with code: \(closeCode), reason: \(reasonString)")
            #endif

            self.handleDisconnection()
        }
    }
}

// MARK: - WebSocket Message Types

private struct WebSocketMessage: Decodable {
    let type: String
    let data: WebSocketMessageData?

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        // Decode data based on type
        switch type {
        case "presence_update":
            data = try container.decodeIfPresent(PresenceUpdateData.self, forKey: .data)
        case "typing_update":
            data = try container.decodeIfPresent(TypingUpdateData.self, forKey: .data)
        default:
            data = nil
        }
    }
}

private protocol WebSocketMessageData {}

private struct PresenceUpdateData: Decodable, WebSocketMessageData {
    let userId: Int
    let status: String
    let lastSeen: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case status
        case lastSeen = "last_seen"
    }
}

private struct TypingUpdateData: Decodable, WebSocketMessageData {
    let userId: Int
    let conversationId: Int
    let isTyping: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case conversationId = "conversation_id"
        case isTyping = "is_typing"
    }
}
