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
    @ViewBuilder let content: () -> Content

    init(
        card: DashboardCard,
        isEditMode: Bool = false,
        onConfigure: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.card = card
        self.isEditMode = isEditMode
        self.onConfigure = onConfigure
        self.onRemove = onRemove
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
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
                    .stroke(isEditMode ? card.type.color.opacity(0.5) : Color.clear, lineWidth: 2)
            )

            if isEditMode {
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
                    }
                }
                .offset(x: 8, y: -8)
            }
        }
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
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.5))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
