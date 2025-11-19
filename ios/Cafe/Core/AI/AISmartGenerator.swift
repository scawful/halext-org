//
//  AISmartGenerator.swift
//  Cafe
//
//  AI-powered smart task and list generation manager
//  Converts natural language prompts into structured tasks, events, and smart lists
//

import Foundation
import Combine

/// Manager class for AI-powered smart task/list/event generation
@MainActor
class AISmartGenerator: ObservableObject {
    static let shared = AISmartGenerator()

    @Published var isGenerating = false
    @Published var generationProgress: GenerationProgress = .idle
    @Published var lastError: AIGeneratorError?

    private let apiClient = APIClient.shared

    private init() {}

    /// Generate structured tasks, events, and lists from a natural language prompt
    /// - Parameters:
    ///   - prompt: Natural language description of what to create
    ///   - context: Additional context (timezone, current date, existing tasks, etc.)
    /// - Returns: Generated items ready for preview/editing
    func generateFromPrompt(
        _ prompt: String,
        context: GenerationContext? = nil
    ) async throws -> GenerationResult {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIGeneratorError.emptyPrompt
        }

        isGenerating = true
        generationProgress = .analyzing
        defer {
            isGenerating = false
            generationProgress = .idle
        }

        do {
            // Build context if not provided
            let generationContext: GenerationContext
            if let providedContext = context {
                generationContext = providedContext
            } else {
                generationContext = await buildDefaultContext()
            }

            // Call backend AI endpoint
            generationProgress = .generating
            let response = try await apiClient.generateSmartItems(
                prompt: prompt,
                context: generationContext
            )

            generationProgress = .organizing

            // Parse and structure the response
            let result = try parseGenerationResponse(response)

            generationProgress = .complete
            return result

        } catch let error as APIError {
            lastError = .apiError(error)
            throw AIGeneratorError.apiError(error)
        } catch {
            lastError = .unknownError(error.localizedDescription)
            throw AIGeneratorError.unknownError(error.localizedDescription)
        }
    }

    /// Build default generation context with current environment
    private func buildDefaultContext() async -> GenerationContext {
        let timezone = TimeZone.current.identifier
        let currentDate = ISO8601DateFormatter().string(from: Date())

        // Optionally fetch user's existing tasks/events for smart suggestions
        var existingTaskTitles: [String] = []
        var upcomingEventDates: [String] = []

        do {
            let tasks = try await apiClient.getTasks()
            existingTaskTitles = tasks.prefix(20).map { $0.title }

            let events = try await apiClient.getEvents()
            upcomingEventDates = events.prefix(10).map {
                ISO8601DateFormatter().string(from: $0.startTime)
            }
        } catch {
            // Context fetch is optional, continue without it
            print("Could not fetch context: \(error)")
        }

        return GenerationContext(
            timezone: timezone,
            currentDate: currentDate,
            existingTaskTitles: existingTaskTitles.isEmpty ? nil : existingTaskTitles,
            upcomingEventDates: upcomingEventDates.isEmpty ? nil : upcomingEventDates
        )
    }

    /// Parse the AI response into structured generation result
    private func parseGenerationResponse(_ response: SmartGenerationResponse) throws -> GenerationResult {
        var generatedTasks: [GeneratedTask] = []
        var generatedEvents: [GeneratedEvent] = []
        var generatedSmartLists: [GeneratedSmartList] = []

        // Parse tasks with hierarchy support (main tasks and subtasks)
        for taskData in response.tasks {
            let task = GeneratedTask(
                id: UUID(),
                title: taskData.title,
                description: taskData.description,
                dueDate: taskData.dueDate,
                priority: parsePriority(taskData.priority),
                labels: taskData.labels,
                estimatedMinutes: taskData.estimatedMinutes,
                subtasks: taskData.subtasks,
                parentTaskId: nil,
                aiReasoning: taskData.reasoning
            )
            generatedTasks.append(task)
        }

        // Parse events
        for eventData in response.events {
            let event = GeneratedEvent(
                id: UUID(),
                title: eventData.title,
                description: eventData.description,
                startTime: eventData.startTime,
                endTime: eventData.endTime,
                location: eventData.location,
                recurrenceType: eventData.recurrenceType,
                aiReasoning: eventData.reasoning
            )
            generatedEvents.append(event)
        }

        // Parse smart lists
        for listData in response.smartLists {
            let smartList = GeneratedSmartList(
                id: UUID(),
                name: listData.name,
                description: listData.description,
                category: listData.category,
                items: listData.items,
                aiReasoning: listData.reasoning
            )
            generatedSmartLists.append(smartList)
        }

        return GenerationResult(
            tasks: generatedTasks,
            events: generatedEvents,
            smartLists: generatedSmartLists,
            metadata: GenerationMetadata(
                originalPrompt: response.metadata.originalPrompt,
                generatedAt: Date(),
                aiModel: response.metadata.model,
                summary: response.metadata.summary
            )
        )
    }

    /// Parse priority string to enum
    private func parsePriority(_ priorityString: String?) -> TaskPriority {
        guard let priorityString = priorityString?.lowercased() else {
            return .medium
        }

        switch priorityString {
        case "low":
            return .low
        case "medium":
            return .medium
        case "high":
            return .high
        case "urgent":
            return .urgent
        default:
            return .medium
        }
    }

    /// Create actual tasks/events from generated items
    func createItems(from result: GenerationResult, selectedTaskIds: Set<UUID>, selectedEventIds: Set<UUID>) async throws {
        // Create selected tasks
        for task in result.tasks where selectedTaskIds.contains(task.id) {
            let taskCreate = TaskCreate(
                title: task.title,
                description: task.description,
                dueDate: task.dueDate,
                labels: task.labels
            )

            do {
                let createdTask = try await apiClient.createTask(taskCreate)

                // Create subtasks if any
                if let subtasks = task.subtasks {
                    for subtaskTitle in subtasks {
                        let subtaskCreate = TaskCreate(
                            title: subtaskTitle,
                            description: "Part of: \(task.title)",
                            dueDate: task.dueDate,
                            labels: task.labels
                        )
                        _ = try await apiClient.createTask(subtaskCreate)
                    }
                }
            } catch {
                print("Failed to create task '\(task.title)': \(error)")
                throw error
            }
        }

        // Create selected events
        for event in result.events where selectedEventIds.contains(event.id) {
            let eventCreate = EventCreate(
                title: event.title,
                description: event.description,
                startTime: event.startTime,
                endTime: event.endTime,
                location: event.location
            )

            do {
                _ = try await apiClient.createEvent(eventCreate)
            } catch {
                print("Failed to create event '\(event.title)': \(error)")
                throw error
            }
        }
    }
}

// MARK: - Models

/// Context information for AI generation
struct GenerationContext: Codable {
    let timezone: String
    let currentDate: String
    let existingTaskTitles: [String]?
    let upcomingEventDates: [String]?

    enum CodingKeys: String, CodingKey {
        case timezone
        case currentDate = "current_date"
        case existingTaskTitles = "existing_task_titles"
        case upcomingEventDates = "upcoming_event_dates"
    }
}

/// Progress state of generation
enum GenerationProgress {
    case idle
    case analyzing      // Understanding the prompt
    case generating     // AI is generating items
    case organizing     // Structuring the results
    case complete

    var description: String {
        switch self {
        case .idle:
            return ""
        case .analyzing:
            return "Analyzing your request..."
        case .generating:
            return "Generating tasks and events..."
        case .organizing:
            return "Organizing results..."
        case .complete:
            return "Complete!"
        }
    }
}

/// Result of AI generation
struct GenerationResult {
    let tasks: [GeneratedTask]
    let events: [GeneratedEvent]
    let smartLists: [GeneratedSmartList]
    let metadata: GenerationMetadata

    var isEmpty: Bool {
        tasks.isEmpty && events.isEmpty && smartLists.isEmpty
    }

    var totalItemCount: Int {
        tasks.count + events.count + smartLists.count
    }
}

/// Metadata about the generation
struct GenerationMetadata {
    let originalPrompt: String
    let generatedAt: Date
    let aiModel: String
    let summary: String
}

/// Generated task ready for preview/creation
struct GeneratedTask: Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var dueDate: Date?
    var priority: TaskPriority
    var labels: [String]
    var estimatedMinutes: Int?
    var subtasks: [String]?
    var parentTaskId: UUID?
    let aiReasoning: String?
}

/// Generated event ready for preview/creation
struct GeneratedEvent: Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var location: String?
    var recurrenceType: String
    let aiReasoning: String?
}

/// Generated smart list ready for preview/creation
struct GeneratedSmartList: Identifiable {
    let id: UUID
    var name: String
    var description: String?
    var category: String
    var items: [String]
    let aiReasoning: String?
}

// Note: TaskPriority is defined in TaskTemplate.swift

/// Errors specific to AI generation
enum AIGeneratorError: LocalizedError {
    case emptyPrompt
    case apiError(APIError)
    case invalidResponse
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Please enter a description of what you'd like to create"
        case .apiError(let apiError):
            return apiError.errorDescription
        case .invalidResponse:
            return "Could not understand the AI response. Please try again."
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
}
