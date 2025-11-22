//
//  GroupConversationView.swift
//  Cafe
//
//  Enhanced conversation view with group chat and AI agents
//

import SwiftUI

struct GroupConversationView: View {
    @Environment(ThemeManager.self) var themeManager
    @StateObject private var store: ConversationStore
    @State private var messageText = ""
    @State private var showingParticipants = false
    @State private var showingAddParticipant = false
    private let onConversationUpdated: (Conversation) -> Void

    init(conversation: Conversation, onConversationUpdated: @escaping (Conversation) -> Void = { _ in }) {
        _store = StateObject(wrappedValue: ConversationStore(conversation: conversation))
        self.onConversationUpdated = onConversationUpdated
    }

    var isGroupChat: Bool {
        store.conversation.participants.count > 2
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
                                isGroup: isGroupChat,
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
                // Add participants button
                Button(action: { showingAddParticipant = true }) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundColor(themeManager.accentColor)
                }

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
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? themeManager.secondaryTextColor : themeManager.accentColor)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isSending)
            }
            .padding()
            .background(themeManager.backgroundColor)
        }
        .navigationTitle(conversationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingParticipants = true }) {
                    ParticipantAvatarsView(participants: Array(store.conversation.participants.prefix(3)))
                }
            }
        }
        .sheet(isPresented: $showingParticipants) {
            ParticipantsListView(conversation: store.conversation)
        }
        .sheet(isPresented: $showingAddParticipant) {
            AddParticipantView(conversation: store.conversation)
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

    private var conversationTitle: String {
        if isGroupChat {
            let names = store.conversation.participants.prefix(3).compactMap { user in
                user.fullName ?? user.username
            }
            if store.conversation.participants.count > 3 {
                return names.joined(separator: ", ") + " +\(store.conversation.participants.count - 3)"
            }
            return names.joined(separator: ", ")
        }
        return store.conversation.displayName
    }

    private func sendMessage() {
        let pending = messageText
        let content = pending.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        messageText = "" // Clear immediately for better UX

        _Concurrency.Task {
            await store.send(content: content)
            if store.error != nil {
                messageText = pending
            }
        }
    }
}

// MARK: - Participant Avatars

struct ParticipantAvatarsView: View {
    @Environment(ThemeManager.self) var themeManager
    let participants: [User]

    var body: some View {
        HStack(spacing: -8) {
            ForEach(participants) { user in
                Circle()
                    .fill(themeManager.accentColor.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text(user.username.prefix(1).uppercased())
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.accentColor)
                    )
                    .overlay(
                        Circle()
                            .stroke(themeManager.backgroundColor, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var animationAmount = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(themeManager.secondaryTextColor)
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
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
        .onAppear {
            animationAmount = 2.0
        }
    }
}

// MARK: - Participants List

struct ParticipantsListView: View {
    @Environment(ThemeManager.self) var themeManager
    let conversation: Conversation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Members (\(conversation.participants.count))") {
                    ForEach(conversation.participants) { user in
                        HStack {
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(user.username.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundColor(themeManager.accentColor)
                                )

                            VStack(alignment: .leading) {
                                Text(user.fullName ?? user.username)
                                    .font(.body)
                                    .foregroundColor(themeManager.textColor)
                                Text("@\(user.username)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
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
    @Environment(ThemeManager.self) var themeManager
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
                            .fill(themeManager.accentColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(user.username.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundColor(themeManager.accentColor)
                            )

                        VStack(alignment: .leading) {
                            Text(user.fullName ?? user.username)
                                .font(.body)
                                .foregroundColor(themeManager.textColor)
                            Text("@\(user.username)")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.successColor)
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
    @Environment(ThemeManager.self) var themeManager
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
                                    .foregroundColor(themeManager.textColor)

                                Text(agent.description)
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)

                                HStack(spacing: 4) {
                                    ForEach(agent.capabilities.prefix(3), id: \.self) { capability in
                                        Text(capability.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(themeManager.secondaryTextColor.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(themeManager.successColor)
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
