//
//  PresenceManager.swift
//  Cafe
//
//  Manages user online/offline status and presence tracking
//
//  CROSS-PLATFORM DOCUMENTATION:
//  This manager handles real-time presence tracking. Backend and web platforms
//  should implement equivalent functionality for feature parity.
//

import SwiftUI
import Combine

// Typealias to avoid conflict with Task model from Models.swift
private typealias AsyncTask = _Concurrency.Task

// MARK: - Presence Status

enum PresenceStatus: String, Codable {
    case online
    case away
    case offline

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .online: return .green
        case .away: return .orange
        case .offline: return .gray
        }
    }

    var icon: String {
        switch self {
        case .online: return "circle.fill"
        case .away: return "moon.fill"
        case .offline: return "circle"
        }
    }
}

// MARK: - User Presence Model

struct UserPresence: Codable, Identifiable {
    let id: Int // user ID
    var status: PresenceStatus
    var lastSeen: Date
    var isTyping: Bool

    var isOnline: Bool {
        status == .online
    }

    var lastSeenText: String {
        if isOnline {
            return "Active now"
        }

        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: lastSeen, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Presence Manager

@MainActor
@Observable
class PresenceManager {
    static let shared = PresenceManager()

    private var userPresences: [Int: UserPresence] = [:]
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 30 // Update every 30 seconds

    /// Tracks whether the user is authenticated and presence updates should be sent
    private var isAuthenticated: Bool {
        KeychainManager.shared.getToken() != nil
    }

    /// Tracks pending presence update to handle offline scenarios
    private var pendingPresenceUpdate: PresenceStatus?

    /// Last successful presence update timestamp for rate limiting
    private var lastPresenceUpdateTime: Date?

    /// Minimum interval between presence updates (rate limiting)
    private let minimumUpdateInterval: TimeInterval = 5.0

    var currentStatus: PresenceStatus = .online {
        didSet {
            if currentStatus != oldValue {
                triggerPresenceUpdate()
            }
        }
    }

    /// Triggers an async presence update without using Task directly in didSet
    /// This avoids the @Observable macro conflict with _Concurrency.Task
    private func triggerPresenceUpdate() {
        AsyncTask { @MainActor in
            await updateOwnPresence()
        }
    }

    /// Indicates whether WebSocket is connected for real-time updates
    var isWebSocketConnected: Bool = false

    private init() {
        setupWebSocketCallbacks()
        setupAuthenticationObserver()
        startPresenceUpdates()
        observeAppLifecycle()
    }

    // MARK: - Setup

    private func setupWebSocketCallbacks() {
        // Handle real-time presence updates from WebSocket
        PresenceWebSocketManager.shared.onPresenceUpdate = { [weak self] userId, status, lastSeen in
            AsyncTask { @MainActor in
                self?.handlePresenceUpdate(userId: userId, status: status, lastSeen: lastSeen)
            }
        }

        // Handle typing indicator updates from WebSocket
        PresenceWebSocketManager.shared.onTypingUpdate = { [weak self] userId, conversationId, isTyping in
            AsyncTask { @MainActor in
                self?.handleTypingUpdate(userId: userId, conversationId: conversationId, isTyping: isTyping)
            }
        }

        // Track connection state
        PresenceWebSocketManager.shared.onConnectionStateChanged = { [weak self] connected in
            AsyncTask { @MainActor in
                self?.isWebSocketConnected = connected
                #if DEBUG
                print("[Presence] WebSocket connection state: \(connected ? "connected" : "disconnected")")
                #endif
            }
        }
    }

    private func setupAuthenticationObserver() {
        // Listen for token expiration to stop presence updates
        NotificationCenter.default.addObserver(
            forName: .tokenExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleLogout()
        }
    }

    // MARK: - Presence Updates

    func startPresenceUpdates() {
        guard isAuthenticated else {
            #if DEBUG
            print("[Presence] Not starting updates - user not authenticated")
            #endif
            return
        }

        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            AsyncTask { @MainActor in
                await self?.updateOwnPresence()
                await self?.fetchPresences()
            }
        }

        // Initial update and WebSocket connection
        AsyncTask { @MainActor in
            await updateOwnPresence()
            await fetchPresences()
            connectWebSocket()
        }
    }

    func stopPresenceUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        disconnectWebSocket()
    }

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.currentStatus = .online
            self?.startPresenceUpdates()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.currentStatus = .away
            AsyncTask { @MainActor in
                await self?.updateOwnPresence()
            }
            self?.stopPresenceUpdates()
        }
    }

    // MARK: - WebSocket Management

    private func connectWebSocket() {
        guard isAuthenticated else { return }
        
        // Get user ID from Keychain or AppState
        guard let userId = KeychainManager.shared.getUserId() else {
            #if DEBUG
            print("[Presence] Cannot connect WebSocket - no user ID")
            #endif
            return
        }
        
        let environment = APIClient.shared.environment
        let wsScheme = environment == .development ? "ws" : "wss"
        let host = environment == .development ? "127.0.0.1:8000" : "org.halext.org"
        
        guard let url = URL(string: "\(wsScheme)://\(host)/ws/presence/\(userId)") else {
            #if DEBUG
            print("[Presence] Invalid WebSocket URL")
            #endif
            return
        }
        
        let token = KeychainManager.shared.getToken()
        
        _Concurrency.Task { @MainActor in
            let manager = WebSocketManager.shared
            manager.onMessage = { [weak self] message in
                self?.handleWebSocketMessage(message)
            }
            manager.onConnect = { [weak self] in
                self?.isWebSocketConnected = true
            }
            manager.onDisconnect = { [weak self] _ in
                self?.isWebSocketConnected = false
            }
            
            await manager.connect(url: url, authToken: token)
        }
    }

    private func disconnectWebSocket() {
        _Concurrency.Task { @MainActor in
            await WebSocketManager.shared.disconnect()
            isWebSocketConnected = false
        }
    }
    
    private func handleWebSocketMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Parse WebSocket message format from backend
            struct WebSocketMessage: Decodable {
                let type: String
                let data: PresenceUpdateData?
            }
            
            struct PresenceUpdateData: Decodable {
                let userId: Int?
                let status: String?
                let lastSeen: Date?
                let conversationId: Int?
                let isTyping: Bool?
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case status
                    case lastSeen = "last_seen"
                    case conversationId = "conversation_id"
                    case isTyping = "is_typing"
                }
            }
            
            let wsMessage = try decoder.decode(WebSocketMessage.self, from: data)
            
            switch wsMessage.type {
            case "presence_update":
                if let data = wsMessage.data,
                   let userId = data.userId,
                   let statusString = data.status,
                   let status = PresenceStatus(rawValue: statusString),
                   let lastSeen = data.lastSeen {
                    handlePresenceUpdate(userId: userId, status: status, lastSeen: lastSeen)
                }
            case "typing_indicator":
                if let data = wsMessage.data,
                   let userId = data.userId,
                   let conversationId = data.conversationId,
                   let isTyping = data.isTyping {
                    handleTypingUpdate(userId: userId, conversationId: conversationId, isTyping: isTyping)
                }
            case "initial_presences":
                // Parse array of presences
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataArray = json["data"] as? [[String: Any]] {
                    for item in dataArray {
                        if let userId = item["user_id"] as? Int,
                           let statusString = item["status"] as? String,
                           let status = PresenceStatus(rawValue: statusString),
                           let lastSeenString = item["last_seen"] as? String,
                           let lastSeen = ISO8601DateFormatter().date(from: lastSeenString) {
                            handlePresenceUpdate(userId: userId, status: status, lastSeen: lastSeen)
                        }
                    }
                }
            default:
                #if DEBUG
                print("[Presence] Unknown WebSocket message type: \(wsMessage.type)")
                #endif
            }
        } catch {
            #if DEBUG
            print("[Presence] Failed to parse WebSocket message: \(error)")
            #endif
        }
    }

    // MARK: - API Integration

    /// Update own presence status via backend API
    ///
    /// **Endpoint:** `POST /api/presence/status`
    ///
    /// **Offline Handling:**
    /// - Stores pending update if network unavailable
    /// - Retries on next successful network operation
    ///
    /// **Rate Limiting:**
    /// - Minimum 5 seconds between updates to prevent server overload
    private func updateOwnPresence() async {
        guard isAuthenticated else {
            #if DEBUG
            print("[Presence] Skipping update - not authenticated")
            #endif
            return
        }

        // Rate limiting check
        if let lastUpdate = lastPresenceUpdateTime,
           Date().timeIntervalSince(lastUpdate) < minimumUpdateInterval {
            #if DEBUG
            print("[Presence] Skipping update - rate limited")
            #endif
            return
        }

        do {
            let response = try await APIClient.shared.updatePresenceStatus(currentStatus)
            lastPresenceUpdateTime = Date()
            pendingPresenceUpdate = nil

            #if DEBUG
            print("[Presence] Updated status to: \(response.status)")
            #endif
        } catch let error as APIError {
            handlePresenceError(error, for: "update")
        } catch let error as URLError {
            // Network error - store for retry
            pendingPresenceUpdate = currentStatus
            #if DEBUG
            print("[Presence] Network error during update: \(error.localizedDescription)")
            #endif
        } catch {
            #if DEBUG
            print("[Presence] Unexpected error during update: \(error.localizedDescription)")
            #endif
        }
    }

    /// Fetch presence for all connected users via backend API
    ///
    /// **Endpoint:** `GET /api/presence/users`
    ///
    /// **Caching:**
    /// - Results are cached in memory
    /// - WebSocket provides real-time updates between fetches
    private func fetchPresences() async {
        guard isAuthenticated else {
            #if DEBUG
            print("[Presence] Skipping fetch - not authenticated")
            #endif
            return
        }

        do {
            let presences = try await APIClient.shared.getPresences()
            for presence in presences {
                let status = PresenceStatus(rawValue: presence.status) ?? .offline
                userPresences[presence.userId] = UserPresence(
                    id: presence.userId,
                    status: status,
                    lastSeen: presence.lastSeen,
                    isTyping: presence.isTyping ?? false
                )
            }

            // Retry pending update if we have network again
            if let pending = pendingPresenceUpdate {
                pendingPresenceUpdate = nil
                currentStatus = pending
            }

            #if DEBUG
            print("[Presence] Fetched \(presences.count) user presences")
            #endif
        } catch let error as APIError {
            handlePresenceError(error, for: "fetch")
        } catch {
            #if DEBUG
            print("[Presence] Error fetching presences: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Real-time Update Handlers

    private func handlePresenceUpdate(userId: Int, status: PresenceStatus, lastSeen: Date) {
        if var presence = userPresences[userId] {
            presence.status = status
            presence.lastSeen = lastSeen
            userPresences[userId] = presence
        } else {
            userPresences[userId] = UserPresence(
                id: userId,
                status: status,
                lastSeen: lastSeen,
                isTyping: false
            )
        }

        #if DEBUG
        print("[Presence] Real-time update - User \(userId): \(status.rawValue)")
        #endif
    }

    private func handleTypingUpdate(userId: Int, conversationId: Int, isTyping: Bool) {
        if var presence = userPresences[userId] {
            presence.isTyping = isTyping
            userPresences[userId] = presence
        }

        #if DEBUG
        print("[Presence] Typing update - User \(userId) in conversation \(conversationId): \(isTyping)")
        #endif
    }

    // MARK: - Error Handling

    private func handlePresenceError(_ error: APIError, for operation: String) {
        switch error {
        case .unauthorized, .notAuthenticated:
            // Token expired - stop updates
            #if DEBUG
            print("[Presence] Auth error during \(operation) - stopping updates")
            #endif
            stopPresenceUpdates()

        case .httpError(let code) where (500...599).contains(code):
            // Server error - will retry on next interval
            #if DEBUG
            print("[Presence] Server error (\(code)) during \(operation) - will retry")
            #endif

        default:
            #if DEBUG
            print("[Presence] API error during \(operation): \(error.localizedDescription ?? "Unknown error")")
            #endif
        }
    }

    // MARK: - Public API

    func getPresence(for userId: Int) -> UserPresence? {
        userPresences[userId]
    }

    func isUserOnline(_ userId: Int) -> Bool {
        userPresences[userId]?.isOnline ?? false
    }

    /// Sends typing indicator for a conversation
    ///
    /// **Endpoint:** `POST /api/conversations/{conversation_id}/typing`
    ///
    /// **Debouncing:**
    /// - Call with `isTyping: true` on first keystroke
    /// - Call with `isTyping: false` after 3 seconds of inactivity
    /// - The backend should auto-expire typing status after timeout
    func setTyping(_ isTyping: Bool, for conversationId: Int) {
        guard isAuthenticated else { return }

        let _ = _Concurrency.Task { @MainActor in
            do {
                try await APIClient.shared.sendTypingIndicator(
                    conversationId: conversationId,
                    isTyping: isTyping
                )
                #if DEBUG
                print("[Presence] Sent typing indicator: \(isTyping) for conversation: \(conversationId)")
                #endif
            } catch {
                // Typing indicators are non-critical - just log errors
                #if DEBUG
                print("[Presence] Failed to send typing indicator: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Manually refresh presence for a specific user
    ///
    /// **Endpoint:** `GET /api/presence/users/{user_id}`
    func refreshPresence(for userId: Int) async {
        guard isAuthenticated else { return }

        do {
            let response = try await APIClient.shared.getPresence(for: userId)
            let status = PresenceStatus(rawValue: response.status) ?? .offline
            userPresences[userId] = UserPresence(
                id: response.userId,
                status: status,
                lastSeen: response.lastSeen,
                isTyping: response.isTyping ?? false
            )
            #if DEBUG
            print("[Presence] Refreshed presence for user \(userId): \(status.rawValue)")
            #endif
        } catch {
            #if DEBUG
            print("[Presence] Failed to refresh presence for user \(userId): \(error.localizedDescription)")
            #endif
        }
    }

    /// Called when user logs out to clean up presence state
    func handleLogout() {
        stopPresenceUpdates()
        userPresences.removeAll()
        pendingPresenceUpdate = nil
        lastPresenceUpdateTime = nil

        #if DEBUG
        print("[Presence] Cleaned up after logout")
        #endif
    }

    /// Called when user logs in to start presence tracking
    func handleLogin() {
        currentStatus = .online
        startPresenceUpdates()

        #if DEBUG
        print("[Presence] Started tracking after login")
        #endif
    }
}

// MARK: - Presence Indicator View

struct PresenceIndicator: View {
    let status: PresenceStatus
    let size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            )
    }
}

// MARK: - User Avatar with Presence

struct UserAvatarWithPresence: View {
    let username: String
    let presence: UserPresence?
    let size: CGFloat = 40

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar circle with initials
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: size, height: size)
                .overlay(
                    Text(username.prefix(1).uppercased())
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(.blue)
                )

            // Presence indicator
            if let presence = presence {
                PresenceIndicator(status: presence.status)
                    .offset(x: 2, y: 2)
            }
        }
    }
}

// MARK: - Last Seen Text View

struct LastSeenView: View {
    let presence: UserPresence?

    var body: some View {
        if let presence = presence {
            HStack(spacing: 4) {
                Circle()
                    .fill(presence.status.color)
                    .frame(width: 8, height: 8)

                Text(presence.lastSeenText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Backend API Requirements

/*
 BACKEND ENDPOINTS NEEDED FOR FULL FUNCTIONALITY:

 1. Update Own Presence
    POST /users/me/presence
    Body: {
        "status": "online" | "away" | "offline"
    }
    Response: {
        "user_id": 1,
        "status": "online",
        "last_seen": "2024-01-01T12:00:00Z"
    }

 2. Get User Presences
    GET /users/presence
    Query params: user_ids (optional, comma-separated)
    Response: [
        {
            "user_id": 1,
            "status": "online",
            "last_seen": "2024-01-01T12:00:00Z"
        }
    ]

 3. Get Single User Presence
    GET /users/{user_id}/presence
    Response: {
        "user_id": 1,
        "status": "online",
        "last_seen": "2024-01-01T12:00:00Z"
    }

 4. Typing Indicator (already exists in GroupConversationView)
    POST /conversations/{conversation_id}/typing
    Body: {
        "is_typing": true
    }

 Database schema addition needed:
 - Add `presence_status` ENUM column to users table
 - Add `last_seen` TIMESTAMP column to users table
 - Consider adding a separate `user_presence` table for better performance
 */
