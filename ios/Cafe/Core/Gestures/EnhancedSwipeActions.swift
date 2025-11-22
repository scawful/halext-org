//
//  EnhancedSwipeActions.swift
//  Cafe
//
//  Enhanced swipe action utilities and components
//

import SwiftUI

// MARK: - Swipe Action Configuration

struct SwipeActionConfig {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let allowsFullSwipe: Bool
    let role: ButtonRole?
    
    init(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void,
        allowsFullSwipe: Bool = false,
        role: ButtonRole? = nil
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
        self.allowsFullSwipe = allowsFullSwipe
        self.role = role
    }
}

// MARK: - Enhanced Swipe Actions View Modifier

struct EnhancedSwipeActionsModifier: ViewModifier {
    let leadingActions: [SwipeActionConfig]
    let trailingActions: [SwipeActionConfig]
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: trailingActions.first?.allowsFullSwipe ?? false) {
                ForEach(Array(trailingActions.enumerated()), id: \.offset) { index, action in
                    Button(role: action.role, action: {
                        HapticManager.selection()
                        action.action()
                    }) {
                        SwiftUI.Label(action.title, systemImage: action.icon)
                    }
                    .tint(action.color)
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: leadingActions.first?.allowsFullSwipe ?? false) {
                ForEach(Array(leadingActions.enumerated()), id: \.offset) { index, action in
                    Button(role: action.role, action: {
                        HapticManager.selection()
                        action.action()
                    }) {
                        SwiftUI.Label(action.title, systemImage: action.icon)
                    }
                    .tint(action.color)
                }
            }
    }
}

extension View {
    func enhancedSwipeActions(
        leading: [SwipeActionConfig] = [],
        trailing: [SwipeActionConfig] = []
    ) -> some View {
        modifier(EnhancedSwipeActionsModifier(leadingActions: leading, trailingActions: trailing))
    }
}

