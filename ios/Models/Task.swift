import Foundation

struct LabelDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let color: String
}

struct TaskSummary: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let due_date: Date?
    let completed: Bool
    let labels: [LabelDTO]

    var dueDateString: String {
        guard let due_date else { return "" }
        return DateFormatter.short.string(from: due_date)
    }
}

struct EventSummary: Codable, Identifiable {
    let id: Int
    let title: String
    let start_time: Date
    let end_time: Date
    let location: String?
    let recurrence_type: String
}

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}
