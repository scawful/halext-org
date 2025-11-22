//
//  FocusManager.swift
//  Cafe
//
//  Focus management for VoiceOver and keyboard navigation
//

import SwiftUI
import Combine

@MainActor
class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var currentFocus: String?
    @Published var focusHistory: [String] = []
    
    private init() {}
    
    func setFocus(_ identifier: String) {
        currentFocus = identifier
        focusHistory.append(identifier)
        if focusHistory.count > 10 {
            focusHistory.removeFirst()
        }
    }
    
    func clearFocus() {
        currentFocus = nil
    }
    
    func announce(_ message: String) {
        // Post notification for VoiceOver announcements
        NotificationCenter.default.post(
            name: .accessibilityAnnouncement,
            object: nil,
            userInfo: ["message": message]
        )
    }
}

extension Notification.Name {
    static let accessibilityAnnouncement = Notification.Name("accessibilityAnnouncement")
}

// MARK: - Focus Modifier

struct FocusModifier: ViewModifier {
    let identifier: String
    @ObservedObject private var focusManager = FocusManager.shared
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement()
            .accessibilityIdentifier(identifier)
            .onAppear {
                if focusManager.currentFocus == identifier {
                    // Focus this element when it appears
                    UIAccessibility.post(notification: .screenChanged, argument: nil)
                }
            }
    }
}

extension View {
    func focusIdentifier(_ identifier: String) -> some View {
        modifier(FocusModifier(identifier: identifier))
    }
}

// MARK: - Keyboard Navigation

struct KeyboardNavigationModifier: ViewModifier {
    let onArrowUp: (() -> Void)?
    let onArrowDown: (() -> Void)?
    let onArrowLeft: (() -> Void)?
    let onArrowRight: (() -> Void)?
    let onEnter: (() -> Void)?
    let onEscape: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onKeyPress(.upArrow) {
                onArrowUp?()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onArrowDown?()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                onArrowLeft?()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onArrowRight?()
                return .handled
            }
            .onKeyPress(.return) {
                onEnter?()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }
}

extension View {
    func keyboardNavigation(
        arrowUp: (() -> Void)? = nil,
        arrowDown: (() -> Void)? = nil,
        arrowLeft: (() -> Void)? = nil,
        arrowRight: (() -> Void)? = nil,
        enter: (() -> Void)? = nil,
        escape: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardNavigationModifier(
            onArrowUp: arrowUp,
            onArrowDown: arrowDown,
            onArrowLeft: arrowLeft,
            onArrowRight: arrowRight,
            onEnter: enter,
            onEscape: escape
        ))
    }
}

// MARK: - Accessibility Announcement View Modifier

struct AccessibilityAnnouncementModifier: ViewModifier {
    @State private var announcement: String?
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .accessibilityAnnouncement)) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    announcement = message
                    // Trigger VoiceOver announcement
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIAccessibility.post(notification: .announcement, argument: message)
                        announcement = nil
                    }
                }
            }
    }
}

extension View {
    func accessibilityAnnouncements() -> some View {
        modifier(AccessibilityAnnouncementModifier())
    }
}

// MARK: - Focus State Helper

struct FocusStateHelper: ViewModifier {
    @FocusState.Binding var isFocused: Bool
    let identifier: String
    @ObservedObject private var focusManager = FocusManager.shared
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    focusManager.setFocus(identifier)
                }
            }
            .onChange(of: focusManager.currentFocus) { _, newFocus in
                if newFocus == identifier {
                    isFocused = true
                }
            }
    }
}

extension View {
    func managedFocus(_ binding: FocusState<Bool>.Binding, identifier: String) -> some View {
        modifier(FocusStateHelper(isFocused: binding, identifier: identifier))
    }
}

