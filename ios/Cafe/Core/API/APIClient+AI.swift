//
//  APIClient+AI.swift
//  Cafe
//
//  Additional AI API endpoints
//

import Foundation

extension APIClient {
    // MARK: - AI Provider Info

    func getAIInfo() async throws -> AIProviderInfo {
        let request = try authorizedRequest(path: "/ai/info", method: "GET")
        return try await performRequest(request)
    }

    func getAIModels() async throws -> AIModelsResponse {
        let request = try authorizedRequest(path: "/ai/models", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - AI Embeddings

    func getEmbeddings(texts: [String], model: String? = nil) async throws -> AIEmbeddingsResponse {
        struct EmbeddingsRequest: Codable {
            let texts: [String]
            let model: String?
        }

        var request = try authorizedRequest(path: "/ai/embeddings", method: "POST")
        let body = EmbeddingsRequest(texts: texts, model: model)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    // MARK: - Task AI Features

    func estimateTaskTime(title: String, description: String?) async throws -> AITimeEstimate {
        struct TimeEstimateRequest: Codable {
            let title: String
            let description: String?
        }

        var request = try authorizedRequest(path: "/ai/tasks/estimate-time", method: "POST")
        let body = TimeEstimateRequest(title: title, description: description)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    func suggestTaskPriority(title: String, description: String?, dueDate: Date?) async throws -> AIPrioritySuggestion {
        struct PriorityRequest: Codable {
            let title: String
            let description: String?
            let dueDate: String?
        }

        var request = try authorizedRequest(path: "/ai/tasks/suggest-priority", method: "POST")
        let dueDateString = dueDate.map { ISO8601DateFormatter().string(from: $0) }
        let body = PriorityRequest(title: title, description: description, dueDate: dueDateString)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    func suggestTaskLabels(title: String, description: String?) async throws -> [String] {
        struct LabelsRequest: Codable {
            let title: String
            let description: String?
        }

        var request = try authorizedRequest(path: "/ai/tasks/suggest-labels", method: "POST")
        let body = LabelsRequest(title: title, description: description)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    // MARK: - Event AI Features

    func analyzeEvent(title: String, description: String?, startTime: Date, endTime: Date?) async throws -> AIEventAnalysis {
        struct EventAnalysisRequest: Codable {
            let title: String
            let description: String?
            let startTime: String
            let endTime: String?
        }

        var request = try authorizedRequest(path: "/ai/events/analyze", method: "POST")
        let formatter = ISO8601DateFormatter()
        let body = EventAnalysisRequest(
            title: title,
            description: description,
            startTime: formatter.string(from: startTime),
            endTime: endTime.map { formatter.string(from: $0) }
        )
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    // MARK: - Note AI Features

    func summarizeNote(content: String, maxLength: Int? = nil) async throws -> AINoteSummary {
        struct NoteSummaryRequest: Codable {
            let content: String
            let maxLength: Int?
        }

        var request = try authorizedRequest(path: "/ai/notes/summarize", method: "POST")
        let body = NoteSummaryRequest(content: content, maxLength: maxLength)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }
}

// MARK: - AI Models

struct AIProviderInfo: Codable {
    let provider: String
    let version: String?
    let capabilities: [String]
}

struct AIModelsResponse: Codable {
    let models: [AIModel]
    let defaultModel: String
}

struct AIModel: Codable {
    let id: String
    let name: String
    let capabilities: [String]
}

struct AIEmbeddingsResponse: Codable {
    let embeddings: [[Double]]
    let model: String
}

struct AITimeEstimate: Codable {
    let estimatedMinutes: Int
    let confidence: Double
    let reasoning: String
}

struct AIPrioritySuggestion: Codable {
    let priority: TaskPriority
    let confidence: Double
    let reasoning: String

    enum TaskPriority: String, Codable {
        case low
        case medium
        case high
        case urgent
    }
}

struct AIEventAnalysis: Codable {
    let category: String
    let suggestedDuration: Int?
    let conflicts: [String]
    let recommendations: [String]
}

struct AINoteSummary: Codable {
    let summary: String
    let keyPoints: [String]
    let wordCount: Int
}
