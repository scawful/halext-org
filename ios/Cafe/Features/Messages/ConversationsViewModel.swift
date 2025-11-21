//
//  ConversationsViewModel.swift
//  Cafe
//
//  Centralizes conversation list loading + mutations.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var error: String?

    private let api = APIClient.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await api.getConversations()
            conversations = sort(conversations: fetched)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.compactMap { conversations[$0].id }
        conversations.remove(atOffsets: offsets)

        // Fire-and-forget delete so the UI stays responsive.
        _Concurrency.Task {
            for id in ids {
                try? await api.deleteConversation(id: id)
            }
        }
    }

    func insertOrUpdate(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        conversations = sort(conversations: conversations)
    }

    private func sort(conversations: [Conversation]) -> [Conversation] {
        conversations.sorted { (lhs, rhs) in
            let lhsDate = lhs.updatedAt ?? lhs.lastMessage?.createdAt ?? .distantPast
            let rhsDate = rhs.updatedAt ?? rhs.lastMessage?.createdAt ?? .distantPast
            return lhsDate > rhsDate
        }
    }
}
