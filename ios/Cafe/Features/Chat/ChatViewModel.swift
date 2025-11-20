//
//  ChatViewModel.swift
//  Cafe
//
//  Created by Langley on 2025-11-18.
//

import Foundation
import SwiftUI

@Observable
class ChatViewModel {
    var messages: [AiChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false

    private var api = APIClient.shared
    private var settingsManager = SettingsManager.shared

    @MainActor
    func sendMessage() async {
        guard !inputText.isEmpty else { return }

        let userMessage = AiChatMessage(role: .user, content: inputText)
        messages.append(userMessage)

        // Convert to API-compatible format
        let history = AiChatMessage.toHistory(messages)
        inputText = ""
        isLoading = true

        // Get selected model from settings
        let modelId = settingsManager.selectedAiModelId

        do {
            var assistantResponse = ""
            let stream = try await api.streamChatMessage(prompt: userMessage.content, history: history, model: modelId)

            // Add a placeholder for the streaming message
            let assistantMessageId = UUID()
            let placeholder = AiChatMessage(id: assistantMessageId, role: .assistant, content: "")
            messages.append(placeholder)

            for try await chunk in stream {
                assistantResponse += chunk
                if let index = messages.firstIndex(where: { $0.id == assistantMessageId }) {
                    messages[index] = AiChatMessage(id: assistantMessageId, role: .assistant, content: assistantResponse)
                }
            }
        } catch {
            let errorMessage = AiChatMessage(role: .assistant, content: "Sorry, I encountered an error: \(error.localizedDescription)")
            messages.append(errorMessage)
        }

        isLoading = false
    }

    @MainActor
    func clearChat() {
        messages.removeAll()
    }

    @MainActor
    func regenerateLastResponse() async {
        guard let lastUserMessageIndex = messages.lastIndex(where: { $0.role == .user }) else { return }

        // Remove messages after the last user message
        messages.removeSubrange((lastUserMessageIndex + 1)...)

        // Resend the last user message
        let lastUserMessage = messages[lastUserMessageIndex]
        messages.removeLast() // Remove it temporarily
        inputText = lastUserMessage.content
        await sendMessage()
    }
}
