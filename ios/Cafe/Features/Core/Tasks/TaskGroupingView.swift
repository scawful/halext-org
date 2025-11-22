//
//  TaskGroupingView.swift
//  Cafe
//
//  Task grouping options and views
//

import SwiftUI

enum TaskGroupingOption: String, CaseIterable, Identifiable {
    case none = "None"
    case byDate = "By Date"
    case byLabel = "By Label"
    case byStatus = "By Status"
    case byPriority = "By Priority"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "list.bullet"
        case .byDate: return "calendar"
        case .byLabel: return "tag"
        case .byStatus: return "checkmark.circle"
        case .byPriority: return "exclamationmark.circle"
        }
    }
}

struct TaskGroupingView: View {
    let tasks: [Task]
    let grouping: TaskGroupingOption
    @Environment(ThemeManager.self) private var themeManager
    
    var groupedTasks: [String: [Task]] {
        switch grouping {
        case .none:
            return ["All Tasks": tasks]
            
        case .byDate:
            return groupTasks(tasks) { task in
                if let dueDate = task.dueDate {
                    let calendar = Calendar.current
                    if calendar.isDateInToday(dueDate) {
                        return "Today"
                    } else if calendar.isDateInTomorrow(dueDate) {
                        return "Tomorrow"
                    } else if calendar.isDateInYesterday(dueDate) {
                        return "Yesterday"
                    } else if calendar.dateInterval(of: .weekOfYear, for: dueDate)?.contains(Date()) ?? false {
                        return "This Week"
                    } else {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MMMM yyyy"
                        return formatter.string(from: dueDate)
                    }
                } else {
                    return "No Due Date"
                }
            }
            
        case .byLabel:
            return groupTasks(tasks) { task in
                if task.labels.isEmpty {
                    return "No Labels"
                } else {
                    return task.labels.map { $0.name }.joined(separator: ", ")
                }
            }
            
        case .byStatus:
            return groupTasks(tasks) { task in
                task.completed ? "Completed" : "Pending"
            }
            
        case .byPriority:
            // Assuming tasks have priority - for now, group by completion
            return groupTasks(tasks) { task in
                if task.completed {
                    return "Completed"
                } else if let dueDate = task.dueDate, dueDate < Date() {
                    return "Overdue"
                } else {
                    return "Upcoming"
                }
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(Array(groupedTasks.keys.sorted()), id: \.self) { groupKey in
                Section {
                    ForEach(groupedTasks[groupKey] ?? []) { task in
                        TaskRowView(
                            task: task,
                            onToggle: {},
                            onDelete: {},
                            onGenerateRecipe: {},
                            onSelect: nil
                        )
                    }
                } header: {
                    HStack {
                        Image(systemName: grouping.icon)
                            .foregroundColor(themeManager.accentColor)
                        Text(groupKey)
                            .font(.headline)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// Helper function for grouping tasks
private func groupTasks<T: Hashable>(_ tasks: [Task], by keyForTask: (Task) -> T) -> [String: [Task]] {
    var result: [String: [Task]] = [:]
    for task in tasks {
        let key = String(describing: keyForTask(task))
        if result[key] == nil {
            result[key] = []
        }
        result[key]?.append(task)
    }
    return result
}

// MARK: - Preview

#Preview {
    TaskGroupingView(
        tasks: [],
        grouping: .byDate
    )
    .environment(ThemeManager.shared)
}

