//
//  DeepLinkManager.swift
//  Cafe
//
//  Enhanced deep linking and URL scheme handling
//

import Foundation

@MainActor
class DeepLinkManager {
    static let shared = DeepLinkManager()

    private init() {}

    // MARK: - Handle Deep Link

    func handleDeepLink(_ url: URL) -> DeepLinkAction? {
        print("🔗 Handling deep link: \(url)")

        guard url.scheme == "cafe" else {
            return nil
        }

        let host = url.host ?? ""
        let path = url.path
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        switch host {
        // Simple actions
        case "new-task":
            return .newTask(prefill: extractPrefillData(from: queryItems))

        case "new-event":
            return .newEvent(prefill: extractEventPrefillData(from: queryItems))

        case "chat":
            let prompt = queryItems.first(where: { $0.name == "prompt" })?.value
            return .openChat(prompt: prompt)

        // View specific items
        case "task":
            if let taskId = extractID(from: path) {
                return .viewTask(id: taskId)
            }

        case "event":
            if let eventId = extractID(from: path) {
                return .viewEvent(id: eventId)
            }

        // Navigation
        case "dashboard":
            return .openDashboard

        case "calendar":
            if let dateString = queryItems.first(where: { $0.name == "date" })?.value,
               let date = ISO8601DateFormatter().date(from: dateString) {
                return .openCalendar(date: date)
            }
            return .openCalendar(date: nil)

        // Share extension
        case "share":
            return .processShare

        // Search
        case "search":
            let query = queryItems.first(where: { $0.name == "q" })?.value ?? ""
            return .search(query: query)

        // Settings
        case "settings":
            let section = path.replacingOccurrences(of: "/", with: "")
            return .openSettings(section: section.isEmpty ? nil : section)

        default:
            print("⚠️ Unknown deep link host: \(host)")
            return nil
        }

        return nil
    }

    // MARK: - Extract Data

    private func extractID(from path: String) -> Int? {
        let components = path.components(separatedBy: "/")
        guard let lastComponent = components.last,
              let id = Int(lastComponent) else {
            return nil
        }
        return id
    }

    private func extractPrefillData(from queryItems: [URLQueryItem]) -> TaskPrefillData? {
        let title = queryItems.first(where: { $0.name == "title" })?.value
        let description = queryItems.first(where: { $0.name == "description" })?.value
        let dueDateString = queryItems.first(where: { $0.name == "due" })?.value
        let labels = queryItems.first(where: { $0.name == "labels" })?.value?.components(separatedBy: ",")

        guard title != nil || description != nil else {
            return nil
        }

        var dueDate: Date?
        if let dueDateString = dueDateString {
            dueDate = ISO8601DateFormatter().date(from: dueDateString)
        }

        return TaskPrefillData(
            title: title,
            description: description,
            dueDate: dueDate,
            labels: labels ?? []
        )
    }

    private func extractEventPrefillData(from queryItems: [URLQueryItem]) -> EventPrefillData? {
        let title = queryItems.first(where: { $0.name == "title" })?.value
        let startTimeString = queryItems.first(where: { $0.name == "start" })?.value
        let endTimeString = queryItems.first(where: { $0.name == "end" })?.value
        let location = queryItems.first(where: { $0.name == "location" })?.value

        guard let title = title else {
            return nil
        }

        var startTime: Date?
        var endTime: Date?

        if let startTimeString = startTimeString {
            startTime = ISO8601DateFormatter().date(from: startTimeString)
        }

        if let endTimeString = endTimeString {
            endTime = ISO8601DateFormatter().date(from: endTimeString)
        }

        return EventPrefillData(
            title: title,
            startTime: startTime,
            endTime: endTime,
            location: location
        )
    }

    // MARK: - Generate Deep Links

    func generateTaskLink(taskId: Int) -> URL? {
        URL(string: "cafe://task/\(taskId)")
    }

    func generateEventLink(eventId: Int) -> URL? {
        URL(string: "cafe://event/\(eventId)")
    }

    func generateNewTaskLink(title: String? = nil, description: String? = nil, dueDate: Date? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "cafe"
        components.host = "new-task"

        var queryItems: [URLQueryItem] = []

        if let title = title {
            queryItems.append(URLQueryItem(name: "title", value: title))
        }

        if let description = description {
            queryItems.append(URLQueryItem(name: "description", value: description))
        }

        if let dueDate = dueDate {
            let dateString = ISO8601DateFormatter().string(from: dueDate)
            queryItems.append(URLQueryItem(name: "due", value: dateString))
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url
    }

    func generateSearchLink(query: String) -> URL? {
        var components = URLComponents()
        components.scheme = "cafe"
        components.host = "search"
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        return components.url
    }
}

// MARK: - Deep Link Actions

enum DeepLinkAction {
    case newTask(prefill: TaskPrefillData?)
    case newEvent(prefill: EventPrefillData?)
    case viewTask(id: Int)
    case viewEvent(id: Int)
    case openChat(prompt: String?)
    case openDashboard
    case openCalendar(date: Date?)
    case processShare
    case search(query: String)
    case openSettings(section: String?)
}

// MARK: - Prefill Data

struct TaskPrefillData {
    let title: String?
    let description: String?
    let dueDate: Date?
    let labels: [String]
}

struct EventPrefillData {
    let title: String
    let startTime: Date?
    let endTime: Date?
    let location: String?
}
