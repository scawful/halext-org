//
//  ReorderableTabBar.swift
//  Cafe
//
//  Custom tab bar overlay for long-press drag-and-drop reordering
//

import SwiftUI
import UIKit

struct ReorderableTabBar: UIViewRepresentable {
    let tabs: [NavigationTab]
    let onReorder: (Int, Int) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        return container
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Find the tab bar
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = findTabBarController(in: window.rootViewController) {
                setupLongPressGesture(on: tabBarController.tabBar)
            }
        }
    }
    
    private func findTabBarController(in viewController: UIViewController?) -> UITabBarController? {
        guard let viewController = viewController else { return nil }
        
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        for child in viewController.children {
            if let found = findTabBarController(in: child) {
                return found
            }
        }
        
        return nil
    }
    
    private func setupLongPressGesture(on tabBar: UITabBar) {
        // Remove existing gestures
        tabBar.gestureRecognizers?.forEach { gesture in
            if gesture is UILongPressGestureRecognizer {
                tabBar.removeGestureRecognizer(gesture)
            }
        }
        
        let longPress = UILongPressGestureRecognizer(target: ReorderableTabBarCoordinator(self), action: #selector(ReorderableTabBarCoordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        tabBar.addGestureRecognizer(longPress)
    }
}

class ReorderableTabBarCoordinator: NSObject {
    let parent: ReorderableTabBar
    private var draggedTabIndex: Int?
    
    init(_ parent: ReorderableTabBar) {
        self.parent = parent
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let tabBar = gesture.view as? UITabBar else { return }
        let location = gesture.location(in: tabBar)
        
        switch gesture.state {
        case .began:
            if let index = tabIndex(at: location, in: tabBar) {
                draggedTabIndex = index
                hapticFeedback(style: .medium)
                
                // Visual feedback
                if let itemView = tabBarItemView(at: index, in: tabBar) {
                    UIView.animate(withDuration: 0.2) {
                        itemView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                        itemView.alpha = 0.8
                    }
                }
            }
            
        case .changed:
            guard let draggedIndex = draggedTabIndex else { return }
            if let newIndex = tabIndex(at: location, in: tabBar), newIndex != draggedIndex {
                hapticFeedback(style: .light)
                
                // Reorder
                parent.onReorder(draggedIndex, newIndex)
                draggedTabIndex = newIndex
            }
            
        case .ended, .cancelled:
            if let index = draggedTabIndex, let itemView = tabBarItemView(at: index, in: tabBar) {
                UIView.animate(withDuration: 0.2) {
                    itemView.transform = .identity
                    itemView.alpha = 1.0
                }
            }
            draggedTabIndex = nil
            hapticFeedback(style: .light)
            
        default:
            break
        }
    }
    
    private func tabIndex(at location: CGPoint, in tabBar: UITabBar) -> Int? {
        guard let items = tabBar.items, !items.isEmpty else { return nil }
        
        let itemWidth = tabBar.bounds.width / CGFloat(items.count)
        let index = Int(location.x / itemWidth)
        
        guard index >= 0 && index < items.count else { return nil }
        return index
    }
    
    private func tabBarItemView(at index: Int, in tabBar: UITabBar) -> UIView? {
        guard let items = tabBar.items, index < items.count else { return nil }
        
        // Find the tab bar item view
        for subview in tabBar.subviews {
            if let itemView = findItemView(for: items[index], in: subview) {
                return itemView
            }
        }
        
        return nil
    }
    
    private func findItemView(for item: UITabBarItem, in view: UIView) -> UIView? {
        // This is a simplified approach - in production, you'd need to traverse the view hierarchy
        if view.subviews.isEmpty {
            return view
        }
        
        for subview in view.subviews {
            if let found = findItemView(for: item, in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    private func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// SwiftUI-friendly wrapper
struct ReorderableTabBarOverlay: View {
    let tabs: [NavigationTab]
    let onReorder: (Int, Int) -> Void
    
    var body: some View {
        ReorderableTabBar(tabs: tabs, onReorder: onReorder)
            .frame(height: 0)
            .allowsHitTesting(false)
    }
}

