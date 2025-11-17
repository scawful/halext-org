import Foundation

struct HalextAPI {
    var baseURL = URL(string: "https://org.halext.org/api")!

    func login(username: String, password: String, accessCode: String) async throws -> String {
        var request = URLRequest(url: baseURL.appending(path: "/token"))
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue(accessCode, forHTTPHeaderField: "X-Halext-Code")
        let body = "username=\(username)&password=\(password)&grant_type=password"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard http.statusCode == 200 else {
            throw NSError(domain: "HalextAPI", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Login failed (\(http.statusCode))",
            ])
        }
        let token = try JSONDecoder().decode(TokenResponse.self, from: data)
        return token.access_token
    }

    func fetchTasks(token: String, accessCode: String) async throws -> [TaskSummary] {
        try await request(path: "/tasks/", token: token, accessCode: accessCode)
    }

    func fetchEvents(token: String, accessCode: String) async throws -> [EventSummary] {
        try await request(path: "/events/", token: token, accessCode: accessCode)
    }

    func fetchLayoutPresets(token: String, accessCode: String) async throws -> [LayoutPreset] {
        try await request(path: "/layout-presets/", token: token, accessCode: accessCode)
    }

    func applyPresetToPage(pageId: Int, presetId: Int, token: String, accessCode: String) async throws {
        var request = URLRequest(url: baseURL.appending(path: "/pages/\(pageId)/apply-preset/\(presetId)"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(accessCode, forHTTPHeaderField: "X-Halext-Code")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    private func request<T: Decodable>(path: String, token: String, accessCode: String) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue(accessCode, forHTTPHeaderField: "X-Halext-Code")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

private struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
}
