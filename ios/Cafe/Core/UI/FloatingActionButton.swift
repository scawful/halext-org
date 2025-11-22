//
//  FloatingActionButton.swift
//  Cafe
//
//  Floating action button component for quick actions
//

import SwiftUI

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color? = nil
    var size: CGFloat = 56
    
    @Environment(ThemeManager.self) private var themeManager
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.mediumImpact()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    (color ?? themeManager.accentColor),
                                    (color ?? themeManager.accentColor).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing)
                        )
                        .shadow(color: (color ?? themeManager.accentColor).opacity(0.4), radius: 12, x: 0, y: 6)
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .accessibilityLabel("Quick action")
        .accessibilityHint("Double tap to perform quick action")
    }
}

// MARK: - Floating Action Button with Menu

struct FloatingActionMenu: View {
    let primaryIcon: String
    let primaryAction: () -> Void
    let items: [FloatingActionItem]
    var color: Color? = nil
    
    @State private var isExpanded = false
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                ForEach(items.reversed()) { item in
                    FloatingActionItemButton(item: item, color: color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
                if !isExpanded {
                    HapticManager.mediumImpact()
                    primaryAction()
                } else {
                    HapticManager.lightImpact()
                }
            }) {
                Image(systemName: isExpanded ? "xmark" : primaryIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (color ?? themeManager.accentColor),
                                        (color ?? themeManager.accentColor).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                            .shadow(color: (color ?? themeManager.accentColor).opacity(0.4), radius: 12, x: 0, y: 6)
                    )
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
        }
    }
}

struct FloatingActionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let action: () -> Void
}

struct FloatingActionItemButton: View {
    let item: FloatingActionItem
    var color: Color? = nil
    
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            item.action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill((color ?? themeManager.accentColor).opacity(0.9))
                            .shadow(color: (color ?? themeManager.accentColor).opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                
                Text(item.title)
                    .font(.caption)
                    .foregroundColor(themeManager.textColor)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton(icon: "plus", action: {})
                    .padding()
            }
        }
    }
    .environment(ThemeManager.shared)
}

