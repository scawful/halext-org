//
//  ConversationView.swift
//  Cafe
//
//  Chat conversation view
//

import SwiftUI

struct ConversationView: View {
    let conversation: Conversation

    @State private var messages: [Message] = []
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }

                        ForEach(messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar
            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                }
                .disabled(messageText.isEmpty || isSending)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMessages()
            await markAsRead()
        }
    }

    private func loadMessages() async {
        isLoading = true
        defer { isLoading = false }

        do {
            messages = try await APIClient.shared.getMessages(conversationId: conversation.id, limit: 100)
            messages.sort { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isSending = true
        messageText = "" // Clear immediately for better UX

        _Concurrency.Task {
            do {
                let newMessage = try await APIClient.shared.sendMessage(
                    conversationId: conversation.id,
                    content: content
                )
                messages.append(newMessage)
            } catch {
                errorMessage = error.localizedDescription
                messageText = content // Restore on error
            }
            isSending = false
        }
    }

    private func markAsRead() async {
        do {
            try await APIClient.shared.markConversationAsRead(conversationId: conversation.id)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
}

// MARK: - Message Bubble

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromCurrentUser ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)

                HStack(spacing: 4) {
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let modelUsed = message.modelUsed {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 2) {
                            Image(systemName: "cpu")
                                .font(.caption2)

                            Text(modelUsed)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConversationView(conversation: Conversation(
            id: 1,
            participants: [],
            lastMessage: nil,
            unreadCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
