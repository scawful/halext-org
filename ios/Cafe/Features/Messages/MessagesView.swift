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
    @State private var preferredContactUsername: String = "magicalgirl"
    @State private var chrisConversation: Conversation?
    @State private var isLoadingChris = false
    @State private var chrisPresence: SocialPresenceStatus?
    @State private var showRetry = false

    var body: some View {
        NavigationStack {
            Group {
                themeManager.backgroundColor.ignoresSafeArea()
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.conversations.isEmpty {
                    EmptyConversationsView(onNewMessage: { showingNewMessage = true })
                } else {
                    List {
                        // Featured: AI Chat (prominent entry)
                        Section {
                            Button {
                                _Concurrency.Task {
                                    await startAIConversation(modelId: nil)
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        LinearGradient(
                                            colors: [.blue, .purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Text("AI Chat")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                            
                                            Image(systemName: "wand.and.stars")
                                                .foregroundColor(.purple)
                                                .font(.caption)
                                        }
                                        
                                        Text("Start a conversation with AI • Get instant help")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                            
                            NavigationLink {
                                AgentHubView(onStartChat: { modelId in
                                    _Concurrency.Task {
                                        await startAIConversation(modelId: modelId)
                                    }
                                })
                            } label: {
                                HStack {
                                    Image(systemName: "cpu.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.purple.opacity(0.8))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Agent Hub")
                                            .font(.headline)
                                        Text("Choose your AI model and customize")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
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
                    .scrollContentBackground(.hidden)
                    .background(themeManager.backgroundColor.ignoresSafeArea())
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
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
                await loadChrisPresence()
            }
            .alert("Error", isPresented: Binding(get: { viewModel.error != nil }, set: { _ in 
                viewModel.error = nil
                showRetry = false
            })) {
                Button("OK", role: .cancel) { 
                    viewModel.error = nil
                    showRetry = false
                }
                if showRetry {
                    Button("Retry") {
                        viewModel.error = nil
                        showRetry = false
                        _Concurrency.Task {
                            await viewModel.load()
                        }
                    }
                }
            } message: {
                Text(viewModel.error ?? "")
            }
            .onChange(of: viewModel.error) { _, newError in
                if let error = newError {
                    // Determine if retry should be shown based on error type
                    // Since we only have error string, we'll check common patterns
                    showRetry = !error.lowercased().contains("session") && 
                               !error.lowercased().contains("expired") &&
                               !error.lowercased().contains("unauthorized") &&
                               !error.lowercased().contains("authenticated")
                } else {
                    showRetry = false
                }
            }
        }
    }

    private func destinationView(for conversation: Conversation) -> some View {
        // Use unified conversation view for all conversations (supports both AI and human chat)
        UnifiedConversationView(conversation: conversation) { updated in
            viewModel.insertOrUpdate(updated)
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
    
    // MARK: - Chris Conversation Helpers
    
    private func openOrCreateChrisConversation() async {
        await MainActor.run {
            isLoadingChris = true
        }
        
        defer {
            _Concurrency.Task { @MainActor in
                isLoadingChris = false
            }
        }
        
        // First, try to find existing conversation with Chris
        if let existing = viewModel.conversations.first(where: { conv in
            conv.participantUsernames.contains(where: { $0.lowercased() == preferredContactUsername.lowercased() })
        }) {
            await MainActor.run {
                chrisConversation = existing
                activeConversation = existing
            }
            return
        }
        
        // If not found, search for Chris user and create conversation
        do {
            let users = try await APIClient.shared.searchUsers(query: preferredContactUsername)
            if let chrisUser = users.first(where: { $0.username.lowercased() == preferredContactUsername.lowercased() }) {
                let convo = try await APIClient.shared.createConversation(
                    title: "Chat with \(chrisUser.fullName ?? chrisUser.username)",
                    participantUsernames: [chrisUser.username],
                    withAI: false
                )
                await MainActor.run {
                    viewModel.insertOrUpdate(convo)
                    chrisConversation = convo
                    activeConversation = convo
                }
            } else {
                await MainActor.run {
                    viewModel.error = "Could not find user '\(preferredContactUsername)'"
                }
            }
        } catch {
            await MainActor.run {
                viewModel.error = "Failed to start conversation: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadChrisPresence() async {
        // Try to get Chris's presence status
        // This will be enhanced when we add presence API
        do {
            let users = try await APIClient.shared.searchUsers(query: preferredContactUsername)
            if let chrisUser = users.first(where: { $0.username.lowercased() == preferredContactUsername.lowercased() }) {
                // For now, we'll use a placeholder presence
                // This will be replaced with actual presence API call
                await MainActor.run {
                    chrisPresence = SocialPresenceStatus(
                        profileId: "\(chrisUser.id)",
                        isOnline: false,
                        currentActivity: nil,
                        statusMessage: nil,
                        lastUpdated: Date()
                    )
                }
            }
        } catch {
            // Silently fail - presence is optional
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
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }

            VStack(spacing: 12) {
                Text("No Conversations Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start chatting with AI agents or message other users")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(action: onNewMessage) {
                    Label("New Message", systemImage: "square.and.pencil")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                
                NavigationLink(destination: AgentHubView(onStartChat: { _ in })) {
                    Label("Browse AI Agents", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
