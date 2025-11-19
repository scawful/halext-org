//
//  WidgetDataProvider.swift
//  CafeWidgets
//
//  Shared data provider for widgets using App Groups
//

import Foundation
import WidgetKit

class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    // App Group identifier - must match in both app and widget targets
    private let appGroupIdentifier = "group.org.halext.cafe"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Save Data (Called from Main App)

    func saveTasks(_ tasks: [WidgetTask]) {
        guard let userDefaults = userDefaults else { return }

        if let encoded = try? JSONEncoder().encode(tasks) {
            userDefaults.set(encoded, forKey: "cachedTasks")
            print("📱 Saved \(tasks.count) tasks to widget container")
        }
    }

    func saveEvents(_ events: [WidgetEvent]) {
        guard let userDefaults = userDefaults else { return }

        if let encoded = try? JSONEncoder().encode(events) {
            userDefaults.set(encoded, forKey: "cachedEvents")
            print("📱 Saved \(events.count) events to widget container")
        }
    }

    func saveLastUpdate(_ date: Date = Date()) {
        guard let userDefaults = userDefaults else { return }
        userDefaults.set(date, forKey: "lastUpdate")
    }

    // MARK: - Load Data (Called from Widgets)

    func loadTasks() -> [WidgetTask] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: "cachedTasks"),
              let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) else {
            return []
        }
        return tasks
    }

    func loadEvents() -> [WidgetEvent] {
        guard let userDefaults = userDefaults,
              let data = userDefaults.data(forKey: "cachedEvents"),
              let events = try? JSONDecoder().decode([WidgetEvent].self, from: data) else {
            return []
        }
        return events
    }

    func loadLastUpdate() -> Date? {
        guard let userDefaults = userDefaults else { return nil }
        return userDefaults.object(forKey: "lastUpdate") as? Date
    }

    // MARK: - Computed Properties

    var todaysTasks: [WidgetTask] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        return loadTasks().filter { task in
            !task.completed &&
            (task.dueDate ?? now) >= startOfToday &&
            (task.dueDate ?? now) < endOfToday
        }
    }

    var upcomingEvents: [WidgetEvent] {
        let now = Date()
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        return loadEvents()
            .filter { $0.startTime >= now && $0.startTime <= weekFromNow }
            .sorted { $0.startTime < $1.startTime }
    }

    var completedTodayCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        return loadTasks().filter { task in
            task.completed &&
            task.createdAt >= startOfToday
        }.count
    }
}

// MARK: - Widget Models

struct WidgetTask: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let completed: Bool
    let dueDate: Date?
    let createdAt: Date
    let labels: [WidgetLabel]
}

struct WidgetEvent: Codable, Identifiable {
    let id: Int
    let title: String
    let startTime: Date
    let endTime: Date
    let location: String?
}

struct WidgetLabel: Codable {
    let id: Int
    let name: String
    let color: String?
}

// MARK: - Timeline Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let events: [WidgetEvent]
    let lastUpdate: Date?
}
