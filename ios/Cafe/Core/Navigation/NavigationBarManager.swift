//
//  NavigationBarManager.swift
//  Cafe
//
//  Manages customizable bottom navigation bar
//

import SwiftUI

@MainActor
@Observable
class NavigationBarManager {
    static let shared = NavigationBarManager()

    private(set) var visibleTabs: [NavigationTab]
    private let userDefaults = UserDefaults.standard
    private let visibleTabsKey = "visibleNavigationTabs"

    var maxTabs: Int = 5
    var minTabs: Int = 3

    private init() {
        // Load saved tabs or use defaults
        if let savedData = userDefaults.data(forKey: visibleTabsKey),
           let savedTabs = try? JSONDecoder().decode([NavigationTab].self, from: savedData) {
            self.visibleTabs = savedTabs
        } else {
            self.visibleTabs = NavigationTab.defaultTabs
        }
    }

    // MARK: - Tab Management

    func updateVisibleTabs(_ tabs: [NavigationTab]) {
        guard tabs.count >= minTabs && tabs.count <= maxTabs else {
            print("❌ Tab count must be between \(minTabs) and \(maxTabs)")
            return
        }

        visibleTabs = tabs
        saveTabs()
    }

    func addTab(_ tab: NavigationTab) {
        guard !visibleTabs.contains(tab) else { return }
        guard visibleTabs.count < maxTabs else {
            print("❌ Cannot add more than \(maxTabs) tabs")
            return
        }

        visibleTabs.append(tab)
        saveTabs()
    }

    func removeTab(_ tab: NavigationTab) {
        guard visibleTabs.count > minTabs else {
            print("❌ Cannot have fewer than \(minTabs) tabs")
            return
        }

        visibleTabs.removeAll { $0 == tab }
        saveTabs()
    }

    func moveTab(from source: IndexSet, to destination: Int) {
        visibleTabs.move(fromOffsets: source, toOffset: destination)
        saveTabs()
    }

    func resetToDefaults() {
        visibleTabs = NavigationTab.defaultTabs
        saveTabs()
    }

    func applyPreset(_ preset: NavigationPreset) {
        visibleTabs = preset.tabs
        saveTabs()
    }

    func saveCustomLayout(name: String) {
        let layout = CustomLayout(name: name, tabs: visibleTabs)
        var layouts = loadCustomLayouts()
        layouts.append(layout)

        if let data = try? JSONEncoder().encode(layouts) {
            userDefaults.set(data, forKey: "customNavigationLayouts")
            print("✅ Saved custom layout: \(name)")
        }
    }

    func loadCustomLayouts() -> [CustomLayout] {
        guard let data = userDefaults.data(forKey: "customNavigationLayouts"),
              let layouts = try? JSONDecoder().decode([CustomLayout].self, from: data) else {
            return []
        }
        return layouts
    }

    func deleteCustomLayout(_ layout: CustomLayout) {
        var layouts = loadCustomLayouts()
        layouts.removeAll { $0.id == layout.id }

        if let data = try? JSONEncoder().encode(layouts) {
            userDefaults.set(data, forKey: "customNavigationLayouts")
            print("✅ Deleted custom layout: \(layout.name)")
        }
    }

    func applyCustomLayout(_ layout: CustomLayout) {
        visibleTabs = layout.tabs
        saveTabs()
    }

    // MARK: - Persistence

    private func saveTabs() {
        if let data = try? JSONEncoder().encode(visibleTabs) {
            userDefaults.set(data, forKey: visibleTabsKey)
            print("✅ Saved \(visibleTabs.count) navigation tabs")
        }
    }

    // MARK: - Helpers

    var availableTabs: [NavigationTab] {
        NavigationTab.allCases.filter { !visibleTabs.contains($0) }
    }

    func isTabVisible(_ tab: NavigationTab) -> Bool {
        visibleTabs.contains(tab)
    }
}

// MARK: - Navigation Presets

struct NavigationPreset: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let tabs: [NavigationTab]
    let icon: String

    static let allPresets: [NavigationPreset] = [
        NavigationPreset(
            name: "Productivity",
            description: "Focus on tasks and organization",
            tabs: [.dashboard, .tasks, .calendar, .templates, .more],
            icon: "checkmark.circle.fill"
        ),
        NavigationPreset(
            name: "Communication",
            description: "Stay connected with your team",
            tabs: [.dashboard, .messages, .chat, .calendar, .more],
            icon: "bubble.left.and.bubble.right.fill"
        ),
        NavigationPreset(
            name: "Financial",
            description: "Manage money and budgets",
            tabs: [.dashboard, .finance, .tasks, .calendar, .more],
            icon: "dollarsign.circle.fill"
        ),
        NavigationPreset(
            name: "Minimal",
            description: "Just the essentials",
            tabs: [.dashboard, .tasks, .more],
            icon: "minus.circle.fill"
        ),
        NavigationPreset(
            name: "Advanced",
            description: "Power user features",
            tabs: [.dashboard, .smartLists, .templates, .pages, .more],
            icon: "star.fill"
        )
    ]
}

// MARK: - Custom Layout

struct CustomLayout: Identifiable, Codable {
    let id: UUID
    let name: String
    let tabs: [NavigationTab]
    let createdAt: Date

    init(name: String, tabs: [NavigationTab]) {
        self.id = UUID()
        self.name = name
        self.tabs = tabs
        self.createdAt = Date()
    }
}

// MARK: - Navigation Tab

enum NavigationTab: String, Codable, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case tasks = "Tasks"
    case calendar = "Calendar"
    case chat = "AI Chat"
    case finance = "Finance"
    case settings = "Settings"
    case templates = "Templates"
    case smartLists = "Smart Lists"
    case pages = "Pages"
    case messages = "Messages"
    case more = "More"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .tasks: return "checkmark.circle"
        case .calendar: return "calendar"
        case .chat: return "bubble.left.and.bubble.right"
        case .finance: return "dollarsign.circle"
        case .settings: return "gear"
        case .templates: return "doc.text"
        case .smartLists: return "line.3.horizontal.decrease.circle"
        case .pages: return "doc.on.doc"
        case .messages: return "message"
        case .more: return "ellipsis.circle"
        }
    }

    var filledIcon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .tasks: return "checkmark.circle.fill"
        case .calendar: return "calendar"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .finance: return "dollarsign.circle.fill"
        case .settings: return "gear"
        case .templates: return "doc.text.fill"
        case .smartLists: return "line.3.horizontal.decrease.circle.fill"
        case .pages: return "doc.on.doc.fill"
        case .messages: return "message.fill"
        case .more: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .tasks: return .green
        case .calendar: return .orange
        case .chat: return .purple
        case .finance: return .mint
        case .settings: return .gray
        case .templates: return .indigo
        case .smartLists: return .teal
        case .pages: return .pink
        case .messages: return .cyan
        case .more: return .secondary
        }
    }

    var description: String {
        switch self {
        case .dashboard: return "Overview of tasks and events"
        case .tasks: return "Manage your tasks"
        case .calendar: return "View and schedule events"
        case .chat: return "AI assistant for productivity"
        case .finance: return "Financial management and budgets"
        case .settings: return "App settings and preferences"
        case .templates: return "Task templates library"
        case .smartLists: return "Custom filtered views"
        case .pages: return "Notes and documents"
        case .messages: return "Chat with team members"
        case .more: return "All features and options"
        }
    }

    static var defaultTabs: [NavigationTab] {
        [.dashboard, .tasks, .calendar, .chat, .more]
    }
}
