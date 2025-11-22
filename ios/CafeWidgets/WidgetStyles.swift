//
//  WidgetStyles.swift
//  CafeWidgets
//
//  Shared design system for consistent widget styling
//

import SwiftUI
import WidgetKit

// MARK: - Widget Color Palette

enum WidgetColors {
    // Primary brand colors
    static let primaryBlue = Color.blue
    static let primaryPurple = Color.purple
    static let primaryOrange = Color.orange
    static let primaryGreen = Color.green

    // Semantic colors
    static let taskColor = Color.blue
    static let eventColor = Color.purple
    static let aiColor = Color.orange
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let overdueColor = Color.red

    // Background colors with opacity for cards
    static let taskBackground = Color.blue.opacity(0.12)
    static let eventBackground = Color.purple.opacity(0.12)
    static let aiBackground = Color.orange.opacity(0.12)
    static let successBackground = Color.green.opacity(0.08)

    // Gradient definitions
    static let primaryGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let taskGradient = LinearGradient(
        colors: [Color.blue, Color.blue.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let eventGradient = LinearGradient(
        colors: [Color.purple, Color.purple.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography Styles

enum WidgetTypography {
    // Widget title - bold, prominent
    static func title(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
    }

    // Subtitle - medium weight, secondary importance
    static func subtitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
    }

    // Caption - small, supporting text
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    // Large number display
    static func largeNumber(_ value: Int, color: Color = .blue) -> some View {
        Text("\(value)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundStyle(color)
    }

    // Medium number display
    static func mediumNumber(_ value: Int, color: Color = .blue) -> some View {
        Text("\(value)")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundStyle(color)
    }
}

// MARK: - Widget Header Component

struct WidgetHeader: View {
    let icon: String
    let title: String
    let iconColor: Color
    var count: Int? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            if let count = count {
                Text("\(count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.12))
                    )
            }
        }
    }
}

// MARK: - Empty State Component

struct WidgetEmptyState: View {
    let icon: String
    let message: String
    let iconColor: Color
    var detailMessage: String? = nil
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: isCompact ? 6 : 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: isCompact ? 44 : 60, height: isCompact ? 44 : 60)

                Image(systemName: icon)
                    .font(.system(size: isCompact ? 20 : 28, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(spacing: 4) {
                Text(message)
                    .font(isCompact ? .caption : .subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let detail = detailMessage, !isCompact {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Date Badge Component

struct WidgetDateBadge: View {
    let date: Date
    var accentColor: Color = WidgetColors.eventColor
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: isCompact ? 0 : 2) {
            Text(date, format: .dateTime.month(.abbreviated))
                .font(.system(size: isCompact ? 9 : 10, weight: .semibold))
                .foregroundStyle(accentColor)
                .textCase(.uppercase)

            Text(date, format: .dateTime.day())
                .font(.system(size: isCompact ? 14 : 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: isCompact ? 36 : 44, height: isCompact ? 36 : 44)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 8 : 10, style: .continuous)
                .fill(accentColor.opacity(0.12))
        )
    }
}

// MARK: - Task Indicator Component

struct TaskIndicator: View {
    let isCompleted: Bool
    var accentColor: Color = WidgetColors.taskColor

    var body: some View {
        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isCompleted ? WidgetColors.successColor : accentColor)
    }
}

// MARK: - Time Badge Component

struct TimeBadge: View {
    let date: Date
    var isOverdue: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock")
                .font(.system(size: 9, weight: .medium))

            Text(date, style: .time)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(isOverdue ? WidgetColors.overdueColor : .secondary)
    }
}

// MARK: - Location Badge Component

struct LocationBadge: View {
    let location: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.system(size: 8, weight: .medium))

            Text(location)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Count Badge Component

struct CountBadge: View {
    let count: Int
    var color: Color = WidgetColors.taskColor

    var body: some View {
        Text("\(count)")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(
                Circle()
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            )
    }
}

// MARK: - View Modifiers

struct WidgetCardStyle: ViewModifier {
    var backgroundColor: Color = Color.secondary.opacity(0.08)
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
    }
}

struct WidgetActionButtonStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - View Extensions

extension View {
    func widgetCardStyle(backgroundColor: Color = Color.secondary.opacity(0.08), cornerRadius: CGFloat = 12) -> some View {
        modifier(WidgetCardStyle(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }

    func widgetActionButtonStyle(color: Color) -> some View {
        modifier(WidgetActionButtonStyle(color: color))
    }
}

// MARK: - Preview Support

struct WidgetStylesPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            WidgetHeader(icon: "checkmark.circle.fill", title: "Today's Tasks", iconColor: .blue, count: 5)

            WidgetEmptyState(
                icon: "checkmark.circle",
                message: "All Done!",
                iconColor: .green,
                detailMessage: "You've completed all tasks for today"
            )

            HStack(spacing: 12) {
                WidgetDateBadge(date: Date())
                WidgetDateBadge(date: Date(), isCompact: true)
                CountBadge(count: 7)
            }

            HStack(spacing: 12) {
                TaskIndicator(isCompleted: false)
                TaskIndicator(isCompleted: true)
                TimeBadge(date: Date())
                LocationBadge(location: "Office")
            }
        }
        .padding()
    }
}

#Preview {
    WidgetStylesPreview()
}
