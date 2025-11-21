//
//  ConversationView.swift
//  Cafe
//
//  Chat conversation view
//

import SwiftUI

struct ConversationView: View {
    @StateObject private var store: ConversationStore
    @State private var messageText = ""
    private let onConversationUpdated: (Conversation) -> Void

    init(conversation: Conversation, onConversationUpdated: @escaping (Conversation) -> Void = { _ in }) {
        _store = StateObject(wrappedValue: ConversationStore(conversation: conversation))
        self.onConversationUpdated = onConversationUpdated
    }

    var body: some View {
        VStack(spacing: 0) {
            ConversationInfoHeader(conversation: store.conversation)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if store.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }

                        ForEach(store.messages) { message in
                            ConversationMessageBubble(
                                message: message,
                                senderName: message.senderName(in: store.conversation.participants),
                                isGroup: false,
                                defaultModelId: store.conversation.defaultModelId
                            )
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: store.messages.count) { _, _ in
                    if let lastMessage = store.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button(action: sendMessage) {
                    if store.isSending {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isSending)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(store.conversation.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if store.conversation.hasHiveMindGoal || store.conversation.isAIEnabled {
                        NavigationLink {
                            HiveMindView(conversationId: store.conversation.id)
                        } label: {
                            Label("Hive Mind", systemImage: "brain")
                        }
                    }
                    
                    Button(action: {}) {
                        Label("Info", systemImage: "info.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await store.refresh()
        }
        .onChange(of: store.conversation) { _, updated in
            onConversationUpdated(updated)
        }
        .alert("Error", isPresented: Binding(get: { store.error != nil }, set: { _ in store.error = nil })) {
            Button("OK", role: .cancel) { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
    }

    private func sendMessage() {
        let pending = messageText
        let trimmed = pending.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messageText = ""

        _Concurrency.Task {
            await store.send(content: trimmed)
            if store.error != nil {
                messageText = pending
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConversationView(conversation: Conversation(
            id: 1,
            title: "Preview",
            mode: "solo",
            withAI: false,
            defaultModelId: nil,
            hiveMindGoal: nil,
            participants: [],
            participantUsernames: [],
            lastMessage: nil,
            unreadCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
