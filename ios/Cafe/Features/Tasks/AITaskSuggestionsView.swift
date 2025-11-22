//
//  AITaskSuggestionsView.swift
//  Cafe
//
//  AI-powered task suggestions view
//

import SwiftUI

struct AITaskSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let description: String?
    
    @State private var suggestions: AITaskSuggestionsResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Selection state
    @State private var selectedSubtasks: Set<Int> = []
    @State private var selectedLabels: Set<Int> = []
    @State private var acceptTimeEstimate = false
    @State private var acceptPriority = false
    
    var onApply: ((AITaskSuggestionsResponse, Set<Int>, Set<Int>, Bool, Bool) -> Void)?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Getting AI suggestions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let suggestions = suggestions {
                    suggestionsContent(suggestions)
                } else if let error = errorMessage {
                    errorContent(error)
                } else {
                    emptyState
                }
            }
            .navigationTitle("AI Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if suggestions != nil {
                        Button("Apply") {
                            applySuggestions()
                        }
                    }
                }
            }
            .task {
                await loadSuggestions()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No suggestions yet")
                .font(.headline)
            Text("Tap the refresh button to get AI suggestions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private func errorContent(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Failed to load suggestions")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                _Concurrency.Task {
                    await loadSuggestions()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func suggestionsContent(_ suggestions: AITaskSuggestionsResponse) -> some View {
        Form {
            // Subtasks Section
            if !suggestions.subtasks.isEmpty {
                Section {
                    ForEach(Array(suggestions.subtasks.enumerated()), id: \.offset) { index, subtask in
                        HStack {
                            Button(action: {
                                if selectedSubtasks.contains(index) {
                                    selectedSubtasks.remove(index)
                                } else {
                                    selectedSubtasks.insert(index)
                                }
                            }) {
                                Image(systemName: selectedSubtasks.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedSubtasks.contains(index) ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            
                            Text(subtask)
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Suggested Subtasks")
                } footer: {
                    Text("Select subtasks to add to your task")
                }
            }
            
            // Time Estimate Section
            Section {
                Toggle("Use time estimate", isOn: $acceptTimeEstimate)
                if acceptTimeEstimate {
                    HStack {
                        Text("Estimated time")
                        Spacer()
                        Text("\(Int(suggestions.estimatedHours * 60)) minutes")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Time Estimate")
            }
            
            // Priority Section
            Section {
                Toggle("Use suggested priority", isOn: $acceptPriority)
                if acceptPriority {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Priority")
                            Spacer()
                            Text(suggestions.priority.capitalized)
                                .foregroundColor(priorityColor(suggestions.priority))
                                .fontWeight(.semibold)
                        }
                        if !suggestions.priorityReasoning.isEmpty {
                            Text(suggestions.priorityReasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Priority Suggestion")
            }
            
            // Labels Section
            if !suggestions.labels.isEmpty {
                Section {
                    ForEach(Array(suggestions.labels.enumerated()), id: \.offset) { index, label in
                        HStack {
                            Button(action: {
                                if selectedLabels.contains(index) {
                                    selectedLabels.remove(index)
                                } else {
                                    selectedLabels.insert(index)
                                }
                            }) {
                                Image(systemName: selectedLabels.contains(index) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedLabels.contains(index) ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            
                            Text(label)
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Suggested Labels")
                } footer: {
                    Text("Select labels to add to your task")
                }
            }
        }
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent", "high":
            return .red
        case "medium":
            return .orange
        case "low":
            return .blue
        default:
            return .secondary
        }
    }
    
    private func loadSuggestions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            suggestions = try await APIClient.shared.suggestTaskEnhancements(
                title: title,
                description: description
            )
            // Auto-select all by default
            selectedSubtasks = Set(0..<suggestions!.subtasks.count)
            selectedLabels = Set(0..<suggestions!.labels.count)
            acceptTimeEstimate = true
            acceptPriority = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func applySuggestions() {
        guard let suggestions = suggestions else { return }
        onApply?(suggestions, selectedSubtasks, selectedLabels, acceptTimeEstimate, acceptPriority)
        dismiss()
    }
}

