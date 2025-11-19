//
//  TaskTemplate.swift
//  Cafe
//
//  Reusable task templates
//

import Foundation

struct TaskTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var color: String

    // Template fields
    var titleTemplate: String
    var descriptionTemplate: String?
    var defaultLabels: [String]
    var defaultDueDays: Int? // Days from creation
    var defaultPriority: TaskPriority?
    var checklist: [ChecklistItem]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "doc.text",
        color: String = "blue",
        titleTemplate: String,
        descriptionTemplate: String? = nil,
        defaultLabels: [String] = [],
        defaultDueDays: Int? = nil,
        defaultPriority: TaskPriority? = nil,
        checklist: [ChecklistItem] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.titleTemplate = titleTemplate
        self.descriptionTemplate = descriptionTemplate
        self.defaultLabels = defaultLabels
        self.defaultDueDays = defaultDueDays
        self.defaultPriority = defaultPriority
        self.checklist = checklist
    }

    // Create a task from this template
    func createTask() -> TaskCreate {
        let dueDate: Date? = {
            guard let days = defaultDueDays else { return nil }
            return Calendar.current.date(byAdding: .day, value: days, to: Date())
        }()

        return TaskCreate(
            title: titleTemplate,
            description: descriptionTemplate,
            dueDate: dueDate,
            labels: defaultLabels
        )
    }
}

struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"

    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.2"
        }
    }
}

// MARK: - Predefined Templates

extension TaskTemplate {
    static let builtInTemplates: [TaskTemplate] = [
        TaskTemplate(
            name: "Meeting",
            icon: "person.3",
            color: "blue",
            titleTemplate: "Meeting: ",
            descriptionTemplate: "Agenda:\n- \n\nNotes:\n- ",
            defaultLabels: ["meeting"],
            defaultDueDays: 1,
            defaultPriority: .medium,
            checklist: [
                ChecklistItem(title: "Send calendar invite"),
                ChecklistItem(title: "Prepare agenda"),
                ChecklistItem(title: "Book meeting room")
            ]
        ),

        TaskTemplate(
            name: "Bug Report",
            icon: "ant",
            color: "red",
            titleTemplate: "Bug: ",
            descriptionTemplate: "Steps to reproduce:\n1. \n\nExpected behavior:\n\n\nActual behavior:\n\n",
            defaultLabels: ["bug"],
            defaultPriority: .high,
            checklist: [
                ChecklistItem(title: "Reproduce the issue"),
                ChecklistItem(title: "Document steps"),
                ChecklistItem(title: "Create fix"),
                ChecklistItem(title: "Test fix"),
                ChecklistItem(title: "Deploy")
            ]
        ),

        TaskTemplate(
            name: "Feature Request",
            icon: "sparkles",
            color: "purple",
            titleTemplate: "Feature: ",
            descriptionTemplate: "Description:\n\n\nUser Story:\nAs a [user], I want [feature] so that [benefit]\n\nAcceptance Criteria:\n- ",
            defaultLabels: ["feature"],
            defaultDueDays: 7,
            defaultPriority: .medium,
            checklist: [
                ChecklistItem(title: "Design mockups"),
                ChecklistItem(title: "Review with team"),
                ChecklistItem(title: "Implement"),
                ChecklistItem(title: "Test"),
                ChecklistItem(title: "Document")
            ]
        ),

        TaskTemplate(
            name: "Code Review",
            icon: "doc.text.magnifyingglass",
            color: "green",
            titleTemplate: "Review: ",
            descriptionTemplate: "PR Link:\n\n\nReview Checklist:\n- Code quality\n- Tests\n- Documentation\n- Performance",
            defaultLabels: ["review"],
            defaultDueDays: 1,
            defaultPriority: .medium,
            checklist: [
                ChecklistItem(title: "Review code changes"),
                ChecklistItem(title: "Check tests"),
                ChecklistItem(title: "Verify documentation"),
                ChecklistItem(title: "Leave feedback")
            ]
        ),

        TaskTemplate(
            name: "Weekly Planning",
            icon: "calendar",
            color: "orange",
            titleTemplate: "Plan week of ",
            descriptionTemplate: "Goals:\n- \n\nPriorities:\n1. \n\nNotes:\n",
            defaultLabels: ["planning"],
            defaultDueDays: 7,
            defaultPriority: .high,
            checklist: [
                ChecklistItem(title: "Review last week"),
                ChecklistItem(title: "Set goals"),
                ChecklistItem(title: "Schedule tasks"),
                ChecklistItem(title: "Block calendar")
            ]
        ),

        TaskTemplate(
            name: "Research",
            icon: "book",
            color: "indigo",
            titleTemplate: "Research: ",
            descriptionTemplate: "Topic:\n\n\nQuestions:\n- \n\nResources:\n- ",
            defaultLabels: ["research"],
            defaultDueDays: 3,
            defaultPriority: .low,
            checklist: [
                ChecklistItem(title: "Gather resources"),
                ChecklistItem(title: "Take notes"),
                ChecklistItem(title: "Summarize findings"),
                ChecklistItem(title: "Share with team")
            ]
        ),

        TaskTemplate(
            name: "Shopping List",
            icon: "cart",
            color: "teal",
            titleTemplate: "Shopping: ",
            descriptionTemplate: "Items:\n- \n- \n- ",
            defaultLabels: ["personal"],
            defaultPriority: .low
        ),

        TaskTemplate(
            name: "Workout",
            icon: "figure.run",
            color: "pink",
            titleTemplate: "Workout: ",
            descriptionTemplate: "Exercises:\n- \n\nDuration:\n\nNotes:",
            defaultLabels: ["fitness"],
            defaultPriority: .medium,
            checklist: [
                ChecklistItem(title: "Warm up"),
                ChecklistItem(title: "Main workout"),
                ChecklistItem(title: "Cool down"),
                ChecklistItem(title: "Stretch")
            ]
        )
    ]
}
