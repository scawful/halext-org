//
//  MessagesView.swift
//  Cafe
//
//  User-to-user messaging interface
//

import SwiftUI

struct MessagesView: View {
    @Environment(ThemeManager.self) private var themeManager
    @StateObject private var viewModel = ConversationsViewModel()
    @State private var presenceManager = SocialPresenceManager.shared
    @State private var showingNewMessage = false
    @State private var activeConversation: Conversation?
    @State private var preferredContactUsername: String = "chris"

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.conversations.isEmpty {
                    EmptyConversationsView(onNewMessage: { showingNewMessage = true })
                } else {
                    List {
                        // Unified AI + people quick actions
                        Section {
                            NavigationLink {
                                AgentHubView(onStartChat: { modelId in
                                    _Concurrency.Task {
                                        await startAIConversation(modelId: modelId)
                                    }
                                })
                            } label: {
                                HStack {
                                    Image(systemName: "atom")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Agents & LLMs")
                                            .font(.headline)
                                        Text("Manage models and start AI threads")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }

                            Button {
                                showingNewMessage = true
                                // seed search for preferred contact
                                NotificationCenter.default.post(
                                    name: Notification.Name("MessagesViewSeedSearch"),
                                    object: preferredContactUsername
                                )
                            } label: {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.green)
                                    Text("Message \(preferredContactUsername.capitalized)")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listRowBackground(themeManager.cardBackgroundColor)

                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(destination: destinationView(for: conversation)) {
                                ConversationRowView(
                                    conversation: conversation,
                                    presence: nil
                                )
                            }
                        }
                        .onDelete(perform: deleteConversations)
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewMessage = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: destinationView(for: activeConversation ?? Conversation(id: -1, title: "AI", mode: "solo", withAI: true, defaultModelId: nil, hiveMindGoal: nil, participants: [], participantUsernames: [], lastMessage: nil, unreadCount: 0, createdAt: nil, updatedAt: nil)),
                    isActive: Binding(
                        get: { activeConversation != nil },
                        set: { newValue in
                            if !newValue { activeConversation = nil }
                        }
                    )
                ) {
                    EmptyView()
                }
            )
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView(onConversationCreated: { conversation in
                    viewModel.insertOrUpdate(conversation)
                })
            }
            .task {
                presenceManager.startTrackingPresence()
                presenceManager.startMonitoringPartnerPresence()
                await viewModel.load()
            }
            .alert("Error", isPresented: Binding(get: { viewModel.error != nil }, set: { _ in viewModel.error = nil })) {
                Button("OK", role: .cancel) { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }

    private func destinationView(for conversation: Conversation) -> some View {
        Group {
            if conversation.participants.count > 2 {
                GroupConversationView(conversation: conversation) { updated in
                    viewModel.insertOrUpdate(updated)
                }
            } else {
                ConversationView(conversation: conversation) { updated in
                    viewModel.insertOrUpdate(updated)
                }
            }
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        viewModel.delete(at: offsets)
    }

    private func startAIConversation(modelId: String?) async {
        do {
            let convo = try await APIClient.shared.createConversation(
                title: "AI Agent",
                participantUsernames: [],
                withAI: true,
                defaultModelId: modelId
            )
            viewModel.insertOrUpdate(convo)
            activeConversation = convo
        } catch {
            viewModel.error = error.localizedDescription
        }
    }
}

// MARK: - Conversation Row

struct ConversationRowView: View {
    let conversation: Conversation
    let presence: SocialPresenceStatus?

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.displayName.prefix(1).uppercased())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName)
                        .font(.headline)

                    if let presence = presence {
                        PresenceDot(isOnline: presence.isOnline)
                    }

                    Spacer()

                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let lastMessage = conversation.lastMessage {
                    HStack {
                        Text(lastMessage.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        Spacer()

                        if conversation.unreadCount > 0 {
                            Text("\(conversation.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }

                HStack(spacing: 8) {
                    if conversation.isAIEnabled {
                        Label("AI", systemImage: "sparkles")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.12))
                            .foregroundColor(.purple)
                            .cornerRadius(8)
                    }

                    if let model = conversation.defaultModelId, !model.isEmpty {
                        Label(model, systemImage: "cpu")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }

                if !conversation.participantDisplayNames.isEmpty {
                    Text(conversation.participantDisplayNames)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

struct EmptyConversationsView: View {
    let onNewMessage: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Conversations Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start a conversation with your team members")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: onNewMessage) {
                Label("New Message", systemImage: "square.and.pencil")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Presence Indicator

struct PresenceDot: View {
    let isOnline: Bool

    var body: some View {
        Circle()
            .fill(isOnline ? Color.green : Color.gray.opacity(0.5))
            .frame(width: 10, height: 10)
    }
}

// MARK: - New Message View

struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss
    let onConversationCreated: (Conversation) -> Void

    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var selectedUser: User?
    @State private var isSearching = false
    @State private var notificationObserver: NSObjectProtocol?

    var body: some View {
        NavigationStack {
            VStack {
                if let user = selectedUser {
                    // Show selected user
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
                                .font(.headline)
                            Text("@\(user.username)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { selectedUser = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding()

                    Button(action: createConversation) {
                        Text("Start Conversation")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                } else {
                    // Search for users
                    List {
                        if isSearching {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if searchResults.isEmpty && !searchText.isEmpty {
                            Text("No users found")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(searchResults) { user in
                                Button(action: { selectedUser = user }) {
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

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search users")
            .onChange(of: searchText) { _, newValue in
                searchUsers(query: newValue)
            }
            .onAppear {
                notificationObserver = NotificationCenter.default.addObserver(
                    forName: Notification.Name("MessagesViewSeedSearch"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let seed = notification.object as? String, searchText.isEmpty {
                        searchText = seed
                        searchUsers(query: seed)
                    }
                }
            }
            .onDisappear {
                if let observer = notificationObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func searchUsers(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        _Concurrency.Task {
            do {
                searchResults = try await APIClient.shared.searchUsers(query: query)
            } catch {
                print("Search error: \(error)")
            }
            isSearching = false
        }
    }

    private func createConversation() {
        guard let user = selectedUser else { return }

        _Concurrency.Task {
            do {
                let conversation = try await APIClient.shared.createConversation(
                    title: "Chat with \(user.username)",
                    participantUsernames: [user.username],
                    withAI: false
                )
                onConversationCreated(conversation)
                dismiss()
            } catch {
                print("Failed to create conversation: \(error)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MessagesView()
}
