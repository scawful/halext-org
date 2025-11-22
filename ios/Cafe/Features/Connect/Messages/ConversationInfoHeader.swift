//
//  ConversationInfoHeader.swift
//  Cafe
//
//  Surfaces server-backed conversation facts (participants, AI model, timestamps).
//

import SwiftUI

struct ConversationInfoHeader: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Label(conversation.displayName, systemImage: "person.2")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                if conversation.hasHiveMindGoal {
                    TagView(text: "Hive Mind", icon: "brain", tint: .orange.opacity(0.2), foreground: .orange)
                }

                if conversation.isAIEnabled {
                    TagView(text: "AI", icon: "sparkles", tint: .purple.opacity(0.2), foreground: .purple)
                }

                if let model = conversation.defaultModelId, !model.isEmpty {
                    TagView(text: model, icon: "cpu", tint: .blue.opacity(0.1), foreground: .blue)
                }
            }
            
            if let goal = conversation.hiveMindGoal, !goal.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "target")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(goal)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            if !conversation.participantDisplayNames.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundColor(.secondary)
                    Text(conversation.participantDisplayNames)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 10) {
                if let updated = conversation.updatedAt {
                    Label {
                        Text(updated, style: .relative)
                    } icon: {
                        Image(systemName: "clock")
                    }
                } else if let created = conversation.createdAt {
                    Label {
                        Text(created, style: .date)
                    } icon: {
                        Image(systemName: "clock")
                    }
                }

                if conversation.unreadCount > 0 {
                    TagView(
                        text: "\(conversation.unreadCount) unread",
                        icon: "envelope.badge",
                        tint: .orange.opacity(0.15),
                        foreground: .orange
                    )
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

private struct TagView: View {
    let text: String
    let icon: String
    let tint: Color
    let foreground: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint)
        .foregroundColor(foreground)
        .clipShape(Capsule())
    }
}
