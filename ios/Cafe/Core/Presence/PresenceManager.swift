//
//  PresenceManager.swift
//  Cafe
//
//  Manages user online/offline status and presence tracking
//

import SwiftUI
import Combine

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

    var currentStatus: PresenceStatus = .online {
        didSet {
            if currentStatus != oldValue {
                _Concurrency.Task {
                    await updateOwnPresence()
                }
            }
        }
    }

    private init() {
        startPresenceUpdates()
        observeAppLifecycle()
    }

    // MARK: - Presence Updates

    func startPresenceUpdates() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                await self?.updateOwnPresence()
                await self?.fetchPresences()
            }
        }

        // Initial update
        _Concurrency.Task {
            await updateOwnPresence()
            await fetchPresences()
        }
    }

    func stopPresenceUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
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
            _Concurrency.Task {
                await self?.updateOwnPresence()
            }
            self?.stopPresenceUpdates()
        }
    }

    // MARK: - API Integration

    /// Update own presence status
    /// Backend endpoint needed: POST /users/me/presence
    /// Body: { "status": "online|away|offline" }
    private func updateOwnPresence() async {
        // TODO: Implement when backend endpoint is ready
        // try await APIClient.shared.updatePresence(status: currentStatus)
        print("🟢 Would update presence to: \(currentStatus.rawValue)")
    }

    /// Fetch presence for all users or specific users
    /// Backend endpoint needed: GET /users/presence?user_ids=1,2,3
    /// Response: [{ "user_id": 1, "status": "online", "last_seen": "2024-01-01T12:00:00Z" }]
    private func fetchPresences() async {
        // TODO: Implement when backend endpoint is ready
        // let presences = try await APIClient.shared.getPresences()
        // for presence in presences {
        //     userPresences[presence.id] = presence
        // }
        print("📡 Would fetch user presences")
    }

    // MARK: - Public API

    func getPresence(for userId: Int) -> UserPresence? {
        userPresences[userId]
    }

    func isUserOnline(_ userId: Int) -> Bool {
        userPresences[userId]?.isOnline ?? false
    }

    func setTyping(_ isTyping: Bool, for conversationId: Int) {
        // Backend endpoint needed: POST /conversations/{id}/typing
        // Body: { "is_typing": true }
        _Concurrency.Task {
            // try await APIClient.shared.sendTypingIndicator(conversationId: conversationId, isTyping: isTyping)
            print("⌨️  Would send typing indicator: \(isTyping) for conversation: \(conversationId)")
        }
    }

    /// Manually refresh presence for specific user
    func refreshPresence(for userId: Int) async {
        // Backend endpoint needed: GET /users/{userId}/presence
        // try await fetchPresence(userId: userId)

        // Mock data for now - replace when backend is ready
        userPresences[userId] = UserPresence(
            id: userId,
            status: .online,
            lastSeen: Date(),
            isTyping: false
        )
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
