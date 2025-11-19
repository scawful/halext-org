//
//  ChatView.swift
//  Cafe
//
//  Modern chat interface with streaming AI responses
//

import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.messages.isEmpty {
                                EmptyChatView()
                            } else {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }

                            // Typing indicator
                            if viewModel.isLoading {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isLoading) { _, isLoading in
                        if isLoading {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }

                Divider()

                // Input area
                ChatInputView(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    onSend: {
                        _Concurrency.Task {
                            await viewModel.sendMessage()
                        }
                    }
                )
                .focused($isInputFocused)
                .padding()
            }
            .navigationTitle("AI Assistant")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            _Concurrency.Task {
                                await viewModel.regenerateLastResponse()
                            }
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        .disabled(viewModel.messages.isEmpty)

                        Button(role: .destructive) {
                            viewModel.clearChat()
                        } label: {
                            Label("Clear Chat", systemImage: "trash")
                        }
                        .disabled(viewModel.messages.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if viewModel.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: AiChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                // AI avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            } else {
                Spacer()
            }

            // Message content
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(message.role == .user
                                ? Color.blue
                                : Color(.systemGray6)
                            )
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
            }

            if message.role == .user {
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

// MARK: - Empty Chat

struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Welcome text
            VStack(spacing: 8) {
                Text("AI Assistant")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Ask me anything to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // Example prompts
            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(examplePrompts, id: \.self) { prompt in
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(prompt)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)

            Spacer()
        }
    }

    private var examplePrompts: [String] {
        [
            "Help me plan my day",
            "Suggest productive morning routines",
            "What's a good time management strategy?",
            "Create a task breakdown for my project"
        ]
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

            // Animated dots
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

            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Chat Input

struct ChatInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("Ask me anything...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(1...5)
                .onSubmit {
                    if !text.isEmpty && !isLoading {
                        onSend()
                    }
                }

            // Send button
            Button(action: onSend) {
                Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        text.isEmpty || isLoading ? AnyShapeStyle(Color.secondary) : AnyShapeStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    )
            }
            .disabled(text.isEmpty && !isLoading)
        }
    }
}

// MARK: - Preview

#Preview {
    ChatView()
}
