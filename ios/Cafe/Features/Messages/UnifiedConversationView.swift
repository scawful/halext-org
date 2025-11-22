//
//  UnifiedConversationView.swift
//  Cafe
//
//  Unified conversation view supporting both human messaging and AI chat with streaming
//

import SwiftUI

struct UnifiedConversationView: View {
    let conversation: Conversation
    let onUpdate: (Conversation) -> Void
    
    @Environment(ThemeManager.self) private var themeManager
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showRetry = false
    @State private var streamingText: String = ""
    @State private var isStreaming: Bool = false
    @State private var showModelPicker: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with conversation info
            conversationHeader
            
            Divider()
            
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            // Streaming message (if AI is responding)
                            if isStreaming && !streamingText.isEmpty {
                                StreamingMessageBubble(text: streamingText)
                                    .id("streaming")
                            }
                        }
                    }
                    .padding()
                }
                .background(themeManager.backgroundColor)
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isStreaming) { _, streaming in
                    if streaming {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            Divider()
            
            // Input area
            inputArea
                .focused($isInputFocused)
                .padding()
                .background(themeManager.cardBackgroundColor)
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .navigationTitle(conversation.title ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                conversationMenu
            }
        }
        .task {
            await loadMessages()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) { errorMessage = nil }
            if showRetry {
                Button("Retry") {
                    errorMessage = nil
                    _Concurrency.Task {
                        await loadMessages()
                    }
                }
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .sheet(isPresented: $showModelPicker) {
            if conversation.isAIEnabled {
                AIModelSelectionSheet(
                    currentModelId: conversation.defaultModelId,
                    onSelectModel: { modelId in
                        // Update conversation model
                        _Concurrency.Task {
                            await updateConversationModel(modelId)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var conversationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title ?? "Conversation")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if conversation.isAIEnabled {
                        Label("AI Enabled", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        if let modelId = conversation.defaultModelId, !modelId.isEmpty {
                            Button {
                                showModelPicker = true
                            } label: {
                                Label(modelId, systemImage: "cpu")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    } else {
                        if !conversation.participantDisplayNames.isEmpty {
                            Text(conversation.participantDisplayNames)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
    }
    
    // MARK: - Menu
    
    private var conversationMenu: some View {
        Menu {
            if conversation.isAIEnabled {
                Button {
                    showModelPicker = true
                } label: {
                    Label("Change AI Model", systemImage: "cpu")
                }
                
                Button {
                    _Concurrency.Task {
                        await regenerateLastResponse()
                    }
                } label: {
                    Label("Regenerate Response", systemImage: "arrow.clockwise")
                }
                .disabled(messages.isEmpty || isLoading)
            }
            
            Button(role: .destructive) {
                clearConversation()
            } label: {
                Label("Clear Messages", systemImage: "trash")
            }
            .disabled(messages.isEmpty)
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            if conversation.isAIEnabled {
                // AI conversation empty state
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                
                Text("AI Assistant Ready")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Ask me anything to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                // Human conversation empty state
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                
                Text("Start the Conversation")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Send a message to begin chatting")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField(conversation.isAIEnabled ? "Ask me anything..." : "Type a message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(1...5)
                .onSubmit {
                    if !inputText.isEmpty && !isLoading {
                        sendMessage()
                    }
                }
            
            Button(action: sendMessage) {
                Image(systemName: isLoading || isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        inputText.isEmpty && !isLoading && !isStreaming
                            ? AnyShapeStyle(Color.secondary)
                            : AnyShapeStyle(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
            }
            .disabled(inputText.isEmpty && !isLoading && !isStreaming)
        }
    }
    
    // MARK: - Actions
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            messages = try await APIClient.shared.getMessages(conversationId: conversation.id)
            await MainActor.run {
                errorMessage = nil
                showRetry = false
            }
        } catch {
            await MainActor.run {
                // Provide user-friendly error messages and determine if retry should be shown
                let friendlyMessage: String
                var shouldShowRetry = false
                
                if let apiError = error as? APIError {
                    friendlyMessage = apiError.errorDescription ?? "Failed to load messages. Please try again."
                    // Show retry for transient errors
                    shouldShowRetry = apiError != .unauthorized && apiError != .notAuthenticated
                } else if let urlError = error as? URLError {
                    friendlyMessage = "Network error: \(urlError.localizedDescription). Please check your connection and try again."
                    shouldShowRetry = true
                } else {
                    friendlyMessage = "Failed to load messages: \(error.localizedDescription)"
                    shouldShowRetry = true
                }
                
                errorMessage = friendlyMessage
                showRetry = shouldShowRetry
            }
        }
    }
    
    private func sendMessage() {
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        // If currently loading or streaming, stop it
        if isLoading || isStreaming {
            isStreaming = false
            isLoading = false
            return
        }
        
        // Clear input immediately for better UX
        inputText = ""
        
        // If AI is enabled, use streaming
        if conversation.isAIEnabled {
            _Concurrency.Task {
                await sendWithStreaming(message: messageText)
            }
        } else {
            _Concurrency.Task {
                await sendRegularMessage(message: messageText)
            }
        }
    }
    
    private func sendRegularMessage(message: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let newMessages = try await APIClient.shared.sendMessage(
                conversationId: conversation.id,
                content: message,
                model: conversation.defaultModelId
            )
            
            // Add new messages to list
            await MainActor.run {
                messages.append(contentsOf: newMessages)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to send message: \(error.localizedDescription)"
                // Restore input text so user can retry
                inputText = message
            }
        }
    }
    
    private func sendWithStreaming(message: String) async {
        isStreaming = true
        streamingText = ""
        
        // Add user message optimistically (will be replaced with server response)
        // Note: We'll reload messages after sending to get proper server response
        
        do {
            // Get streaming response
            let result = try await APIClient.shared.streamChatMessage(
                prompt: message,
                history: messages.map { 
                    ChatMessage(
                        role: $0.isFromAI ? "assistant" : "user", 
                        content: $0.content
                    ) 
                },
                model: conversation.defaultModelId
            )
            
            // Stream tokens
            for try await token in result.stream {
                await MainActor.run {
                    streamingText += token
                }
            }
            
            await MainActor.run {
                streamingText = ""
                isStreaming = false
            }
            
            // Reload messages from server to get proper IDs
            await loadMessages()
        } catch {
            await MainActor.run {
                isStreaming = false
                errorMessage = "Failed to get AI response: \(error.localizedDescription)"
                // Restore input so user can retry
                inputText = message
            }
        }
    }
    
    private func regenerateLastResponse() async {
        guard let lastUserMessage = messages.last(where: { !$0.isFromAI }) else { return }
        
        // Remove last AI response if exists
        if let lastAI = messages.last(where: { $0.isFromAI }) {
            messages.removeAll { $0.id == lastAI.id }
        }
        
        await sendWithStreaming(message: lastUserMessage.content)
    }
    
    private func clearConversation() {
        messages.removeAll()
    }
    
    private func updateConversationModel(_ modelId: String?) async {
        // This would call API to update conversation model
        // For now, just close the sheet
        showModelPicker = false
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromAI {
                // AI avatar
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            } else {
                Spacer()
            }
            
            VStack(alignment: message.isFromAI ? .leading : .trailing, spacing: 4) {
                if message.isFromAI, let model = message.modelUsed {
                    Label {
                        Text(model)
                            .font(.caption2)
                    } icon: {
                        Image(systemName: "cpu")
                    }
                    .foregroundStyle(.secondary)
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isFromAI ? .primary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.isFromAI ? Color(.systemGray6) : Color.blue)
                    )
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        ShareLink(item: message.content) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromAI {
                // User avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                    }
            } else {
                Spacer()
            }
        }
    }
}

// MARK: - Streaming Message Bubble

struct StreamingMessageBubble: View {
    let text: String
    @State private var animating = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(animating ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animating)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                if !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                        )
                } else {
                    // Typing indicator
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.secondary.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .scaleEffect(animating ? 1.0 : 0.5)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: animating
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Label("Generating...", systemImage: "ellipsis")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - AI Model Selection Sheet

struct AIModelSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) var appState
    
    let currentModelId: String?
    let onSelectModel: (String?) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                if let models = appState.aiModels {
                    ForEach(models.models) { model in
                        Button {
                            onSelectModel(model.id)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.name)
                                        .font(.headline)
                                    
                                    Text(model.provider)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let description = model.description {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Spacer()
                                
                                if model.id == currentModelId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } else {
                    ProgressView("Loading models...")
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Select AI Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if appState.aiModels == nil {
                    await appState.loadAIModels()
                }
            }
        }
    }
}

#Preview {
    UnifiedConversationView(
        conversation: Conversation(
            id: 1,
            title: "AI Assistant",
            mode: "solo",
            withAI: true,
            defaultModelId: "gemini:gemini-2.5-flash",
            hiveMindGoal: nil,
            participants: [],
            participantUsernames: [],
            lastMessage: nil,
            unreadCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        ),
        onUpdate: { _ in }
    )
    .environment(AppState())
    .environment(ThemeManager.shared)
}

