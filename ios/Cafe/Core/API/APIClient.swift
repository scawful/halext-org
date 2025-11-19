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

    // Allow environment override in DEBUG builds
    var environment: APIEnvironment {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "useProductionAPI") {
            return .production
        }
        return .development
        #else
        return .production
        #endif
    }

    private var baseURL: String { environment.baseURL }
    private var token: String? { KeychainManager.shared.getToken() }
    private var accessCode: String? { KeychainManager.shared.getAccessCode() }

    private init() {}

    // MARK: - Authentication

    /// Properly encode a string for application/x-www-form-urlencoded format
    /// This follows RFC 3986 and HTML form encoding rules
    private func formURLEncode(_ string: String) -> String? {
        // Characters allowed in form data: A-Z, a-z, 0-9, -, _, ., ~
        // Everything else must be percent-encoded
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: "-_.~")
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }

    func login(username: String, password: String) async throws -> TokenResponse {
        // URL encode the username and password for form data
        guard let encodedUsername = formURLEncode(username),
              let encodedPassword = formURLEncode(password) else {
            throw APIError.invalidCredentials
        }

        let formData = "username=\(encodedUsername)&password=\(encodedPassword)"
        let loginURL = "\(baseURL)/token"

        print("🔐 Attempting login to: \(loginURL)")
        print("🌍 Using environment: \(environment)")
        print("👤 Username: '\(username)' (length: \(username.count))")
        print("🔑 Password length: \(password.count)")
        print("📝 Encoded username: '\(encodedUsername)'")
        print("📦 Form data: \(formData)")

        var request = URLRequest(url: URL(string: loginURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formData.data(using: .utf8)

        // Log headers
        print("📋 Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📤 Request body: \(bodyString)")
        }

        let response: TokenResponse = try await performRequest(request)
        print("✅ Login successful, got token")

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

    // MARK: - Labels

    func getLabels() async throws -> [TaskLabel] {
        let request = try authorizedRequest(path: "/labels/", method: "GET")
        return try await performRequest(request)
    }

    func createLabel(name: String, color: String) async throws -> TaskLabel {
        struct LabelCreate: Codable {
            let name: String
            let color: String
        }

        var request = try authorizedRequest(path: "/labels/", method: "POST")
        let body = LabelCreate(name: name, color: color)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }

    // MARK: - AI Features

    func sendChatMessage(prompt: String, history: [ChatMessage] = []) async throws -> AIChatResponse {
        let chatRequest = AIChatRequest(prompt: prompt, history: history)
        var request = try authorizedRequest(path: "/ai/chat", method: "POST")
        request.httpBody = try JSONEncoder().encode(chatRequest)
        return try await performRequest(request)
    }

    /// Stream chat message responses token by token
    func streamChatMessage(prompt: String, history: [ChatMessage] = []) async throws -> AsyncThrowingStream<String, Error> {
        let chatRequest = AIChatRequest(prompt: prompt, history: history)
        var request = try authorizedRequest(path: "/ai/chat/stream", method: "POST")
        request.httpBody = try JSONEncoder().encode(chatRequest)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 120 // Longer timeout for streaming

        return AsyncThrowingStream { continuation in
            _Concurrency.Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: APIError.invalidResponse)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        if httpResponse.statusCode == 401 {
                            continuation.finish(throwing: APIError.unauthorized)
                        } else {
                            continuation.finish(throwing: APIError.httpError(httpResponse.statusCode))
                        }
                        return
                    }

                    var buffer = ""

                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))

                        // Handle Server-Sent Events format or newline-delimited JSON
                        if char == "\n" {
                            let line = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

                            if line.hasPrefix("data: ") {
                                // SSE format: "data: {json}"
                                let jsonString = String(line.dropFirst(6))
                                if let data = jsonString.data(using: .utf8),
                                   let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data) {
                                    continuation.yield(chunk.content)
                                }
                            } else if !line.isEmpty && line.first == "{" {
                                // Plain JSON chunks
                                if let data = line.data(using: .utf8),
                                   let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data) {
                                    continuation.yield(chunk.content)
                                }
                            }

                            buffer = ""
                        } else {
                            buffer.append(char)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func getTaskSuggestions(title: String, description: String? = nil) async throws -> AITaskSuggestions {
        let suggestionRequest = AITaskSuggestionsRequest(title: title, description: description)
        var request = try authorizedRequest(path: "/ai/tasks/suggest", method: "POST")
        request.httpBody = try JSONEncoder().encode(suggestionRequest)
        return try await performRequest(request)
    }

    // MARK: - Helper Methods

    internal func authorizedRequest(path: String, method: String) throws -> URLRequest {
        guard let token = token else {
            throw APIError.notAuthenticated
        }

        var request = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    internal func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw APIError.invalidResponse
        }

        print("📡 HTTP Status: \(httpResponse.statusCode)")

        guard (200...299).contains(httpResponse.statusCode) else {
            // Handle 401 Unauthorized first (before trying to decode error response)
            if httpResponse.statusCode == 401 {
                print("❌ Unauthorized - invalid or expired token")
                throw APIError.unauthorized
            }

            // Try to decode error message for other errors
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                print("❌ Server error: \(errorResponse.detail)")
                throw APIError.serverError(errorResponse.detail)
            }

            // Try to get raw response text
            if let responseText = String(data: data, encoding: .utf8) {
                print("❌ Server response (\(httpResponse.statusCode)): \(responseText)")
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
    case invalidCredentials

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
        case .invalidCredentials:
            return "Invalid username or password format"
        }
    }
}

// MARK: - Helper Types

struct EmptyResponse: Codable {}
struct ErrorResponse: Codable {
    let detail: String
}
