//
//  GoalsView.swift
//  Cafe
//
//  List of shared goals with Chris
//

import SwiftUI

struct GoalsView: View {
    @State private var viewModel = GoalsViewModel()
    @State private var showingNewGoal = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.goals.isEmpty {
                    EmptyGoalsView(onCreateGoal: { showingNewGoal = true })
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.goals) { goal in
                                NavigationLink {
                                    GoalProgressView(goal: goal, viewModel: viewModel)
                                } label: {
                                    GoalCard(goal: goal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewGoal) {
                NewGoalView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadGoals()
            }
            .refreshable {
                await viewModel.loadGoals()
            }
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                    
                    if let description = goal.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.pink)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(goal.milestones.filter { $0.completed }.count)/\(goal.milestones.count) milestones")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(goal.progress), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeManager.shared.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Empty State

struct EmptyGoalsView: View {
    let onCreateGoal: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Goals Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first shared goal together")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateGoal) {
                Label("Create Goal", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    GoalsView()
}

