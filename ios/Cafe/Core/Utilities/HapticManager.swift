//
//  HapticManager.swift
//  Cafe
//
//  Haptic feedback utilities
//

import UIKit
import SwiftUI

enum HapticManager {
    // MARK: - Impact Feedback

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func lightImpact() {
        impact(.light)
    }

    static func mediumImpact() {
        impact(.medium)
    }

    static func heavyImpact() {
        impact(.heavy)
    }

    static func rigidImpact() {
        impact(.rigid)
    }

    static func softImpact() {
        impact(.soft)
    }

    // MARK: - Notification Feedback

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func success() {
        notification(.success)
    }

    static func warning() {
        notification(.warning)
    }

    static func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Extension

extension View {
    /// Add haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            HapticManager.impact(style)
        }
    }

    /// Add success haptic feedback
    func successHaptic() -> some View {
        self.onChange(of: UUID()) { _, _ in
            HapticManager.success()
        }
    }
}
