//
//  APIClient+Social.swift
//  Cafe
//
//  Backend-powered social circles
//

import Foundation

extension APIClient {
    func getBackendCircles() async throws -> [BackendSocialCircle] {
        let request = try authorizedRequest(path: "/social/circles", method: "GET")
        return try await performRequest(request)
    }

    func createBackendCircle(payload: BackendCircleCreate) async throws -> BackendSocialCircle {
        var request = try authorizedRequest(path: "/social/circles", method: "POST")
        request.httpBody = try JSONEncoder().encode(payload)
        return try await performRequest(request)
    }

    func joinBackendCircle(inviteCode: String) async throws -> BackendSocialCircle {
        let encoded = inviteCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inviteCode
        let path = "/social/circles/join?invite_code=\(encoded)"
        let request = try authorizedRequest(path: path, method: "POST")
        return try await performRequest(request)
    }

    func getBackendPulses(circleId: Int) async throws -> [BackendSocialPulse] {
        let request = try authorizedRequest(path: "/social/circles/\(circleId)/pulses", method: "GET")
        return try await performRequest(request)
    }

    func shareBackendPulse(circleId: Int, payload: BackendSocialPulseCreate) async throws -> BackendSocialPulse {
        var request = try authorizedRequest(path: "/social/circles/\(circleId)/pulses", method: "POST")
        request.httpBody = try JSONEncoder().encode(payload)
        return try await performRequest(request)
    }
}

struct BackendSocialCircle: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let emoji: String?
    let themeColor: String?
    let inviteCode: String
    let memberCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, emoji
        case themeColor = "theme_color"
        case inviteCode = "invite_code"
        case memberCount = "member_count"
    }
}

struct BackendCircleCreate: Codable {
    let name: String
    let description: String?
    let emoji: String?
    let themeColor: String?

    enum CodingKeys: String, CodingKey {
        case name, description, emoji
        case themeColor = "theme_color"
    }
}

struct BackendSocialPulse: Codable, Identifiable {
    let id: Int
    let circleId: Int
    let authorId: Int
    let authorName: String?
    let message: String
    let mood: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case circleId = "circle_id"
        case authorId = "author_id"
        case authorName = "author_name"
        case message, mood
        case createdAt = "created_at"
    }
}

struct BackendSocialPulseCreate: Codable {
    let message: String
    let mood: String?
}
