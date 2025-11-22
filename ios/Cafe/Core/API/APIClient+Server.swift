//
//  APIClient+Server.swift
//  Cafe
//
//  Server management and monitoring endpoints
//

import Foundation

extension APIClient {
    // MARK: - Server Statistics
    
    func getServerStats() async throws -> ServerStats {
        let request = try authorizedRequest(path: "/admin/server/stats", method: "GET")
        return try await performRequest(request)
    }
    
    // MARK: - Server Actions
    
    func restartAPIServer() async throws -> AdminActionResponse {
        let request = try authorizedRequest(path: "/admin/server/restart", method: "POST")
        return try await performRequest(request)
    }
    
    func syncDatabase() async throws -> AdminActionResponse {
        let request = try authorizedRequest(path: "/admin/database/sync", method: "POST")
        return try await performRequest(request)
    }
    
    // MARK: - Server Logs
    
    func getServerLogs(level: String = "all", limit: Int = 100) async throws -> [String] {
        let request = try authorizedRequest(path: "/admin/logs?level=\(level)&limit=\(limit)", method: "GET")
        let response: LogsResponse = try await performRequest(request)
        return response.logs
    }
}

// MARK: - Response Models

struct AdminActionResponse: Codable {
    let success: Bool
    let message: String
    let itemsCleared: Int?
    
    enum CodingKeys: String, CodingKey {
        case success, message
        case itemsCleared = "items_cleared"
    }
}

struct LogsResponse: Codable {
    let logs: [String]
    let count: Int
    let level: String
}

