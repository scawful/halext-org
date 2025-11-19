//
//  APIClient+Admin.swift
//  Cafe
//
//  Admin API endpoints for system management
//

import Foundation

extension APIClient {
    // MARK: - System Statistics

    func getSystemStats() async throws -> SystemStats {
        let request = try authorizedRequest(path: "/admin/stats", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - Server Health

    func getServerHealth() async throws -> ServerHealth {
        let request = try authorizedRequest(path: "/admin/health", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - User Management

    func getAllUsers() async throws -> [AdminUser] {
        let request = try authorizedRequest(path: "/admin/users", method: "GET")
        return try await performRequest(request)
    }

    func getUserById(id: Int) async throws -> AdminUser {
        let request = try authorizedRequest(path: "/admin/users/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func updateUserRole(userId: Int, isAdmin: Bool) async throws -> AdminUser {
        let update = UserRoleUpdate(isAdmin: isAdmin)
        var request = try authorizedRequest(path: "/admin/users/\(userId)/role", method: "PUT")
        request.httpBody = try JSONEncoder().encode(update)
        return try await performRequest(request)
    }

    func updateUserStatus(userId: Int, isActive: Bool) async throws -> AdminUser {
        let update = UserStatusUpdate(isActive: isActive)
        var request = try authorizedRequest(path: "/admin/users/\(userId)/status", method: "PUT")
        request.httpBody = try JSONEncoder().encode(update)
        return try await performRequest(request)
    }

    func deleteUser(userId: Int) async throws {
        let request = try authorizedRequest(path: "/admin/users/\(userId)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    // MARK: - AI Client Management

    func getAIClients() async throws -> [AIClientNode] {
        let request = try authorizedRequest(path: "/admin/ai-clients", method: "GET")
        return try await performRequest(request)
    }

    func getAIClient(id: Int) async throws -> AIClientNode {
        let request = try authorizedRequest(path: "/admin/ai-clients/\(id)", method: "GET")
        return try await performRequest(request)
    }

    func createAIClient(_ client: AIClientNodeCreate) async throws -> AIClientNode {
        var request = try authorizedRequest(path: "/admin/ai-clients", method: "POST")
        request.httpBody = try JSONEncoder().encode(client)
        return try await performRequest(request)
    }

    func updateAIClient(id: Int, update: AIClientNodeUpdate) async throws -> AIClientNode {
        var request = try authorizedRequest(path: "/admin/ai-clients/\(id)", method: "PUT")
        request.httpBody = try JSONEncoder().encode(update)
        return try await performRequest(request)
    }

    func deleteAIClient(id: Int) async throws {
        let request = try authorizedRequest(path: "/admin/ai-clients/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }

    func testAIClientConnection(id: Int) async throws -> ConnectionTestResponse {
        let request = try authorizedRequest(path: "/admin/ai-clients/\(id)/test", method: "POST")
        return try await performRequest(request)
    }

    func getAIClientModels(id: Int) async throws -> [String] {
        struct ModelsResponse: Codable {
            let models: [String]
        }
        let request = try authorizedRequest(path: "/admin/ai-clients/\(id)/models", method: "GET")
        let response: ModelsResponse = try await performRequest(request)
        return response.models
    }

    func healthCheckAllAIClients() async throws -> [[String: Any]] {
        struct HealthCheckResponse: Codable {
            let results: [[String: String]]
        }
        let request = try authorizedRequest(path: "/admin/ai-clients/health-check-all", method: "POST")
        let response: HealthCheckResponse = try await performRequest(request)
        // Convert to [String: Any] for flexibility
        return response.results.map { dict in
            dict.mapValues { $0 as Any }
        }
    }

    // MARK: - Content Management (CMS)

    func getSitePages() async throws -> [SitePage] {
        let request = try authorizedRequest(path: "/content/admin/pages", method: "GET")
        return try await performRequest(request)
    }

    func getPhotoAlbums() async throws -> [PhotoAlbum] {
        let request = try authorizedRequest(path: "/content/admin/photo-albums", method: "GET")
        return try await performRequest(request)
    }

    func getBlogPosts() async throws -> [BlogPost] {
        let request = try authorizedRequest(path: "/content/admin/blog-posts", method: "GET")
        return try await performRequest(request)
    }

    // MARK: - System Actions

    func clearCache() async throws -> CacheClearResponse {
        let request = try authorizedRequest(path: "/admin/cache/clear", method: "POST")
        return try await performRequest(request)
    }

    func rebuildFrontend() async throws -> RebuildResponse {
        let request = try authorizedRequest(path: "/admin/rebuild-frontend", method: "POST")
        return try await performRequest(request)
    }

    func rebuildIndexes() async throws -> RebuildResponse {
        let request = try authorizedRequest(path: "/admin/rebuild-indexes", method: "POST")
        return try await performRequest(request)
    }
}
