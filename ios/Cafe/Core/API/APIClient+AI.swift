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

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(AIModelsResponse.self, from: data)
    }

    /// Fetch AI models and return them (convenience method)
    func fetchAiModels() async throws -> AIModelsResponse {
        return try await getAIModels()
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

    // MARK: - Recipe AI Features

    func generateRecipes(request: RecipeGenerationRequest) async throws -> RecipeGenerationResponse {
        var apiRequest = try authorizedRequest(path: "/ai/recipes/generate", method: "POST")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        apiRequest.httpBody = try encoder.encode(request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let (data, response) = try await URLSession.shared.data(for: apiRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(RecipeGenerationResponse.self, from: data)
    }

    func generateMealPlan(request: MealPlanRequest) async throws -> MealPlanResponse {
        var apiRequest = try authorizedRequest(path: "/ai/recipes/meal-plan", method: "POST")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        apiRequest.httpBody = try encoder.encode(request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let (data, response) = try await URLSession.shared.data(for: apiRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(MealPlanResponse.self, from: data)
    }

    func generateRecipesWithSubstitutions(
        ingredients: [String],
        recipeType: String?
    ) async throws -> RecipeGenerationResponse {
        struct SubstitutionRequest: Codable {
            let ingredients: [String]
            let recipeType: String?

            enum CodingKeys: String, CodingKey {
                case ingredients
                case recipeType = "recipe_type"
            }
        }

        var apiRequest = try authorizedRequest(path: "/ai/recipes/suggest-substitutions", method: "POST")
        let body = SubstitutionRequest(ingredients: ingredients, recipeType: recipeType)
        apiRequest.httpBody = try JSONEncoder().encode(body)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let (data, response) = try await URLSession.shared.data(for: apiRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(RecipeGenerationResponse.self, from: data)
    }

    func analyzeIngredients(ingredients: [String]) async throws -> IngredientAnalysis {
        struct IngredientsRequest: Codable {
            let ingredients: [String]
        }

        var apiRequest = try authorizedRequest(path: "/ai/recipes/analyze-ingredients", method: "POST")
        let body = IngredientsRequest(ingredients: ingredients)
        apiRequest.httpBody = try JSONEncoder().encode(body)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let (data, response) = try await URLSession.shared.data(for: apiRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(IngredientAnalysis.self, from: data)
    }

    // MARK: - Smart Generation

    func generateSmartItems(prompt: String, context: GenerationContext) async throws -> SmartGenerationResponse {
        struct SmartGenerationRequest: Codable {
            let prompt: String
            let context: GenerationContext
        }

        var request = try authorizedRequest(path: "/ai/generate-tasks", method: "POST")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = SmartGenerationRequest(prompt: prompt, context: context)
        request.httpBody = try encoder.encode(body)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try decoder.decode(SmartGenerationResponse.self, from: data)
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
    let provider: String
    let currentModel: String
    let defaultModelId: String?

    enum CodingKeys: String, CodingKey {
        case models, provider
        case currentModel = "current_model"
        case defaultModelId = "default_model_id"
    }
}

struct AIModel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let provider: String
    let size: String?
    let source: String?
    let nodeId: Int?
    let nodeName: String?
    let endpoint: String?
    let latencyMs: Int?
    let metadata: [String: AnyCodable]
    let modifiedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, provider, size, source, endpoint, metadata
        case nodeId = "node_id"
        case nodeName = "node_name"
        case latencyMs = "latency_ms"
        case modifiedAt = "modified_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        provider = try container.decode(String.self, forKey: .provider)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        nodeId = try container.decodeIfPresent(Int.self, forKey: .nodeId)
        nodeName = try container.decodeIfPresent(String.self, forKey: .nodeName)
        endpoint = try container.decodeIfPresent(String.self, forKey: .endpoint)
        latencyMs = try container.decodeIfPresent(Int.self, forKey: .latencyMs)
        metadata = (try? container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)) ?? [:]
        modifiedAt = try container.decodeIfPresent(String.self, forKey: .modifiedAt)
    }

    var displayName: String {
        if let nodeName = nodeName {
            return "\(name) (\(nodeName))"
        }
        return name
    }

    var sourceLabel: String {
        source ?? provider
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AIModel, rhs: AIModel) -> Bool {
        lhs.id == rhs.id
    }
}

// Helper to decode arbitrary JSON values
struct AnyCodable: Codable, Hashable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    func hash(into hasher: inout Hasher) {
        if let string = value as? String {
            hasher.combine(string)
        } else if let int = value as? Int {
            hasher.combine(int)
        } else if let double = value as? Double {
            hasher.combine(double)
        } else if let bool = value as? Bool {
            hasher.combine(bool)
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as String, r as String): return l == r
        case let (l as Int, r as Int): return l == r
        case let (l as Double, r as Double): return l == r
        case let (l as Bool, r as Bool): return l == r
        default: return false
        }
    }
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

// MARK: - Smart Generation Models

struct SmartGenerationResponse: Codable {
    let tasks: [GeneratedTaskData]
    let events: [GeneratedEventData]
    let smartLists: [GeneratedSmartListData]
    let metadata: GenerationMetadataData

    enum CodingKeys: String, CodingKey {
        case tasks, events, metadata
        case smartLists = "smart_lists"
    }
}

struct GeneratedTaskData: Codable {
    let title: String
    let description: String?
    let dueDate: Date?
    let priority: String?
    let labels: [String]
    let estimatedMinutes: Int?
    let subtasks: [String]?
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case title, description, priority, labels, subtasks, reasoning
        case dueDate = "due_date"
        case estimatedMinutes = "estimated_minutes"
    }
}

struct GeneratedEventData: Codable {
    let title: String
    let description: String?
    let startTime: Date
    let endTime: Date
    let location: String?
    let recurrenceType: String
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case title, description, location, reasoning
        case startTime = "start_time"
        case endTime = "end_time"
        case recurrenceType = "recurrence_type"
    }
}

struct GeneratedSmartListData: Codable {
    let name: String
    let description: String?
    let category: String
    let items: [String]
    let reasoning: String?
}

struct GenerationMetadataData: Codable {
    let originalPrompt: String
    let model: String
    let summary: String

    enum CodingKeys: String, CodingKey {
        case model, summary
        case originalPrompt = "original_prompt"
    }
}
