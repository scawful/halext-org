//
//  APIClient.swift
//  Cafe
//
//  Network client for Halext Org API
//

import Foundation

enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "http://127.0.0.1:8000"
        case .production:
            return "https://org.halext.org/api"
        }
    }
}

class APIClient {
    static let shared = APIClient()

    #if DEBUG
    let environment: APIEnvironment = .development
    #else
    let environment: APIEnvironment = .production
    #endif

    private var baseURL: String { environment.baseURL }
    private var token: String? { KeychainManager.shared.getToken() }
    private var accessCode: String? { KeychainManager.shared.getAccessCode() }

    private init() {}

    // MARK: - Authentication

    func login(username: String, password: String) async throws -> TokenResponse {
        let formData = "username=\(username)&password=\(password)"

        var request = URLRequest(url: URL(string: "\(baseURL)/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formData.data(using: .utf8)

        let response: TokenResponse = try await performRequest(request)

        // Save token to Keychain
        KeychainManager.shared.saveToken(response.accessToken)

        return response
    }

    func register(username: String, email: String, password: String, fullName: String? = nil) async throws -> User {
        let user = UserCreate(
            username: username,
            email: email,
            password: password,
            fullName: fullName
        )

        var request = URLRequest(url: URL(string: "\(baseURL)/users/")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add access code if available
        if let code = accessCode {
            request.setValue(code, forHTTPHeaderField: "X-Halext-Code")
        }

        request.httpBody = try JSONEncoder().encode(user)

        return try await performRequest(request)
    }

    func getCurrentUser() async throws -> User {
        let request = try authorizedRequest(path: "/users/me/", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - Tasks

    func getTasks() async throws -> [Task] {
        let request = try authorizedRequest(path: "/tasks/", method: "GET")
        return try await performRequest(request)
    }

    func createTask(_ task: TaskCreate) async throws -> Task {
        var request = try authorizedRequest(path: "/tasks/", method: "POST")
        request.httpBody = try JSONEncoder().encode(task)
        return try await performRequest(request)
    }

    func updateTask(id: Int, completed: Bool) async throws -> Task {
        let update = TaskUpdate(completed: completed)
        var request = try authorizedRequest(path: "/tasks/\(id)", method: "PUT")
        request.httpBody = try JSONEncoder().encode(update)
        return try await performRequest(request)
    }

    func deleteTask(id: Int) async throws {
        let request = try authorizedRequest(path: "/tasks/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - Events

    func getEvents() async throws -> [Event] {
        let request = try authorizedRequest(path: "/events/", method: "GET")
        return try await performRequest(request)
    }

    func createEvent(_ event: EventCreate) async throws -> Event {
        var request = try authorizedRequest(path: "/events/", method: "POST")
        request.httpBody = try JSONEncoder().encode(event)
        return try await performRequest(request)
    }

    // MARK: - Pages

    func getPages() async throws -> [Page] {
        let request = try authorizedRequest(path: "/pages/", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - Labels

    func getLabels() async throws -> [TaskLabel] {
        let request = try authorizedRequest(path: "/labels/", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - AI Features

    func sendChatMessage(prompt: String, history: [ChatMessage] = []) async throws -> AIChatResponse {
        let chatRequest = AIChatRequest(prompt: prompt, history: history)
        var request = try authorizedRequest(path: "/ai/chat", method: "POST")
        request.httpBody = try JSONEncoder().encode(chatRequest)
        return try await performRequest(request)
    }

    func getTaskSuggestions(title: String, description: String? = nil) async throws -> AITaskSuggestions {
        let suggestionRequest = AITaskSuggestionsRequest(title: title, description: description)
        var request = try authorizedRequest(path: "/ai/tasks/suggest", method: "POST")
        request.httpBody = try JSONEncoder().encode(suggestionRequest)
        return try await performRequest(request)
    }

    // MARK: - Helper Methods

    private func authorizedRequest(path: String, method: String) throws -> URLRequest {
        guard let token = token else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Handle 401 Unauthorized
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            // Try to decode error message
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.detail)
            }

            throw APIError.httpError(httpResponse.statusCode)
        }

        // Handle empty response for DELETE requests
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding error:", error)
            print("Response data:", String(data: data, encoding: .utf8) ?? "Unable to decode")
            throw APIError.decodingError
        }
    }
}

// MARK: - API Errors

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case httpError(Int)
    case decodingError
    case notAuthenticated
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .notAuthenticated:
            return "Not authenticated. Please login."
        case .unauthorized:
            return "Session expired. Please login again."
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Helper Types

struct EmptyResponse: Codable {}
struct ErrorResponse: Codable {
    let detail: String
}
