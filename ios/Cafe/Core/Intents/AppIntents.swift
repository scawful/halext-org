//
//  AppIntents.swift
//  Cafe
//
//  App Intents for Siri and Shortcuts integration
//

import Foundation
import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

struct CafeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "Add a task in \(.applicationName)",
                "Create task in \(.applicationName)",
                "New task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: ViewTodaysTasksIntent(),
            phrases: [
                "Show my tasks in \(.applicationName)",
                "What are my tasks in \(.applicationName)",
                "View today's tasks in \(.applicationName)"
            ],
            shortTitle: "Today's Tasks",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: CreateEventIntent(),
            phrases: [
                "Add an event in \(.applicationName)",
                "Create event in \(.applicationName)",
                "Schedule event in \(.applicationName)"
            ],
            shortTitle: "Add Event",
            systemImageName: "calendar.badge.plus"
        )

        AppShortcut(
            intent: AskAIIntent(),
            phrases: [
                "Ask AI in \(.applicationName)",
                "Chat with AI in \(.applicationName)",
                "Talk to my assistant in \(.applicationName)"
            ],
            shortTitle: "Ask AI",
            systemImageName: "sparkles"
        )
    }
}

// MARK: - Create Task Intent

struct CreateTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Task"
    static var description = IntentDescription("Create a new task in Cafe")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Task Title", requestValueDialog: "What do you want to do?")
    var title: String

    @Parameter(title: "Description", requestValueDialog: "Any additional details?")
    var taskDescription: String?

    @Parameter(title: "Due Date")
    var dueDate: Date?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Create task via API
        let taskCreate = TaskCreate(
            title: title,
            description: taskDescription,
            dueDate: dueDate,
            labels: []
        )

        do {
            let task = try await APIClient.shared.createTask(taskCreate)

            // Schedule notification if due date is set
            if let dueDate = task.dueDate {
                await NotificationManager.shared.scheduleTaskReminder(
                    taskId: task.id,
                    title: task.title,
                    dueDate: dueDate
                )
            }

            return .result(dialog: "Created task: \(task.title)")
        } catch {
            throw $title.needsValueError("Failed to create task: \(error.localizedDescription)")
        }
    }
}

// MARK: - View Today's Tasks Intent

struct ViewTodaysTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "View Today's Tasks"
    static var description = IntentDescription("View your tasks for today")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        do {
            let tasks = try await APIClient.shared.getTasks()
            let calendar = Calendar.current
            let now = Date()
            let startOfToday = calendar.startOfDay(for: now)
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

            let todaysTasks = tasks.filter { task in
                !task.completed &&
                (task.dueDate ?? now) >= startOfToday &&
                (task.dueDate ?? now) < endOfToday
            }

            let message: String
            if todaysTasks.isEmpty {
                message = "You have no tasks due today. Great job!"
            } else if todaysTasks.count == 1 {
                message = "You have 1 task due today: \(todaysTasks[0].title)"
            } else {
                let titles = todaysTasks.prefix(3).map { $0.title }.joined(separator: ", ")
                message = "You have \(todaysTasks.count) tasks today: \(titles)"
            }

            return .result(
                dialog: IntentDialog(stringLiteral: message),
                view: TodaysTasksSnippet(tasks: todaysTasks)
            )
        } catch {
            return .result(
                dialog: IntentDialog(stringLiteral: "Failed to load tasks: \(error.localizedDescription)"),
                view: TodaysTasksSnippet(tasks: [])
            )
        }
    }
}

// MARK: - Create Event Intent

struct CreateEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Event"
    static var description = IntentDescription("Create a new calendar event")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Event Title", requestValueDialog: "What's the event?")
    var title: String

    @Parameter(title: "Start Time", requestValueDialog: "When does it start?")
    var startTime: Date

    @Parameter(title: "Duration (minutes)", default: 60)
    var duration: Int

    @Parameter(title: "Location")
    var location: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))

        let eventCreate = EventCreate(
            title: title,
            description: nil,
            startTime: startTime,
            endTime: endTime,
            location: location
        )

        do {
            let event = try await APIClient.shared.createEvent(eventCreate)

            // Schedule notification
            await NotificationManager.shared.scheduleEventReminder(
                eventId: event.id,
                title: event.title,
                startTime: event.startTime
            )

            return .result(dialog: "Created event: \(event.title) at \(startTime.formatted(.dateTime.hour().minute()))")
        } catch {
            throw $title.needsValueError("Failed to create event: \(error.localizedDescription)")
        }
    }
}

// MARK: - Ask AI Intent

struct AskAIIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask AI"
    static var description = IntentDescription("Ask your AI assistant a question")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Question", requestValueDialog: "What would you like to know?")
    var question: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        do {
            let response = try await APIClient.shared.sendChatMessage(prompt: question)
            return .result(
                value: response.response,
                dialog: IntentDialog(stringLiteral: response.response)
            )
        } catch {
            throw $question.needsValueError("Failed to get AI response: \(error.localizedDescription)")
        }
    }
}

// MARK: - Snippet Views

struct TodaysTasksSnippet: View {
    let tasks: [Task]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if tasks.isEmpty {
                Label("No tasks today", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                ForEach(tasks.prefix(5)) { task in
                    HStack {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                    }
                }

                if tasks.count > 5 {
                    Text("And \(tasks.count - 5) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

// MARK: - Task Entity for Spotlight

struct TaskEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Task"
    static var defaultQuery = TaskQuery()

    var id: Int
    var title: String
    var completed: Bool
    var dueDate: Date?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: completed ? "Completed" : (dueDate != nil ? "Due: \(dueDate!.formatted(.dateTime.month().day()))" : "No due date"),
            image: .init(systemName: completed ? "checkmark.circle.fill" : "circle")
        )
    }
}

struct TaskQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [TaskEntity] {
        let tasks = try await APIClient.shared.getTasks()
        return tasks
            .filter { identifiers.contains($0.id) }
            .map { TaskEntity(id: $0.id, title: $0.title, completed: $0.completed, dueDate: $0.dueDate) }
    }

    func suggestedEntities() async throws -> [TaskEntity] {
        let tasks = try await APIClient.shared.getTasks()
        return tasks
            .filter { !$0.completed }
            .prefix(5)
            .map { TaskEntity(id: $0.id, title: $0.title, completed: $0.completed, dueDate: $0.dueDate) }
    }
}
