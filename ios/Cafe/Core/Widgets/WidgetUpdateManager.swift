//
//  WidgetUpdateManager.swift
//  Cafe
//
//  Updates widget data when tasks/events change in main app
//

import Foundation
import WidgetKit

class WidgetUpdateManager {
    static let shared = WidgetUpdateManager()

    private let appGroupIdentifier = "group.org.halext.cafe"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Update Widget Data

    func updateTasks(_ tasks: [Task]) {
        let widgetTasks = tasks.map { task in
            WidgetTask(
                id: task.id,
                title: task.title,
                description: task.description,
                completed: task.completed,
                dueDate: task.dueDate,
                createdAt: task.createdAt,
                labels: task.labels.map { label in
                    WidgetLabel(id: label.id, name: label.name, color: label.color)
                }
            )
        }

        guard let userDefaults = userDefaults,
              let encoded = try? JSONEncoder().encode(widgetTasks) else {
            return
        }

        userDefaults.set(encoded, forKey: "cachedTasks")
        userDefaults.set(Date(), forKey: "lastUpdate")

        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()

        print("📱 Widget data updated: \(tasks.count) tasks")
    }

    func updateEvents(_ events: [Event]) {
        let widgetEvents = events.map { event in
            WidgetEvent(
                id: event.id,
                title: event.title,
                startTime: event.startTime,
                endTime: event.endTime,
                location: event.location
            )
        }

        guard let userDefaults = userDefaults,
              let encoded = try? JSONEncoder().encode(widgetEvents) else {
            return
        }

        userDefaults.set(encoded, forKey: "cachedEvents")
        userDefaults.set(Date(), forKey: "lastUpdate")

        // Reload all widgets
        WidgetCenter.shared.reloadAllTimelines()

        print("📱 Widget data updated: \(events.count) events")
    }

    func updateAll(tasks: [Task], events: [Event]) {
        updateTasks(tasks)
        updateEvents(events)
    }

    // MARK: - Reload Specific Widgets

    func reloadTaskWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "TodaysTasksWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskCountWidget")
    }

    func reloadEventWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "CalendarWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "NextEventWidget")
    }
}

// MARK: - Widget Models (Matching Widget Extension)

struct WidgetTask: Codable {
    let id: Int
    let title: String
    let description: String?
    let completed: Bool
    let dueDate: Date?
    let createdAt: Date
    let labels: [WidgetLabel]
}

struct WidgetEvent: Codable {
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
