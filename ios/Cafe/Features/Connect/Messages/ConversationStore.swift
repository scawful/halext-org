//
//  ConversationStore.swift
//  Cafe
//
//  Shared conversation state + networking for message threads.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ConversationStore: ObservableObject {
    @Published private(set) var conversation: Conversation
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: String?
    @Published var isWebSocketConnected = false
    @Published var typingUsers: Set<Int> = [] // User IDs who are typing

    private let api = APIClient.shared
    private let chatSettings = ChatSettingsManager.shared
    private var webSocketManager: WebSocketManager?
    private var typingDebounceTask: _Concurrency.Task<Void, Never>?

    init(conversation: Conversation) {
        self.conversation = conversation
        connectWebSocket()
    }
    
    deinit {
        typingDebounceTask?.cancel()
        webSocketManager = nil
    }

    func refresh() async {
        await fetchConversationDetails()
        await loadMessages()
        await markAsReadIfEnabled()
    }

    func fetchConversationDetails() async {
        do {
            let latest = try await api.getConversation(id: conversation.id)
            conversation = latest
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadMessages() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await api.getMessages(conversationId: conversation.id, limit: 200)
            mergeMessages(fetched, replaceExisting: true)
            updateConversationSummary()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func send(content: String, modelOverride: String? = nil) async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            let newMessages = try await api.sendMessage(
                conversationId: conversation.id,
                content: trimmed,
                model: modelOverride
            )
            mergeMessages(newMessages)
            updateConversationSummary()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markAsReadIfEnabled() async {
        guard chatSettings.enableReadReceipts else { return }

        do {
            try await api.markConversationAsRead(conversationId: conversation.id)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }

    private func mergeMessages(_ newMessages: [Message], replaceExisting: Bool = false) {
        var merged = replaceExisting ? [] : messages
        var seen = Set(merged.map { $0.id })

        for message in newMessages {
            if let index = merged.firstIndex(where: { $0.id == message.id }) {
                merged[index] = message
            } else if !seen.contains(message.id) {
                merged.append(message)
                seen.insert(message.id)
            }
        }

        merged.sort { $0.createdAt < $1.createdAt }
        messages = merged
    }

    private func updateConversationSummary() {
        guard let latest = messages.last else { return }
        conversation = conversation.updating(
            lastMessage: latest,
            unreadCount: 0,
            updatedAt: latest.createdAt
        )
    }
    
    // MARK: - WebSocket Integration
    
    private func connectWebSocket() {
        let environment = APIClient.shared.environment
        let wsScheme = environment == .development ? "ws" : "wss"
        let host = environment == .development ? "127.0.0.1:8000" : "org.halext.org"
        
        guard let url = URL(string: "\(wsScheme)://\(host)/ws/\(conversation.id)") else {
            #if DEBUG
            print("[Conversation] Invalid WebSocket URL")
            #endif
            return
        }
        
        let token = KeychainManager.shared.getToken()
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
        
        _Concurrency.Task { @MainActor in
            await manager.connect(url: url, authToken: token)
            self.webSocketManager = manager
        }
    }
    
    private func disconnectWebSocket() {
        typingDebounceTask?.cancel()
        _Concurrency.Task { @MainActor in
            await WebSocketManager.shared.disconnect()
            isWebSocketConnected = false
        }
    }
    
    private func handleWebSocketMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        do {
            // Parse WebSocket message from backend
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String {
                
                switch type {
                case "message":
                    // New message received
                    if let messageData = json["data"] as? [String: Any],
                       let messageJson = try? JSONSerialization.data(withJSONObject: messageData),
                       let message = try? JSONDecoder().decode(Message.self, from: messageJson) {
                        mergeMessages([message])
                        updateConversationSummary()
                    }
                case "typing":
                    // Typing indicator
                    if let data = json["data"] as? [String: Any],
                       let userId = data["user_id"] as? Int,
                       let isTyping = data["is_typing"] as? Bool {
                        if isTyping {
                            typingUsers.insert(userId)
                        } else {
                            typingUsers.remove(userId)
                        }
                    }
                case "user_joined", "user_left":
                    // User joined/left - refresh conversation
                    _Concurrency.Task {
                        await fetchConversationDetails()
                    }
                default:
                    #if DEBUG
                    print("[Conversation] Unknown WebSocket message type: \(type)")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            print("[Conversation] Failed to parse WebSocket message: \(error)")
            #endif
        }
    }
    
    func sendTypingIndicator(_ isTyping: Bool) {
        // Debounce typing indicators
        typingDebounceTask?.cancel()
        
        if isTyping {
            // Send typing=true immediately
            sendTypingToServer(isTyping: true)
            
            // Auto-send typing=false after 3 seconds
            typingDebounceTask = _Concurrency.Task {
                try? await _Concurrency.Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    self.sendTypingToServer(isTyping: false)
                }
            }
        } else {
            // Send typing=false immediately
            sendTypingToServer(isTyping: false)
        }
    }
    
    private func sendTypingToServer(isTyping: Bool) {
        // Send via HTTP endpoint (WebSocket message sending can be added later)
        _Concurrency.Task {
            do {
                try await api.sendTypingIndicator(conversationId: conversation.id, isTyping: isTyping)
            } catch {
                #if DEBUG
                print("[Conversation] Failed to send typing indicator: \(error)")
                #endif
            }
        }
    }
}
