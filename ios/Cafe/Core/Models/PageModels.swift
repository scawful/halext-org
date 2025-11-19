//
//  PageModels.swift
//  Cafe
//
//  Pages and layout presets models
//

import Foundation

// MARK: - Page

struct Page: Codable, Identifiable {
    let id: Int
    let ownerId: Int
    var title: String
    var content: String?
    var layout: PageLayout
    var isShared: Bool
    let createdAt: Date
    let updatedAt: Date
    var sharedWith: [PageShare]?

    var displayTitle: String {
        title.isEmpty ? "Untitled Page" : title
    }
}

struct PageCreate: Codable {
    let title: String
    let content: String?
    let layout: PageLayout?
}

struct PageUpdate: Codable {
    let title: String?
    let content: String?
    let layout: PageLayout?
}

// MARK: - Page Layout

struct PageLayout: Codable {
    var columns: Int
    var rowHeight: Int
    var gap: Int
    var widgets: [PageWidget]

    static let defaultLayout = PageLayout(
        columns: 12,
        rowHeight: 100,
        gap: 16,
        widgets: []
    )
}

struct PageWidget: Codable, Identifiable {
    let id: String
    var type: WidgetType
    var x: Int
    var y: Int
    var w: Int
    var h: Int
    var config: WidgetConfig?

    enum WidgetType: String, Codable {
        case taskList = "task-list"
        case calendar = "calendar"
        case notes = "notes"
        case chart = "chart"
        case weather = "weather"
        case clock = "clock"
        case timer = "timer"
        case habits = "habits"
        case finance = "finance"
        case custom = "custom"
    }
}

struct WidgetConfig: Codable {
    var title: String?
    var backgroundColor: String?
    var textColor: String?
    var data: [String: String]?
}

// MARK: - Page Sharing

struct PageShare: Codable, Identifiable {
    let id: Int
    let pageId: Int
    let sharedWithUserId: Int
    var permission: SharePermission
    let sharedAt: Date
    var sharedWith: User?

    enum SharePermission: String, Codable {
        case view
        case edit
    }
}

struct PageShareCreate: Codable {
    let usernames: [String]
    let permission: PageShare.SharePermission
}

// MARK: - Layout Presets

struct LayoutPreset: Codable, Identifiable {
    let id: Int
    let userId: Int
    var name: String
    var description: String?
    var layout: PageLayout
    var isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct LayoutPresetCreate: Codable {
    let name: String
    let description: String?
    let layout: PageLayout
    let isPublic: Bool
}

struct LayoutPresetUpdate: Codable {
    let name: String?
    let description: String?
    let layout: PageLayout?
    let isPublic: Bool?
}
