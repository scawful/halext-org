//
//  GoalsView.swift
//  Cafe
//
//  List of shared goals with Chris
//

import SwiftUI

struct GoalsView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var viewModel = GoalsViewModel()
    @State private var showingNewGoal = false
    @State private var searchText = ""

    var filteredGoals: [Goal] {
        if searchText.isEmpty {
            return viewModel.goals
        }
        return viewModel.goals.filter { goal in
            goal.title.localizedCaseInsensitiveContains(searchText) ||
            (goal.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredGoals.isEmpty && searchText.isEmpty {
                    EmptyGoalsView(onCreateGoal: { showingNewGoal = true })
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredGoals) { goal in
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
            .searchable(text: $searchText, prompt: "Search goals")
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
    @Environment(ThemeManager.self) var themeManager
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
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(themeManager.accentColor)
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
                        .foregroundColor(themeManager.secondaryTextColor)
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
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Empty State

struct EmptyGoalsView: View {
    let onCreateGoal: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Goals", systemImage: "target")
        } description: {
            Text("Create your first shared goal together")
        } actions: {
            Button(action: onCreateGoal) {
                Text("Create Goal")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    GoalsView()
}

