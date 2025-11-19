//
//  FocusFilterManager.swift
//  Cafe
//
//  Focus Mode filtering for tasks (iOS 16+)
//

import Foundation
import AppIntents
import Combine

// MARK: - Focus Filter

@available(iOS 16.0, *)
struct TaskFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Filter Tasks"
    static var description = IntentDescription("Filter tasks based on Focus mode")

    @Parameter(title: "Focus Mode")
    var focusMode: FocusMode?

    @Parameter(title: "Show Only Priority Tasks")
    var showOnlyPriority: Bool?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Filter \(focusMode?.rawValue ?? "All") Tasks")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Apply the filter
        if let focusMode = focusMode {
            await FocusFilterManager.shared.setFilter(mode: focusMode, showOnlyPriority: showOnlyPriority ?? false)
        } else {
            await FocusFilterManager.shared.clearFilter()
        }
        return .result()
    }
}

// MARK: - Focus Modes

enum FocusMode: String, AppEnum {
    case work
    case personal
    case sleep
    case driving
    case fitness
    case reading
    case gaming

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Focus Mode")

    static var caseDisplayRepresentations: [FocusMode: DisplayRepresentation] = [
        .work: "Work",
        .personal: "Personal",
        .sleep: "Sleep",
        .driving: "Driving",
        .fitness: "Fitness",
        .reading: "Reading",
        .gaming: "Gaming"
    ]
}

// MARK: - Manager

@MainActor
class FocusFilterManager: ObservableObject {
    static let shared = FocusFilterManager()

    @Published var currentFocusMode: FocusMode?
    @Published var showOnlyPriority: Bool = false

    private init() {}

    // MARK: - Set Filter

    func setFilter(mode: FocusMode, showOnlyPriority: Bool) async {
        self.currentFocusMode = mode
        self.showOnlyPriority = showOnlyPriority

        print("🎯 Focus filter updated: \(mode.rawValue), priority only: \(showOnlyPriority)")

        // Notify widgets to update
        NotificationCenter.default.post(name: .focusFilterChanged, object: nil)
    }

    func clearFilter() async {
        self.currentFocusMode = nil
        self.showOnlyPriority = false

        print("🎯 Focus filter cleared")
        NotificationCenter.default.post(name: .focusFilterChanged, object: nil)
    }

    // MARK: - Filter Tasks

    func filteredTasks(_ tasks: [Task]) -> [Task] {
        guard let focusMode = currentFocusMode else {
            return tasks
        }

        var filtered = tasks

        // Filter by focus mode based on task labels or properties
        switch focusMode {
        case .work:
            filtered = filtered.filter { task in
                task.labels.contains { $0.name.lowercased().contains("work") } ||
                task.title.lowercased().contains("work") ||
                task.title.lowercased().contains("meeting")
            }

        case .personal:
            filtered = filtered.filter { task in
                !task.labels.contains { $0.name.lowercased().contains("work") } &&
                (task.labels.contains { $0.name.lowercased().contains("personal") } ||
                 task.title.lowercased().contains("personal") ||
                 task.title.lowercased().contains("home"))
            }

        case .fitness:
            filtered = filtered.filter { task in
                task.labels.contains { $0.name.lowercased().contains("fitness") } ||
                task.labels.contains { $0.name.lowercased().contains("health") } ||
                task.title.lowercased().contains("workout") ||
                task.title.lowercased().contains("exercise")
            }

        case .reading:
            filtered = filtered.filter { task in
                task.labels.contains { $0.name.lowercased().contains("reading") } ||
                task.title.lowercased().contains("read") ||
                task.title.lowercased().contains("book")
            }

        default:
            // For other focus modes, show all non-work tasks
            filtered = filtered.filter { task in
                !task.labels.contains { $0.name.lowercased().contains("work") }
            }
        }

        // Further filter by priority if enabled
        if showOnlyPriority {
            // Filter tasks that are due soon or overdue
            let now = Date()
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: now)!

            filtered = filtered.filter { task in
                if let dueDate = task.dueDate {
                    return dueDate <= nextDay
                }
                return false
            }
        }

        return filtered
    }

    // MARK: - Get Suggested Labels for Focus Mode

    func suggestedLabels(for mode: FocusMode) -> [String] {
        switch mode {
        case .work:
            return ["work", "meeting", "project", "deadline"]
        case .personal:
            return ["personal", "home", "family", "errands"]
        case .fitness:
            return ["fitness", "health", "workout", "exercise"]
        case .reading:
            return ["reading", "book", "article", "learning"]
        case .gaming:
            return ["gaming", "entertainment", "hobby"]
        default:
            return []
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let focusFilterChanged = Notification.Name("focusFilterChanged")
}
