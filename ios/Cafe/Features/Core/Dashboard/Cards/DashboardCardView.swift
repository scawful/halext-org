//
//  DashboardCardView.swift
//  Cafe
//
//  Reusable card wrapper for dashboard widgets
//

import SwiftUI

struct DashboardCardView<Content: View>: View {
    let card: DashboardCard
    let onConfigure: (() -> Void)?
    let onRemove: (() -> Void)?
    let isEditMode: Bool
    let showDragHandle: Bool
    let isDragging: Bool
    @ViewBuilder let content: () -> Content

    init(
        card: DashboardCard,
        isEditMode: Bool = false,
        showDragHandle: Bool = false,
        isDragging: Bool = false,
        onConfigure: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.card = card
        self.isEditMode = isEditMode
        self.showDragHandle = showDragHandle
        self.isDragging = isDragging
        self.onConfigure = onConfigure
        self.onRemove = onRemove
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Drag handle
                if showDragHandle && isEditMode {
                    HStack {
                        Spacer()
                        DragHandle()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
                
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeManager.shared.cardBackgroundColor)
                    .shadow(color: .black.opacity(isEditMode ? 0.1 : 0.05), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isDragging ? card.type.color : (isEditMode ? card.type.color.opacity(0.5) : Color.clear),
                        lineWidth: isDragging ? 3 : 2
                    )
            )

            if isEditMode && !isDragging {
                HStack(spacing: 8) {
                    if let onConfigure = onConfigure {
                        Button(action: onConfigure) {
                            Image(systemName: "gearshape.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 2)
                        }
                        .accessibilityLabel("Configure \(card.type.displayName)")
                        .accessibilityHint("Opens settings to customize this card")
                    }

                    if let onRemove = onRemove {
                        Button(action: onRemove) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.red))
                                .shadow(radius: 2)
                        }
                        .accessibilityLabel("Remove \(card.type.displayName)")
                        .accessibilityHint("Removes this card from the dashboard")
                    }
                }
                .offset(x: 8, y: -8)
            }
        }
    }
}

// MARK: - Drag Handle

struct DragHandle: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 3, height: 12)
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Drag handle")
        .accessibilityHint("Use drag gesture to reorder this card")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

// MARK: - Card Header

struct CardHeader: View {
    let icon: String
    let title: String
    let color: Color
    let badge: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        color: Color,
        badge: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.color = color
        self.badge = badge
        self.action = action
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)

            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let action = action {
                Button(action: action) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Empty Card State

struct EmptyCardState: View {
    @Environment(ThemeManager.self) var themeManager

    let icon: String
    let message: String
    var suggestion: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var accentColor: Color = .secondary

    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Animated background circle
                Circle()
                    .fill(accentColor.opacity(0.08))
                    .frame(width: 56, height: 56)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor.opacity(0.7), accentColor.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)

                if let suggestion = suggestion {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)

                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor.opacity(0.8))
                    }
                }
            }

            if let actionTitle = actionTitle, let action = action {
                Button {
                    HapticManager.selection()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                        )
                }
                .cardPressAnimation(scale: 0.95)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

// MARK: - Enhanced Empty Card State for specific contexts

struct TaskEmptyCardState: View {
    var onAddTask: (() -> Void)? = nil

    var body: some View {
        EmptyCardState(
            icon: "checkmark.circle",
            message: "No tasks here",
            suggestion: "Stay productive by planning ahead",
            actionTitle: onAddTask != nil ? "Add Task" : nil,
            action: onAddTask,
            accentColor: .blue
        )
    }
}

struct EventEmptyCardState: View {
    var onAddEvent: (() -> Void)? = nil

    var body: some View {
        EmptyCardState(
            icon: "calendar.badge.plus",
            message: "No upcoming events",
            suggestion: "Schedule something fun",
            actionTitle: onAddEvent != nil ? "Add Event" : nil,
            action: onAddEvent,
            accentColor: .purple
        )
    }
}

struct OverdueEmptyCardState: View {
    var body: some View {
        EmptyCardState(
            icon: "checkmark.seal.fill",
            message: "All caught up!",
            suggestion: "Great job staying on top of things",
            accentColor: .green
        )
    }
}
