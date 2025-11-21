//
//  GoalProgressView.swift
//  Cafe
//
//  Detailed view of a goal with progress tracking and milestones
//

import SwiftUI

struct GoalProgressView: View {
    let goal: Goal
    let viewModel: GoalsViewModel
    
    @State private var showingNewMilestone = false
    @State private var newMilestoneTitle = ""
    @State private var isUpdatingProgress = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let description = goal.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Progress section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(Int(goal.progress * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 16)
                                .cornerRadius(8)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(goal.progress), height: 16)
                                .cornerRadius(8)
                        }
                    }
                    .frame(height: 16)
                    
                    // Progress slider
                    Slider(value: Binding(
                        get: { goal.progress },
                        set: { newValue in
                            updateProgress(newValue)
                        }
                    ), in: 0...1)
                    .disabled(isUpdatingProgress)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ThemeManager.shared.cardBackgroundColor)
                )
                
                // Milestones
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Milestones")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showingNewMilestone = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if goal.milestones.isEmpty {
                        Text("No milestones yet. Add one to track your progress!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(goal.milestones) { milestone in
                            MilestoneRow(milestone: milestone)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ThemeManager.shared.cardBackgroundColor)
                )
            }
            .padding()
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNewMilestone) {
            NavigationStack {
                Form {
                    TextField("Milestone Title", text: $newMilestoneTitle)
                }
                .navigationTitle("New Milestone")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingNewMilestone = false
                            newMilestoneTitle = ""
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            addMilestone()
                        }
                        .disabled(newMilestoneTitle.isEmpty)
                    }
                }
            }
        }
    }
    
    private func updateProgress(_ newValue: Double) {
        isUpdatingProgress = true
        _Concurrency.Task {
            do {
                try await viewModel.updateProgress(goalId: goal.id, progress: newValue)
            } catch {
                // Handle error
            }
            await MainActor.run {
                isUpdatingProgress = false
            }
        }
    }
    
    private func addMilestone() {
        let milestone = MilestoneCreate(
            title: newMilestoneTitle,
            description: nil
        )
        
        _Concurrency.Task {
            do {
                try await viewModel.addMilestone(goalId: goal.id, milestone: milestone)
                await MainActor.run {
                    showingNewMilestone = false
                    newMilestoneTitle = ""
                }
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: Milestone
    
    var body: some View {
        HStack {
            Image(systemName: milestone.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(milestone.completed ? .green : .secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .strikethrough(milestone.completed)
                
                if let description = milestone.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if milestone.completed, let completedAt = milestone.completedAt {
                Text(completedAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        GoalProgressView(
            goal: Goal(
                id: 1,
                title: "Sample Goal",
                description: "This is a sample goal",
                progress: 0.5,
                sharedWith: ["magicalgirl"],
                milestones: [],
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: 1
            ),
            viewModel: GoalsViewModel()
        )
    }
}

