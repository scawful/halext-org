//
//  GroupConversationView.swift
//  Cafe
//
//  Enhanced conversation view with group chat and AI agents
//

import SwiftUI

struct GroupConversationView: View {
    let conversation: Conversation

    @State private var messages: [Message] = []
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showingParticipants = false
    @State private var showingAddParticipant = false

    @State private var chatSettings = ChatSettingsManager.shared

    var isGroupChat: Bool {
        conversation.participants.count > 2
    }

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
                            EnhancedMessageBubbleView(
                                message: message,
                                showSender: isGroupChat
                            )
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
                // Add participants button
                Button(action: { showingAddParticipant = true }) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundColor(.blue)
                }

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
        .navigationTitle(conversationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingParticipants = true }) {
                    ParticipantAvatarsView(participants: Array(conversation.participants.prefix(3)))
                }
            }
        }
        .sheet(isPresented: $showingParticipants) {
            ParticipantsListView(conversation: conversation)
        }
        .sheet(isPresented: $showingAddParticipant) {
            AddParticipantView(conversation: conversation)
        }
        .task {
            await loadMessages()
            await markAsRead()
        }
    }

    private var conversationTitle: String {
        if isGroupChat {
            let names = conversation.participants.prefix(3).compactMap { user in
                user.fullName ?? user.username
            }
            if conversation.participants.count > 3 {
                return names.joined(separator: ", ") + " +\(conversation.participants.count - 3)"
            }
            return names.joined(separator: ", ")
        }
        return conversation.displayName
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
        let originalText = messageText
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
                messageText = originalText // Restore on error
            }
            isSending = false
        }
    }

    private func markAsRead() async {
        guard chatSettings.enableReadReceipts else { return }

        do {
            try await APIClient.shared.markConversationAsRead(conversationId: conversation.id)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
}

// MARK: - Enhanced Message Bubble

struct EnhancedMessageBubbleView: View {
    let message: Message
    let showSender: Bool

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if showSender && !message.isFromCurrentUser {
                    Text(senderName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isFromCurrentUser ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }

    private var senderName: String {
        // In production, would look up sender from participants
        "User"
    }
}

// MARK: - Participant Avatars

struct ParticipantAvatarsView: View {
    let participants: [User]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(participants) { user in
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(user.username.prefix(1).uppercased())
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animationAmount = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == Double(index) ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear {
            animationAmount = 2.0
        }
    }
}

// MARK: - Participants List

struct ParticipantsListView: View {
    let conversation: Conversation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Members (\(conversation.participants.count))") {
                    ForEach(conversation.participants) { user in
                        HStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(user.username.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                )

                            VStack(alignment: .leading) {
                                Text(user.fullName ?? user.username)
                                    .font(.body)
                                Text("@\(user.username)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Participant View

struct AddParticipantView: View {
    let conversation: Conversation
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var searchResults: [User] = []

    var body: some View {
        NavigationStack {
            List(searchResults) { user in
                Button(action: { addParticipant(user) }) {
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(user.username.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            )

                        VStack(alignment: .leading) {
                            Text(user.fullName ?? user.username)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("@\(user.username)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Participant")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addParticipant(_ user: User) {
        // Would call API to add participant
        dismiss()
    }
}

// MARK: - Add AI Agent View

struct AddAIAgentView: View {
    let conversation: Conversation
    @Environment(\.dismiss) var dismiss

    @State private var chatSettings = ChatSettingsManager.shared

    var availableAgents: [AIAgent] {
        chatSettings.getActiveAgents()
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(availableAgents) { agent in
                    Button(action: { addAgent(agent) }) {
                        HStack {
                            Image(systemName: agent.avatar)
                                .font(.title2)
                                .foregroundColor(colorFromString(agent.color))
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(agent.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(agent.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 4) {
                                    ForEach(agent.capabilities.prefix(3), id: \.self) { capability in
                                        Text(capability.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Add AI Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addAgent(_ agent: AIAgent) {
        // Would call API to add AI agent to conversation
        dismiss()
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "pink": return .pink
        case "orange": return .orange
        default: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupConversationView(conversation: Conversation(
            id: 1,
            title: "Preview",
            mode: "solo",
            withAI: false,
            defaultModelId: nil,
            participants: [],
            participantUsernames: [],
            lastMessage: nil,
            unreadCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
