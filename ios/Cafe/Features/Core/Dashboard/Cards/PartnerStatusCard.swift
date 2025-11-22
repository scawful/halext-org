//
//  PartnerStatusCard.swift
//  Cafe
//
//  Dashboard widget showing partner (Chris) status and quick actions
//

import SwiftUI

struct PartnerStatusCard: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var chrisPresence: PartnerPresence?
    @State private var isLoading = false
    @State private var settingsManager = SettingsManager.shared
    @State private var chrisConversation: Conversation?
    @State private var isLoadingMessage = false
    @State private var errorMessage: String?
    @State private var showRetry = false
    @State private var isPressed = false
    @State private var isCalendarPressed = false
    @State private var isMessageIconPressed = false
    @State private var isPulsing = false
    
    private var preferredContactUsername: String {
        settingsManager.preferredContactUsername
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chris")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if let presence = chrisPresence {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(presence.isOnline ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(presence.isOnline ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                                        .scaleEffect(isPulsing ? 2.5 : 1.0)
                                        .opacity(isPulsing ? 0 : 0.6)
                                )
                                .onAppear {
                                    if presence.isOnline {
                                        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                            isPulsing = true
                                        }
                                    }
                                }
                                .accessibilityHidden(true)

                            Text(presence.isOnline ? "Online" : "Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Chris is \(presence.isOnline ? "online" : "offline")")
                        .onChange(of: presence.isOnline) { _, isOnline in
                            if isOnline {
                                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                                    isPulsing = true
                                }
                            } else {
                                isPulsing = false
                            }
                        }
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Loading partner status")
                    }
                }
                
                Spacer()
                
                Button {
                    HapticManager.selection()
                    _Concurrency.Task {
                        await openOrCreateChrisConversation()
                    }
                } label: {
                    if isLoadingMessage {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.blue)
                    } else {
                        Image(systemName: "message.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .scaleEffect(isMessageIconPressed ? 0.85 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isMessageIconPressed)
                    }
                }
                .disabled(isLoadingMessage)
                .buttonStyle(.plain)
                .accessibilityLabel(isLoadingMessage ? "Loading conversation" : "Quick message Chris")
                .accessibilityHint("Opens a direct message conversation with Chris")
                .accessibilityAddTraits(.isButton)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isMessageIconPressed = true }
                        .onEnded { _ in isMessageIconPressed = false }
                )
            }
            
            // Status message
            if let presence = chrisPresence, let activity = presence.currentActivity {
                HStack {
                    Image(systemName: "ellipsis.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(activity)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Quick actions
            HStack(spacing: 12) {
                Button {
                    HapticManager.selection()
                    _Concurrency.Task {
                        await openOrCreateChrisConversation()
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isLoadingMessage {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "message.fill")
                        }
                        Text("Message")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.3), radius: isPressed ? 2 : 4, y: isPressed ? 1 : 2)
                    )
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 0.97 : 1.0)
                }
                .disabled(isLoadingMessage)
                .buttonStyle(.plain)
                .accessibilityLabel(isLoadingMessage ? "Loading message" : "Message Chris")
                .accessibilityHint("Opens a conversation to send a message to Chris")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )

                NavigationLink {
                    SharedCalendarView()
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.pink.opacity(isCalendarPressed ? 0.35 : 0.2))
                            .shadow(color: Color.pink.opacity(0.2), radius: isCalendarPressed ? 2 : 4, y: isCalendarPressed ? 1 : 2)
                    )
                    .foregroundColor(.pink)
                    .scaleEffect(isCalendarPressed ? 0.97 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isCalendarPressed)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Shared calendar with Chris")
                .accessibilityHint("Opens the shared calendar to view events with Chris")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            isCalendarPressed = true
                            HapticManager.lightImpact()
                        }
                        .onEnded { _ in isCalendarPressed = false }
                )
            }
        }
        .padding()
        .themedCardBackground(cornerRadius: 16, shadow: true)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .task {
            await loadPresence()
        }
        .background(
            // NavigationLink that activates when conversation is set
            // Using NavigationLink with value for modern NavigationStack compatibility
            Group {
                if let conversation = chrisConversation {
                    NavigationLink(
                        value: conversation
                    ) {
                        EmptyView()
                    }
                }
            }
        )
        .navigationDestination(for: Conversation.self) { conversation in
            UnifiedConversationView(conversation: conversation) { updated in
                // Update conversation if needed
                chrisConversation = updated
            }
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) { errorMessage = nil }
            if showRetry {
                Button("Retry") {
                    errorMessage = nil
                    _Concurrency.Task {
                        await openOrCreateChrisConversation()
                    }
                }
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadPresence() async {
        isLoading = true
        do {
            let presence = try await APIClient.shared.getPartnerPresence(username: preferredContactUsername)
            await MainActor.run {
                chrisPresence = presence
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    // MARK: - Chris Conversation Helpers
    
    private func openOrCreateChrisConversation() async {
        await MainActor.run {
            isLoadingMessage = true
            errorMessage = nil
        }
        
        defer {
            _Concurrency.Task { @MainActor in
                isLoadingMessage = false
            }
        }
        
        // First, try to get existing conversations and find one with Chris
        do {
            let conversations = try await APIClient.shared.getConversations()
            if let existing = conversations.first(where: { conv in
                conv.participantUsernames.contains(where: { $0.lowercased() == preferredContactUsername.lowercased() })
            }) {
                await MainActor.run {
                    chrisConversation = existing
                }
                return
            }
            
            // If not found, search for Chris user and create conversation
            let users = try await APIClient.shared.searchUsers(query: preferredContactUsername)
            if let chrisUser = users.first(where: { $0.username.lowercased() == preferredContactUsername.lowercased() }) {
                let convo = try await APIClient.shared.createConversation(
                    title: "Chat with \(chrisUser.fullName ?? chrisUser.username)",
                    participantUsernames: [chrisUser.username],
                    withAI: false
                )
                await MainActor.run {
                    chrisConversation = convo
                }
            } else {
                await MainActor.run {
                    errorMessage = "Could not find user. Please make sure the username is correct."
                }
            }
        } catch {
            await MainActor.run {
                // Provide user-friendly error messages
                let friendlyMessage: String
                var shouldShowRetry = false
                
                if let apiError = error as? APIError {
                    friendlyMessage = apiError.errorDescription ?? "Unable to start conversation. Please try again."
                    // Show retry for transient errors
                    shouldShowRetry = apiError != .unauthorized && apiError != .notAuthenticated
                } else if let urlError = error as? URLError {
                    friendlyMessage = "Network error: \(urlError.localizedDescription). Please check your connection and try again."
                    shouldShowRetry = true
                } else {
                    friendlyMessage = "Unable to start conversation. Please check your connection and try again."
                    shouldShowRetry = true
                }
                
                errorMessage = friendlyMessage
                showRetry = shouldShowRetry
            }
        }
    }
}

#Preview {
    PartnerStatusCard()
        .padding()
}

