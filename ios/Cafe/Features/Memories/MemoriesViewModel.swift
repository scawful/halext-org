//
//  MemoriesViewModel.swift
//  Cafe
//
//  View model for shared memories
//

import Foundation

@Observable
class MemoriesViewModel {
    var memories: [Memory] = []
    var isLoading = false
    var errorMessage: String?
    var preferredContactUsername: String = "magicalgirl"
    
    private let api = APIClient.shared
    
    @MainActor
    func loadMemories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            memories = try await api.getMemories(sharedWith: preferredContactUsername)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func createMemory(_ memory: MemoryCreate) async throws -> Memory {
        let newMemory = try await api.createMemory(memory)
        memories.insert(newMemory, at: 0)
        return newMemory
    }
    
    @MainActor
    func deleteMemory(id: Int) async throws {
        try await api.deleteMemory(id: id)
        memories.removeAll(where: { $0.id == id })
    }
}

