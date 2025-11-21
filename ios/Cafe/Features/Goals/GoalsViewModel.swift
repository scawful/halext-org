//
//  GoalsViewModel.swift
//  Cafe
//
//  View model for shared goals
//

import Foundation

@Observable
class GoalsViewModel {
    var goals: [Goal] = []
    var isLoading = false
    var errorMessage: String?
    var preferredContactUsername: String = "magicalgirl"
    
    private let api = APIClient.shared
    
    @MainActor
    func loadGoals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            goals = try await api.getGoals(sharedWith: preferredContactUsername)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    @MainActor
    func createGoal(_ goal: GoalCreate) async throws -> Goal {
        let newGoal = try await api.createGoal(goal)
        goals.insert(newGoal, at: 0)
        return newGoal
    }
    
    @MainActor
    func updateProgress(goalId: Int, progress: Double) async throws {
        let updated = try await api.updateGoalProgress(id: goalId, progress: progress)
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index] = updated
        }
    }
    
    @MainActor
    func addMilestone(goalId: Int, milestone: MilestoneCreate) async throws {
        let newMilestone = try await api.addMilestone(goalId: goalId, milestone: milestone)
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            var updatedGoal = goals[index]
            // Note: This would require Goal to be mutable or we'd need to reconstruct it
            // For now, we'll reload goals after adding a milestone
            await loadGoals()
        }
    }
}

