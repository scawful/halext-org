//
//  LongPressMenu.swift
//  Cafe
//
//  Enhanced long-press context menu component
//

import SwiftUI

// MARK: - Long Press Menu Item

struct LongPressMenuItem {
    let title: String
    let icon: String
    let action: () -> Void
    let role: ButtonRole?
    let isDestructive: Bool
    
    init(
        title: String,
        icon: String,
        action: @escaping () -> Void,
        role: ButtonRole? = nil,
        isDestructive: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.role = role
        self.isDestructive = isDestructive
    }
}

// MARK: - Long Press Menu Modifier

struct LongPressMenuModifier: ViewModifier {
    let items: [LongPressMenuItem]
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .contextMenu {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Button(role: item.role ?? (item.isDestructive ? .destructive : nil), action: {
                        HapticManager.selection()
                        item.action()
                    }) {
                        SwiftUI.Label(item.title, systemImage: item.icon)
                    }
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onChanged { _ in
                        isPressed = true
                        HapticManager.lightImpact()
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func longPressMenu(_ items: [LongPressMenuItem]) -> some View {
        modifier(LongPressMenuModifier(items: items))
    }
}

// MARK: - Quick Action Menu

struct QuickActionMenu: View {
    let items: [LongPressMenuItem]
    @Binding var isPresented: Bool
    
    var body: some View {
        Menu {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button(role: item.role ?? (item.isDestructive ? .destructive : nil), action: {
                    HapticManager.selection()
                    item.action()
                }) {
                    SwiftUI.Label(item.title, systemImage: item.icon)
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

