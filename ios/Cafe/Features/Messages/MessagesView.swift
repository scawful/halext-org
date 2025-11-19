//
//  MessagesView.swift
//  Cafe
//
//  User-to-user messaging interface
//

import SwiftUI

struct MessagesView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNewMessage = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if conversations.isEmpty {
                    EmptyConversationsView(onNewMessage: { showingNewMessage = true })
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            NavigationLink(destination: GroupConversationView(conversation: conversation)) {
                                ConversationRowView(conversation: conversation)
                            }
                        }
                        .onDelete(perform: deleteConversations)
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await loadConversations()
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
            .sheet(isPresented: $showingNewMessage) {
                NewMessageView(onConversationCreated: { conversation in
                    conversations.insert(conversation, at: 0)
                })
            }
            .task {
                await loadConversations()
            }
        }
    }

    private func loadConversations() async {
        isLoading = true
        defer { isLoading = false }

        do {
            conversations = try await APIClient.shared.getConversations()
            conversations.sort { ($0.updatedAt) > ($1.updatedAt) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversations[index]
            _Concurrency.Task {
                try? await APIClient.shared.deleteConversation(id: conversation.id)
            }
        }
        conversations.remove(atOffsets: offsets)
    }
}

// MARK: - Conversation Row

struct ConversationRowView: View {
    let conversation: Conversation

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
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Conversations")
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

// MARK: - New Message View

struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss
    let onConversationCreated: (Conversation) -> Void

    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var selectedUser: User?
    @State private var isSearching = false

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
                let conversation = try await APIClient.shared.createConversation(participantIds: [user.id])
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
