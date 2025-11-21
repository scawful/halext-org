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

    private let api = APIClient.shared
    private let chatSettings = ChatSettingsManager.shared

    init(conversation: Conversation) {
        self.conversation = conversation
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
}
