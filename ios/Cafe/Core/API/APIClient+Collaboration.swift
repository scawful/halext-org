//
//  APIClient+Collaboration.swift
//  Cafe
//
//  Collaboration API endpoints for shared features
//

import Foundation

extension APIClient {
    // MARK: - Shared Events
    
    func getSharedEvents() async throws -> [Event] {
        let request = try authorizedRequest(path: "/events/shared", method: "GET")
        return try await performRequest(request)
    }
    
    func createSharedEvent(_ event: EventCreate, sharedWith: [String]) async throws -> Event {
        struct SharedEventCreate: Codable {
            let title: String
            let description: String?
            let startTime: Date
            let endTime: Date
            let location: String?
            let sharedWith: [String]
            
            enum CodingKeys: String, CodingKey {
                case title, description, location
                case startTime = "start_time"
                case endTime = "end_time"
                case sharedWith = "shared_with"
            }
        }
        
        var request = try authorizedRequest(path: "/events/", method: "POST")
        let body = SharedEventCreate(
            title: event.title,
            description: event.description,
            startTime: event.startTime,
            endTime: event.endTime,
            location: event.location,
            sharedWith: sharedWith
        )
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }
    
    func updateEventSharing(eventId: Int, sharedWith: [String]) async throws -> Event {
        struct EventShareUpdate: Codable {
            let sharedWith: [String]
            
            enum CodingKeys: String, CodingKey {
                case sharedWith = "shared_with"
            }
        }
        
        var request = try authorizedRequest(path: "/events/\(eventId)/share", method: "PUT")
        let body = EventShareUpdate(sharedWith: sharedWith)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }
    
    // MARK: - Shared Memories
    
    func getMemories(sharedWith: String? = nil) async throws -> [Memory] {
        var path = "/memories"
        if let sharedWith = sharedWith {
            path += "?shared_with=\(sharedWith.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        let request = try authorizedRequest(path: path, method: "GET")
        return try await performRequest(request)
    }
    
    func createMemory(_ memory: MemoryCreate) async throws -> Memory {
        var request = try authorizedRequest(path: "/memories", method: "POST")
        request.httpBody = try JSONEncoder().encode(memory)
        return try await performRequest(request)
    }
    
    func updateMemory(id: Int, _ memory: MemoryUpdate) async throws -> Memory {
        var request = try authorizedRequest(path: "/memories/\(id)", method: "PUT")
        request.httpBody = try JSONEncoder().encode(memory)
        return try await performRequest(request)
    }
    
    func deleteMemory(id: Int) async throws {
        let request = try authorizedRequest(path: "/memories/\(id)", method: "DELETE")
        let _: EmptyResponse = try await performRequest(request)
    }
    
    // MARK: - Shared Goals
    
    func getGoals(sharedWith: String? = nil) async throws -> [Goal] {
        var path = "/goals"
        if let sharedWith = sharedWith {
            path += "?shared_with=\(sharedWith.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        let request = try authorizedRequest(path: path, method: "GET")
        return try await performRequest(request)
    }
    
    func createGoal(_ goal: GoalCreate) async throws -> Goal {
        var request = try authorizedRequest(path: "/goals", method: "POST")
        request.httpBody = try JSONEncoder().encode(goal)
        return try await performRequest(request)
    }
    
    func updateGoalProgress(id: Int, progress: Double) async throws -> Goal {
        struct GoalProgressUpdate: Codable {
            let progress: Double
        }
        
        var request = try authorizedRequest(path: "/goals/\(id)/progress", method: "PUT")
        let body = GoalProgressUpdate(progress: progress)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }
    
    func addMilestone(goalId: Int, milestone: MilestoneCreate) async throws -> Milestone {
        var request = try authorizedRequest(path: "/goals/\(goalId)/milestones", method: "POST")
        request.httpBody = try JSONEncoder().encode(milestone)
        return try await performRequest(request)
    }
    
    // MARK: - Partner Presence
    
    func getPartnerPresence(username: String) async throws -> PartnerPresence {
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let request = try authorizedRequest(path: "/users/\(encodedUsername)/presence", method: "GET")
        return try await performRequest(request)
    }
    
    // MARK: - Quick Message
    
    func sendQuickMessage(to username: String, content: String) async throws -> Message {
        struct QuickMessageCreate: Codable {
            let username: String
            let content: String
        }
        
        var request = try authorizedRequest(path: "/messages/quick", method: "POST")
        let body = QuickMessageCreate(username: username, content: content)
        request.httpBody = try JSONEncoder().encode(body)
        return try await performRequest(request)
    }
}

