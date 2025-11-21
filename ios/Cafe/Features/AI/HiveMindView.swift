//
//  HiveMindView.swift
//  Cafe
//
//  Hive Mind goal management and collaboration features
//

import SwiftUI

struct HiveMindView: View {
    let conversationId: Int
    @State private var goal: String = ""
    @State private var summary: String?
    @State private var nextSteps: [String] = []
    @State private var isLoading = false
    @State private var isSettingGoal = false
    @State private var isFetchingSummary = false
    @State private var isFetchingNextSteps = false
    @State private var error: String?
    @State private var conversation: Conversation?
    
    private let api = APIClient.shared
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Set a collaborative goal for this conversation. The AI will help track progress and suggest next steps.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter goal...", text: $goal, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    
                    Button(action: setGoal) {
                        HStack {
                            if isSettingGoal {
                                ProgressView()
                            } else {
                                Image(systemName: "target")
                            }
                            Text(goal.isEmpty ? "Set Goal" : "Update Goal")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSettingGoal)
                }
                .padding(.vertical, 4)
            } header: {
                Label("Hive Mind Goal", systemImage: "brain")
            }
            
            if let currentGoal = conversation?.hiveMindGoal, !currentGoal.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "target.fill")
                                .foregroundColor(.orange)
                            Text(currentGoal)
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        Button(action: fetchSummary) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("View Summary")
                                Spacer()
                                if isFetchingSummary {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .disabled(isFetchingSummary)
                        
                        Button(action: fetchNextSteps) {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                Text("Next Steps")
                                Spacer()
                                if isFetchingNextSteps {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        .disabled(isFetchingNextSteps)
                    }
                } header: {
                    Label("Current Goal", systemImage: "checkmark.circle")
                }
                
                if let summary = summary {
                    Section {
                        Text(summary)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 4)
                    } header: {
                        Label("Summary", systemImage: "doc.text")
                    }
                }
                
                if !nextSteps.isEmpty {
                    Section {
                        ForEach(Array(nextSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                
                                Text(step)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Label("Suggested Next Steps", systemImage: "arrow.right.circle")
                    }
                }
            }
        }
        .navigationTitle("Hive Mind")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadConversation()
        }
        .alert("Error", isPresented: Binding(get: { error != nil }, set: { _ in error = nil })) {
            Button("OK", role: .cancel) { error = nil }
        } message: {
            Text(error ?? "")
        }
    }
    
    private func loadConversation() async {
        do {
            conversation = try await api.getConversation(id: conversationId)
            goal = conversation?.hiveMindGoal ?? ""
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    private func setGoal() {
        guard !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSettingGoal = true
        error = nil
        
        _Concurrency.Task { @MainActor in
            do {
                conversation = try await api.setHiveMindGoal(conversationId: conversationId, goal: goal.trimmingCharacters(in: .whitespacesAndNewlines))
                summary = nil
                nextSteps = []
            } catch {
                self.error = error.localizedDescription
            }
            isSettingGoal = false
        }
    }
    
    private func fetchSummary() {
        isFetchingSummary = true
        error = nil
        
        _Concurrency.Task { @MainActor in
            do {
                summary = try await api.getHiveMindSummary(conversationId: conversationId)
            } catch {
                self.error = error.localizedDescription
            }
            isFetchingSummary = false
        }
    }
    
    private func fetchNextSteps() {
        isFetchingNextSteps = true
        error = nil
        
        _Concurrency.Task { @MainActor in
            do {
                nextSteps = try await api.getHiveMindNextSteps(conversationId: conversationId)
            } catch {
                self.error = error.localizedDescription
            }
            isFetchingNextSteps = false
        }
    }
}
