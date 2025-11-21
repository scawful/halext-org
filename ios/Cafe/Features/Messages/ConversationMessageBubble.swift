//
//  ConversationMessageBubble.swift
//  Cafe
//
//  Shared bubble for message threads that can surface backend metadata.
//

import SwiftUI

struct ConversationMessageBubble: View {
    let message: Message
    let senderName: String
    let isGroup: Bool
    let defaultModelId: String?

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 6) {
                if shouldShowSender {
                    HStack(spacing: 6) {
                        Text(senderName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        if message.isFromAI {
                            Label("AI", systemImage: "sparkles")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
                                .cornerRadius(6)
                        }
                    }
                }

                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleBackground)
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)

                HStack(spacing: 6) {
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let modelBadge = modelBadgeText {
                        Label(modelBadge, systemImage: "cpu")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }

                    if let authorType = message.authorType, !authorType.isEmpty, !message.isFromAI {
                        Text(authorType.uppercased())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }

    private var shouldShowSender: Bool {
        isGroup || message.isFromAI
    }

    private var bubbleBackground: Color {
        if message.isFromCurrentUser {
            return .blue
        }
        if message.isFromAI {
            return Color.purple.opacity(0.12)
        }
        return Color(.secondarySystemBackground)
    }

    private var modelBadgeText: String? {
        if let modelUsed = message.modelUsed {
            return modelUsed
        }
        if message.isFromAI {
            return defaultModelId
        }
        return nil
    }
}
