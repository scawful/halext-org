//
//  AdvancedShortcuts.swift
//  Cafe
//
//  Advanced Siri Shortcuts actions
//

import Foundation
import AppIntents

// MARK: - Search Tasks Intent

struct SearchTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Tasks"
    static var description = IntentDescription("Search for tasks by keyword")

    @Parameter(title: "Search Query")
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<[TaskEntity]> {
        let tasks = try await APIClient.shared.getTasks()

        let filtered = tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(query) ||
            (task.description?.localizedCaseInsensitiveContains(query) ?? false)
        }

        let entities = filtered.map { task in
            TaskEntity(
                id: task.id,
                title: task.title,
                completed: task.completed,
                dueDate: task.dueDate
            )
        }

        return .result(value: entities)
    }
}

// MARK: - Complete Task Intent

struct CompleteTaskByNameIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task by Name"
    static var description = IntentDescription("Mark a task as complete by searching for its name")

    @Parameter(title: "Task Name")
    var taskName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let tasks = try await APIClient.shared.getTasks()

        // Find matching task
        guard let task = tasks.first(where: {
            $0.title.localizedCaseInsensitiveContains(taskName)
        }) else {
            return .result(dialog: "No task found matching '\(taskName)'")
        }

        // Complete the task
        _ = try await APIClient.shared.updateTask(id: task.id, completed: true)

        return .result(dialog: "Marked '\(task.title)' as complete")
    }
}

// MARK: - Get Tasks Count Intent

struct GetTasksCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Tasks Count"
    static var description = IntentDescription("Get count of tasks by status")

    @Parameter(title: "Status")
    var status: TaskStatus

    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        let tasks = try await APIClient.shared.getTasks()

        let count: Int
        let message: String

        switch status {
        case .all:
            count = tasks.count
            message = "You have \(count) total tasks"

        case .incomplete:
            count = tasks.filter { !$0.completed }.count
            message = "You have \(count) incomplete tasks"

        case .completed:
            count = tasks.filter { $0.completed }.count
            message = "You have completed \(count) tasks"

        case .overdue:
            let now = Date()
            count = tasks.filter { task in
                !task.completed &&
                task.dueDate != nil &&
                task.dueDate! < now
            }.count
            message = "You have \(count) overdue tasks"

        case .today:
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            count = tasks.filter { task in
                !task.completed &&
                task.dueDate != nil &&
                task.dueDate! >= startOfToday &&
                task.dueDate! < endOfToday
            }.count
            message = "You have \(count) tasks due today"
        }

        return .result(value: count, dialog: IntentDialog(stringLiteral: message))
    }
}

enum TaskStatus: String, AppEnum {
    case all
    case incomplete
    case completed
    case overdue
    case today

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Task Status")

    static var caseDisplayRepresentations: [TaskStatus: DisplayRepresentation] = [
        .all: "All Tasks",
        .incomplete: "Incomplete",
        .completed: "Completed",
        .overdue: "Overdue",
        .today: "Due Today"
    ]
}

// MARK: - Create Multiple Tasks Intent

struct CreateMultipleTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Multiple Tasks"
    static var description = IntentDescription("Create multiple tasks from a list")

    @Parameter(title: "Task Titles", description: "One task per line")
    var taskList: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let titles = taskList.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !titles.isEmpty else {
            return .result(dialog: "No valid task titles provided")
        }

        var createdCount = 0

        for title in titles {
            let taskCreate = TaskCreate(title: title)
            do {
                _ = try await APIClient.shared.createTask(taskCreate)
                createdCount += 1
            } catch {
                print("Failed to create task: \(title)")
            }
        }

        return .result(dialog: "Created \(createdCount) of \(titles.count) tasks")
    }
}

// MARK: - Get Next Event Intent

struct GetNextEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Next Event"
    static var description = IntentDescription("Get your next upcoming event")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let events = try await APIClient.shared.getEvents()

        let now = Date()
        let upcomingEvents = events
            .filter { $0.startTime > now }
            .sorted { $0.startTime < $1.startTime }

        guard let nextEvent = upcomingEvents.first else {
            return .result(dialog: "You have no upcoming events")
        }

        let timeString = nextEvent.startTime.formatted(date: .abbreviated, time: .shortened)
        var message = "Your next event is '\(nextEvent.title)' at \(timeString)"

        if let location = nextEvent.location {
            message += " in \(location)"
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

// MARK: - Add Label to Task Intent

struct AddLabelToTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Label to Task"
    static var description = IntentDescription("Add a label to a task by name")

    @Parameter(title: "Task Name")
    var taskName: String

    @Parameter(title: "Label Name")
    var labelName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let tasks = try await APIClient.shared.getTasks()

        guard let task = tasks.first(where: {
            $0.title.localizedCaseInsensitiveContains(taskName)
        }) else {
            return .result(dialog: "No task found matching '\(taskName)'")
        }

        // Note: This would require updating the backend API to support adding labels
        // For now, just provide feedback
        return .result(dialog: "Label functionality requires backend API update")
    }
}

// MARK: - Shortcuts Provider
//
// Note: These advanced shortcuts can be added to the main CafeShortcuts provider in AppIntents.swift
// Only one AppShortcutsProvider is allowed per app. The intents above are still available
// in the Shortcuts app even without being in an AppShortcutsProvider.
