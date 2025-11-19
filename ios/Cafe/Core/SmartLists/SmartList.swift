//
//  SmartList.swift
//  Cafe
//
//  Custom filtered task views
//

import Foundation

struct SmartList: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var filters: [TaskFilter]
    var sortOrder: TaskSortOrder
    var groupBy: TaskGrouping?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "line.3.horizontal.decrease.circle",
        color: String = "blue",
        filters: [TaskFilter] = [],
        sortOrder: TaskSortOrder = .dueDate,
        groupBy: TaskGrouping? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.filters = filters
        self.sortOrder = sortOrder
        self.groupBy = groupBy
    }

    // Apply filters to a list of tasks
    func filter(tasks: [Task]) -> [Task] {
        var filtered = tasks

        for filter in filters {
            filtered = filter.apply(to: filtered)
        }

        // Sort
        filtered = sortOrder.sort(tasks: filtered)

        return filtered
    }

    // Group tasks if grouping is enabled
    func group(tasks: [Task]) -> [(String, [Task])] {
        guard let grouping = groupBy else {
            return [("All Tasks", tasks)]
        }

        return grouping.group(tasks: tasks)
    }
}

// MARK: - Task Filter

enum TaskFilter: Codable, Hashable {
    case label(String)
    case dueToday
    case dueThisWeek
    case overdue
    case noDueDate
    case completed
    case incomplete
    case hasDescription
    case noDescription
    case createdToday
    case createdThisWeek
    case custom(CustomFilter)

    func apply(to tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .label(let labelName):
            return tasks.filter { task in
                task.labels.contains(where: { $0.name.lowercased() == labelName.lowercased() })
            }

        case .dueToday:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDateInToday(dueDate)
            }

        case .dueThisWeek:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
                return dueDate >= now && dueDate <= weekFromNow
            }

        case .overdue:
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < now && !task.completed
            }

        case .noDueDate:
            return tasks.filter { $0.dueDate == nil }

        case .completed:
            return tasks.filter { $0.completed }

        case .incomplete:
            return tasks.filter { !$0.completed }

        case .hasDescription:
            return tasks.filter { task in
                if let description = task.description {
                    return !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                return false
            }

        case .noDescription:
            return tasks.filter { task in
                if let description = task.description {
                    return description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                return true
            }

        case .createdToday:
            return tasks.filter { task in
                calendar.isDateInToday(task.createdAt)
            }

        case .createdThisWeek:
            return tasks.filter { task in
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
                return task.createdAt >= weekAgo
            }

        case .custom(let customFilter):
            return customFilter.apply(to: tasks)
        }
    }

    var displayName: String {
        switch self {
        case .label(let name): return "Label: \(name)"
        case .dueToday: return "Due Today"
        case .dueThisWeek: return "Due This Week"
        case .overdue: return "Overdue"
        case .noDueDate: return "No Due Date"
        case .completed: return "Completed"
        case .incomplete: return "Incomplete"
        case .hasDescription: return "Has Description"
        case .noDescription: return "No Description"
        case .createdToday: return "Created Today"
        case .createdThisWeek: return "Created This Week"
        case .custom(let filter): return filter.name
        }
    }

    var icon: String {
        switch self {
        case .label: return "tag"
        case .dueToday: return "calendar"
        case .dueThisWeek: return "calendar.badge.clock"
        case .overdue: return "exclamationmark.triangle"
        case .noDueDate: return "calendar.badge.minus"
        case .completed: return "checkmark.circle"
        case .incomplete: return "circle"
        case .hasDescription: return "doc.text"
        case .noDescription: return "doc"
        case .createdToday: return "sparkles"
        case .createdThisWeek: return "clock"
        case .custom: return "wand.and.stars"
        }
    }
}

// MARK: - Custom Filter

struct CustomFilter: Codable, Hashable {
    var name: String
    var titleContains: String?
    var descriptionContains: String?

    func apply(to tasks: [Task]) -> [Task] {
        var filtered = tasks

        if let titleSearch = titleContains, !titleSearch.isEmpty {
            filtered = filtered.filter { task in
                task.title.lowercased().contains(titleSearch.lowercased())
            }
        }

        if let descSearch = descriptionContains, !descSearch.isEmpty {
            filtered = filtered.filter { task in
                task.description?.lowercased().contains(descSearch.lowercased()) ?? false
            }
        }

        return filtered
    }
}

// MARK: - Sort Order

enum TaskSortOrder: String, Codable, CaseIterable {
    case dueDate = "Due Date"
    case createdDate = "Created Date"
    case title = "Title"
    case completed = "Completion Status"

    func sort(tasks: [Task]) -> [Task] {
        switch self {
        case .dueDate:
            return tasks.sorted { lhs, rhs in
                // Tasks with due dates come before tasks without
                switch (lhs.dueDate, rhs.dueDate) {
                case (nil, nil): return false
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 < date2
                }
            }

        case .createdDate:
            return tasks.sorted { $0.createdAt > $1.createdAt }

        case .title:
            return tasks.sorted { $0.title.lowercased() < $1.title.lowercased() }

        case .completed:
            return tasks.sorted { !$0.completed && $1.completed }
        }
    }
}

// MARK: - Grouping

enum TaskGrouping: String, Codable, CaseIterable {
    case label = "By Label"
    case dueDate = "By Due Date"
    case completionStatus = "By Status"

    func group(tasks: [Task]) -> [(String, [Task])] {
        switch self {
        case .label:
            let grouped = Dictionary(grouping: tasks) { task -> String in
                task.labels.first?.name ?? "No Label"
            }
            return grouped.sorted { $0.key < $1.key }

        case .dueDate:
            let calendar = Calendar.current
            let now = Date()

            let grouped = Dictionary(grouping: tasks) { task -> String in
                guard let dueDate = task.dueDate else { return "No Due Date" }

                if dueDate < now {
                    return "Overdue"
                } else if calendar.isDateInToday(dueDate) {
                    return "Today"
                } else if calendar.isDateInTomorrow(dueDate) {
                    return "Tomorrow"
                } else {
                    let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
                    if dueDate <= weekFromNow {
                        return "This Week"
                    } else {
                        return "Later"
                    }
                }
            }

            // Sort groups in logical order
            let order = ["Overdue", "Today", "Tomorrow", "This Week", "Later", "No Due Date"]
            return order.compactMap { key in
                grouped[key].map { (key, $0) }
            }

        case .completionStatus:
            let grouped = Dictionary(grouping: tasks) { task -> String in
                task.completed ? "Completed" : "Incomplete"
            }
            return [
                ("Incomplete", grouped["Incomplete"] ?? []),
                ("Completed", grouped["Completed"] ?? [])
            ]
        }
    }
}

// MARK: - Predefined Smart Lists

extension SmartList {
    static let builtInLists: [SmartList] = [
        SmartList(
            name: "Today",
            icon: "calendar",
            color: "blue",
            filters: [.dueToday, .incomplete],
            sortOrder: .dueDate
        ),

        SmartList(
            name: "This Week",
            icon: "calendar.badge.clock",
            color: "green",
            filters: [.dueThisWeek, .incomplete],
            sortOrder: .dueDate
        ),

        SmartList(
            name: "Overdue",
            icon: "exclamationmark.triangle",
            color: "red",
            filters: [.overdue],
            sortOrder: .dueDate
        ),

        SmartList(
            name: "No Due Date",
            icon: "calendar.badge.minus",
            color: "gray",
            filters: [.noDueDate, .incomplete],
            sortOrder: .createdDate
        ),

        SmartList(
            name: "Recently Created",
            icon: "sparkles",
            color: "purple",
            filters: [.createdThisWeek],
            sortOrder: .createdDate
        ),

        SmartList(
            name: "Completed",
            icon: "checkmark.circle",
            color: "green",
            filters: [.completed],
            sortOrder: .createdDate
        ),

        SmartList(
            name: "All Tasks",
            icon: "list.bullet",
            color: "blue",
            filters: [],
            sortOrder: .dueDate
        )
    ]
}
