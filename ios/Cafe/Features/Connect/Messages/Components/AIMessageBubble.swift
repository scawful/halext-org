//
//  AIMessageBubble.swift
//  Cafe
//
//  Enhanced AI message bubble with improved design, shadows, and actions
//

import SwiftUI

struct AIMessageBubble: View {
    let message: Message
    let onCopy: () -> Void
    let onRegenerate: (() -> Void)?
    
    @Environment(ThemeManager.self) private var themeManager
    @State private var showActions = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.accentColor.opacity(0.8),
                            themeManager.accentColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 8) {
                // Model badge (if available)
                if let model = message.modelUsed {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.caption2)
                        Text(model)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(themeManager.cardBackgroundColor.opacity(0.6))
                    )
                }
                
                // Message content bubble
                VStack(alignment: .leading, spacing: 0) {
                    MarkdownRenderer(text: message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.cardBackgroundColor)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    themeManager.accentColor.opacity(0.2),
                                    themeManager.accentColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                
                // Actions row
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.selection()
                        onCopy()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                            Text("Copy")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                    
                    if let onRegenerate = onRegenerate {
                        Button(action: {
                            HapticManager.selection()
                            onRegenerate()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                Text("Regenerate")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    Text(message.createdAt, style: .time)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
                }
                .padding(.horizontal, 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI Assistant: \(message.content)")
        .accessibilityHint("Double tap and hold for options to copy or regenerate")
    }
}


// MARK: - Preview

#Preview {
    // Create a sample message for preview
    let sampleMessage = Message(
        id: 1,
        conversationId: 1,
        senderId: nil,
        authorType: "ai",
        content: "Here's a helpful response with some code:\n\n```swift\nfunc example() {\n    print(\"Hello\")\n}\n```",
        createdAt: Date(),
        updatedAt: nil,
        modelUsed: "gemini-2.5-flash"
    )
    
    return VStack {
        AIMessageBubble(
            message: sampleMessage,
            onCopy: {},
            onRegenerate: {}
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
    .environment(ThemeManager.shared)
}

