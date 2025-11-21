//
//  DashboardModels.swift
//  Cafe
//
//  Models for configurable dashboard system
//

import Foundation
import SwiftUI

// MARK: - Card Type

enum DashboardCardType: String, Codable, CaseIterable, Identifiable {
    case welcome
    case aiGenerator
    case todayTasks
    case upcomingTasks
    case overdueTasks
    case tasksStats
    case calendar
    case upcomingEvents
    case quickActions
    case weather
    case recentActivity
    case notes
    case aiSuggestions
    case socialActivity
    case mealPlanning
    case iosFeatures
    case allApps
    case customList

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .welcome: return "Welcome Header"
        case .aiGenerator: return "AI Generator"
        case .todayTasks: return "Today's Tasks"
        case .upcomingTasks: return "Upcoming Tasks"
        case .overdueTasks: return "Overdue Tasks"
        case .tasksStats: return "Task Statistics"
        case .calendar: return "Calendar"
        case .upcomingEvents: return "Upcoming Events"
        case .quickActions: return "Quick Actions"
        case .weather: return "Weather"
        case .recentActivity: return "Recent Activity"
        case .notes: return "Notes"
        case .aiSuggestions: return "AI Suggestions"
        case .socialActivity: return "Social Activity"
        case .mealPlanning: return "Meal Planning"
        case .iosFeatures: return "iOS Features"
        case .allApps: return "All Apps"
        case .customList: return "Custom List"
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "hand.wave.fill"
        case .aiGenerator: return "sparkles"
        case .todayTasks: return "checkmark.circle.fill"
        case .upcomingTasks: return "calendar.badge.clock"
        case .overdueTasks: return "exclamationmark.triangle.fill"
        case .tasksStats: return "chart.bar.fill"
        case .calendar: return "calendar"
        case .upcomingEvents: return "calendar.badge.plus"
        case .quickActions: return "bolt.fill"
        case .weather: return "cloud.sun.fill"
        case .recentActivity: return "clock.arrow.circlepath"
        case .notes: return "note.text"
        case .aiSuggestions: return "brain.head.profile"
        case .socialActivity: return "person.2.fill"
        case .mealPlanning: return "fork.knife"
        case .iosFeatures: return "applelogo"
        case .allApps: return "square.grid.2x2"
        case .customList: return "list.bullet"
        }
    }

    var color: Color {
        switch self {
        case .welcome: return .orange
        case .aiGenerator: return .purple
        case .todayTasks: return .blue
        case .upcomingTasks: return .cyan
        case .overdueTasks: return .red
        case .tasksStats: return .green
        case .calendar: return .purple
        case .upcomingEvents: return .indigo
        case .quickActions: return .orange
        case .weather: return .cyan
        case .recentActivity: return .gray
        case .notes: return .yellow
        case .aiSuggestions: return .pink
        case .socialActivity: return .teal
        case .mealPlanning: return .orange
        case .iosFeatures: return .blue
        case .allApps: return .blue
        case .customList: return .green
        }
    }

    var defaultSize: CardSize {
        switch self {
        case .welcome, .aiGenerator: return .large
        case .tasksStats, .quickActions: return .medium
        case .allApps, .iosFeatures, .mealPlanning: return .large
        default: return .medium
        }
    }

    var description: String {
        switch self {
        case .welcome: return "Greeting and date"
        case .aiGenerator: return "Quick access to AI task generator"
        case .todayTasks: return "Tasks due today"
        case .upcomingTasks: return "Tasks for this week"
        case .overdueTasks: return "Past due tasks"
        case .tasksStats: return "Completion statistics"
        case .calendar: return "Calendar view"
        case .upcomingEvents: return "Next 7 days events"
        case .quickActions: return "Common actions"
        case .weather: return "Current weather"
        case .recentActivity: return "Recent updates"
        case .notes: return "Quick notes"
        case .aiSuggestions: return "AI-powered tips"
        case .socialActivity: return "Activity feed"
        case .mealPlanning: return "Recipe ideas and meal plans"
        case .iosFeatures: return "Discover iOS features"
        case .allApps: return "App grid"
        case .customList: return "Custom task list"
        }
    }
}

// MARK: - Card Size

enum CardSize: String, Codable {
    case small
    case medium
    case large

    var gridColumns: Int {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .large: return 2
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Dashboard Card

struct DashboardCard: Identifiable, Codable, Equatable {
    let id: UUID
    let type: DashboardCardType
    var size: CardSize
    var position: Int
    var isVisible: Bool
    var configuration: CardConfiguration

    init(
        id: UUID = UUID(),
        type: DashboardCardType,
        size: CardSize? = nil,
        position: Int,
        isVisible: Bool = true,
        configuration: CardConfiguration = CardConfiguration()
    ) {
        self.id = id
        self.type = type
        self.size = size ?? type.defaultSize
        self.position = position
        self.isVisible = isVisible
        self.configuration = configuration
    }

    static func == (lhs: DashboardCard, rhs: DashboardCard) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Card Configuration

struct CardConfiguration: Codable {
    // General
    var showHeader: Bool
    var autoHideWhenEmpty: Bool

    // Tasks
    var maxTasksToShow: Int
    var taskFilterProjectId: Int?
    var taskFilterLabelIds: [Int]
    var showCompletedTasks: Bool

    // Events
    var maxEventsToShow: Int
    var calendarDaysAhead: Int

    // Custom list
    var customListTitle: String?
    var customListItemIds: [Int]

    // Time-based behavior
    var showOnlyAtTime: TimeRange?

    init(
        showHeader: Bool = true,
        autoHideWhenEmpty: Bool = true,
        maxTasksToShow: Int = 5,
        taskFilterProjectId: Int? = nil,
        taskFilterLabelIds: [Int] = [],
        showCompletedTasks: Bool = false,
        maxEventsToShow: Int = 3,
        calendarDaysAhead: Int = 7,
        customListTitle: String? = nil,
        customListItemIds: [Int] = [],
        showOnlyAtTime: TimeRange? = nil
    ) {
        self.showHeader = showHeader
        self.autoHideWhenEmpty = autoHideWhenEmpty
        self.maxTasksToShow = maxTasksToShow
        self.taskFilterProjectId = taskFilterProjectId
        self.taskFilterLabelIds = taskFilterLabelIds
        self.showCompletedTasks = showCompletedTasks
        self.maxEventsToShow = maxEventsToShow
        self.calendarDaysAhead = calendarDaysAhead
        self.customListTitle = customListTitle
        self.customListItemIds = customListItemIds
        self.showOnlyAtTime = showOnlyAtTime
    }
}

// MARK: - Time Range

struct TimeRange: Codable {
    var startHour: Int
    var endHour: Int

    var isCurrentlyActive: Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        return currentHour >= startHour && currentHour < endHour
    }
}

// MARK: - Dashboard Layout

struct DashboardLayout: Identifiable, Codable {
    var id: UUID
    var name: String
    var cards: [DashboardCard]
    var isDefault: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        cards: [DashboardCard],
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.cards = cards
        self.isDefault = isDefault
        self.createdAt = createdAt
    }

    // MARK: - Preset Layouts

    static var defaultLayout: DashboardLayout {
        DashboardLayout(
            name: "Default",
            cards: [
                DashboardCard(type: .welcome, position: 0),
                DashboardCard(type: .aiGenerator, position: 1),
                DashboardCard(type: .tasksStats, position: 2),
                DashboardCard(type: .todayTasks, position: 3),
                DashboardCard(type: .upcomingEvents, position: 4),
                DashboardCard(type: .mealPlanning, position: 5),
                DashboardCard(type: .quickActions, position: 6),
                DashboardCard(type: .allApps, position: 7)
            ],
            isDefault: true
        )
    }

    static var focusLayout: DashboardLayout {
        DashboardLayout(
            name: "Focus",
            cards: [
                DashboardCard(type: .welcome, position: 0),
                DashboardCard(type: .todayTasks, size: .large, position: 1),
                DashboardCard(type: .overdueTasks, position: 2),
                DashboardCard(type: .tasksStats, position: 3),
                DashboardCard(type: .quickActions, position: 4)
            ]
        )
    }

    static var overviewLayout: DashboardLayout {
        DashboardLayout(
            name: "Overview",
            cards: [
                DashboardCard(type: .welcome, position: 0),
                DashboardCard(type: .tasksStats, position: 1),
                DashboardCard(type: .todayTasks, position: 2),
                DashboardCard(type: .upcomingTasks, position: 3),
                DashboardCard(type: .upcomingEvents, position: 4),
                DashboardCard(type: .recentActivity, position: 5),
                DashboardCard(type: .aiSuggestions, position: 6),
                DashboardCard(type: .allApps, position: 7)
            ]
        )
    }

    static var socialLayout: DashboardLayout {
        DashboardLayout(
            name: "Social",
            cards: [
                DashboardCard(type: .welcome, position: 0),
                DashboardCard(type: .socialActivity, size: .large, position: 1),
                DashboardCard(type: .recentActivity, position: 2),
                DashboardCard(type: .todayTasks, position: 3),
                DashboardCard(type: .upcomingEvents, position: 4),
                DashboardCard(type: .quickActions, position: 5)
            ]
        )
    }

    static var allPresets: [DashboardLayout] {
        [defaultLayout, focusLayout, overviewLayout, socialLayout]
    }
}
