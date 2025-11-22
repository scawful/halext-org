//
//  APIClient.swift
//  Cafe
//
//  Network client for Halext Org API
//

import Foundation

// MARK: - Token Expiration Notification

extension Notification.Name {
    static let tokenExpired = Notification.Name("tokenExpired")
}

enum APIEnvironment {
    case development
    case production

    var baseURL: String {
        switch self {
        case .development:
            return "http://127.0.0.1:8000/api"
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

        #if DEBUG
        print("🔐 Attempting login to: \(loginURL)")
        print("🌍 Using environment: \(environment)")
        print("👤 Username: '\(username)' (length: \(username.count))")
        print("🔑 Password length: \(password.count)")
        #endif

        var request = URLRequest(url: URL(string: loginURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formData.data(using: .utf8)

        #if DEBUG
        // Log headers (mask sensitive values)
        if let headers = request.allHTTPHeaderFields {
            print("📋 Headers: \(headers)")
        }
        #endif

        let response: TokenResponse = try await performRequest(request)
        
        #if DEBUG
        print("✅ Login successful, got token")
        #endif

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

    /// Delete the current user's account
    /// This is a destructive operation that permanently removes all user data
    func deleteAccount() async throws {
        let request = try authorizedRequest(path: "/users/me/", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)

        #if DEBUG
        print("Account deletion request completed successfully")
        #endif
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

    func sendChatMessage(prompt: String, history: [ChatMessage] = [], model: String? = nil) async throws -> AIChatResponse {
        let chatRequest = AIChatRequest(prompt: prompt, history: history, model: model)
        var request = try authorizedRequest(path: "/ai/chat", method: "POST")
        request.httpBody = try JSONEncoder().encode(chatRequest)
        return try await performRequest(request)
    }

    /// Stream chat message responses token by token
    func streamChatMessage(prompt: String, history: [ChatMessage] = [], model: String? = nil) async throws -> ChatStreamResult {
        let chatRequest = AIChatRequest(prompt: prompt, history: history, model: model)
        var request = try authorizedRequest(path: "/ai/chat/stream", method: "POST")
        request.httpBody = try JSONEncoder().encode(chatRequest)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 120 // Longer timeout for streaming

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        let resolvedModel = httpResponse.value(forHTTPHeaderField: "X-Halext-AI-Model")

        let stream = AsyncThrowingStream<String, Error> { continuation in
            _Concurrency.Task.detached {
                do {
                    var buffer = ""

                    for try await byte in bytes {
                        let char = Character(UnicodeScalar(byte))

                        if char == "\n" {
                            let line = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

                            if line.hasPrefix("data: ") {
                                let jsonString = String(line.dropFirst(6))
                                if let data = jsonString.data(using: .utf8),
                                   let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data) {
                                    continuation.yield(chunk.content)
                                }
                            } else if !line.isEmpty && line.first == "{" {
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

        return ChatStreamResult(stream: stream, modelIdentifier: resolvedModel)
    }

    func getTaskSuggestions(title: String, description: String? = nil, context: TaskSuggestionContext? = nil) async throws -> AITaskSuggestions {
        let suggestionRequest = AITaskSuggestionsRequest(title: title, description: description, context: context)
        var request = try authorizedRequest(path: "/ai/tasks/suggest", method: "POST")
        request.httpBody = try JSONEncoder().encode(suggestionRequest)
        return try await performRequest(request)
    }

    // MARK: - Helper Methods

    internal func authorizedRequest(path: String, method: String) throws -> URLRequest {
        guard let token = token else {
            #if DEBUG
            print("❌ No token available for authorized request to \(path)")
            #endif
            throw APIError.notAuthenticated
        }

        #if DEBUG
        // Debug logging (mask token for security)
        let tokenPreview = token.count > 10 ? String(token.prefix(10)) + "..." : token
        print("🔐 Creating authorized request to \(path)")
        print("   Token preview: \(tokenPreview) (length: \(token.count))")
        print("   Base URL: \(baseURL)")
        #endif

        var request = URLRequest(url: URL(string: "\(baseURL)\(path)")!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let code = accessCode {
            request.setValue(code, forHTTPHeaderField: "X-Halext-Code")
            #if DEBUG
            print("   Access code: \(code.prefix(4))...")
            #endif
        }

        #if DEBUG
        // Log all headers (mask sensitive values)
        if let headers = request.allHTTPHeaderFields {
            print("   Headers:")
            for (key, value) in headers {
                if key == "Authorization" {
                    let tokenPreview = token.count > 10 ? String(token.prefix(10)) + "..." : token
                    print("     \(key): Bearer \(tokenPreview)")
                } else {
                    print("     \(key): \(value)")
                }
            }
        }
        #endif

        return request
    }

    internal func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, _) = try await executeRequest(request)

        // Handle empty response for DELETE requests
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        return try decodeResponse(T.self, from: data)
    }

    /// Executes a request with automatic retry for transient errors.
    /// Retries up to 3 times with exponential backoff for network errors and 5xx server errors.
    internal func executeRequest(_ request: URLRequest, retryCount: Int = 0) async throws -> (Data, HTTPURLResponse) {
        let maxRetries = 3
        let baseDelay: TimeInterval = 1.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                #if DEBUG
                print("❌ Invalid HTTP response")
                #endif
                throw APIError.invalidResponse
            }

            #if DEBUG
            print("📡 HTTP Status: \(httpResponse.statusCode) for \(request.url?.absoluteString ?? "unknown URL")")
            #endif

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    #if DEBUG
                    // Enhanced 401 error diagnostics (debug only)
                    let authHeader = request.value(forHTTPHeaderField: "Authorization")
                    let hasAuth = authHeader != nil && !authHeader!.isEmpty
                    print("❌ Unauthorized (401) - Request to: \(request.url?.absoluteString ?? "unknown")")
                    print("   Has Authorization header: \(hasAuth)")
                    if let auth = authHeader {
                        let preview = auth.count > 20 ? String(auth.prefix(20)) + "..." : auth
                        print("   Auth header preview: \(preview)")
                    }
                    
                    // Check if token exists in keychain
                    let tokenExists = KeychainManager.shared.getToken() != nil
                    print("   Token exists in keychain: \(tokenExists)")
                    
                    // Log response body if available (might contain error details)
                    if let responseBody = String(data: data, encoding: .utf8), !responseBody.isEmpty {
                        print("   Response body: \(responseBody.prefix(200))")
                    }
                    #endif
                    
                    // Post notification for token expiration
                    NotificationCenter.default.post(name: .tokenExpired, object: nil)
                    
                    throw APIError.unauthorized
                }
                
                // Retry on 5xx server errors (transient failures)
                if (500...599).contains(httpResponse.statusCode) && retryCount < maxRetries {
                    let delay = baseDelay * pow(2.0, Double(retryCount))
                    #if DEBUG
                    print("⚠️ Server error \(httpResponse.statusCode), retrying in \(delay)s (attempt \(retryCount + 1)/\(maxRetries))")
                    #endif
                    try await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await executeRequest(request, retryCount: retryCount + 1)
                }

                // Check if response is HTML (like nginx 502 Bad Gateway)
                if let responseText = String(data: data, encoding: .utf8),
                   responseText.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<html") {
                    let errorMessage: String
                    if httpResponse.statusCode == 502 {
                        errorMessage = "Backend server is unavailable. Please try again later."
                    } else if httpResponse.statusCode == 503 {
                        errorMessage = "Service temporarily unavailable. Please try again later."
                    } else if httpResponse.statusCode == 504 {
                        errorMessage = "Gateway timeout. The server took too long to respond."
                    } else {
                        errorMessage = "Server error. Please try again later."
                    }
                    #if DEBUG
                    print("❌ HTML error response (\(httpResponse.statusCode)): \(errorMessage)")
                    #endif
                    throw APIError.serverError(errorMessage)
                }

                // Try to decode as JSON error response
                if let errorResponse = try? decodeResponse(ErrorResponse.self, from: data) {
                    #if DEBUG
                    print("❌ Server error: \(errorResponse.detail)")
                    #endif
                    throw APIError.serverError(errorResponse.detail)
                }

                #if DEBUG
                // Fallback: use status code
                if let responseText = String(data: data, encoding: .utf8) {
                    print("❌ Server response (\(httpResponse.statusCode)): \(responseText.prefix(200))")
                }
                #endif

                throw APIError.httpError(httpResponse.statusCode)
            }

            return (data, httpResponse)
        } catch let error as URLError {
            // Retry on network errors (transient failures)
            if (error.code == .timedOut || error.code == .networkConnectionLost || error.code == .notConnectedToInternet) && retryCount < maxRetries {
                let delay = baseDelay * pow(2.0, Double(retryCount))
                #if DEBUG
                print("⚠️ Network error (\(error.localizedDescription)), retrying in \(delay)s (attempt \(retryCount + 1)/\(maxRetries))")
                #endif
                try await _Concurrency.Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeRequest(request, retryCount: retryCount + 1)
            }
            throw error
        }
    }

    /// Decodes an API response with consistent decoding strategies.
    internal func decodeResponse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        // Check if response is HTML (like nginx error pages)
        if let responseText = String(data: data, encoding: .utf8),
           responseText.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("<html") {
            #if DEBUG
            print("❌ Attempted to decode HTML as JSON")
            #endif
            throw APIError.decodingError
        }
        
        let decoder = JSONDecoder()
        // Custom date decoding that handles both with and without 'Z' suffix
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 formatters first
            let isoFormatter1 = ISO8601DateFormatter()
            if let date = isoFormatter1.date(from: dateString) {
                return date
            }
            
            let isoFormatter2 = ISO8601DateFormatter()
            isoFormatter2.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFormatter2.date(from: dateString) {
                return date
            }
            
            // Try DateFormatter for dates without 'Z'
            let dateFormatter1 = DateFormatter()
            dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            dateFormatter1.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter1.date(from: dateString) {
                return date
            }
            
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter2.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter2.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted."
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("❌ Decoding error:", error)
            if let responseText = String(data: data, encoding: .utf8) {
                // Only print first 200 chars to avoid spam
                let preview = responseText.count > 200 ? String(responseText.prefix(200)) + "..." : responseText
                print("Response data preview:", preview)
            } else {
                print("Response data: Unable to decode as UTF-8")
            }
            #endif
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
            return "Unable to connect to the server. Please check your internet connection and try again."
        case .httpError(let code):
            switch code {
            case 400:
                return "Invalid request. Please try again."
            case 404:
                return "The requested resource was not found."
            case 500...599:
                return "Server error. Please try again in a moment."
            default:
                return "Connection error. Please try again."
            }
        case .decodingError:
            return "Received unexpected data from the server. Please try again."
        case .notAuthenticated:
            return "Please sign in to continue."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .serverError(let message):
            return message
        case .invalidCredentials:
            return "Invalid username or password. Please check your credentials and try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidResponse, .httpError:
            return "Check your internet connection and try again."
        case .unauthorized, .notAuthenticated:
            return "Please sign in again to continue."
        case .decodingError:
            return "The app may need to be updated. Please check for updates."
        case .serverError:
            return "The server may be temporarily unavailable. Please try again in a moment."
        case .invalidCredentials:
            return "Make sure your username and password are correct."
        }
    }
}

// MARK: - Helper Types

struct EmptyResponse: Codable {}
struct ErrorResponse: Codable {
    let detail: String
}

struct ChatStreamResult {
    let stream: AsyncThrowingStream<String, Error>
    let modelIdentifier: String?
}
