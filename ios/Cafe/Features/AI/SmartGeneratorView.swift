//
//  SmartGeneratorView.swift
//  Cafe
//
//  Full-screen modal for AI-powered smart task and list generation
//

import SwiftUI

struct SmartGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager
    @StateObject private var generator = AISmartGenerator.shared

    @State private var prompt = ""
    @State private var showExamples = false
    @State private var generationResult: GenerationResult?
    @State private var selectedTaskIds = Set<UUID>()
    @State private var selectedEventIds = Set<UUID>()
    @State private var selectedSmartListIds = Set<UUID>()
    @State private var showError = false
    @State private var isCreating = false

    @FocusState private var isPromptFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                if generationResult == nil {
                    // Input view
                    inputView
                } else {
                    // Results preview
                    resultsView
                }

                // Generation progress overlay
                if generator.isGenerating {
                    generationOverlay
                }
            }
            .navigationTitle("AI Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if generationResult != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Create Selected") {
                            createSelectedItems()
                        }
                        .disabled(selectedTaskIds.isEmpty && selectedEventIds.isEmpty && selectedSmartListIds.isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showExamples) {
                ExamplePromptsView { selectedPrompt in
                    prompt = selectedPrompt
                    showExamples = false
                    isPromptFocused = true
                }
            }
            .alert("Generation Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = generator.lastError {
                    Text(error.errorDescription ?? "Unknown error")
                }
            }
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 20)

                    Text("What would you like to create?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Describe your tasks, events, or lists in plain English")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Text input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Idea")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextEditor(text: $prompt)
                        .focused($isPromptFocused)
                        .frame(minHeight: 150)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isPromptFocused ? Color.blue : Color.clear, lineWidth: 2)
                        )

                    Text("\(prompt.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Generate button
                Button {
                    generateItems()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                // Example prompts button
                Button {
                    showExamples = true
                } label: {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text("Browse Example Prompts")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal)

                // Quick examples
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Examples")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickExampleCard(
                                icon: "airplane",
                                title: "Trip Planning",
                                example: "Plan a trip to Japan next month"
                            ) {
                                prompt = "Plan a trip to Japan next month"
                            }

                            QuickExampleCard(
                                icon: "birthday.cake.fill",
                                title: "Party Prep",
                                example: "Prepare for Sarah's birthday party"
                            ) {
                                prompt = "Prepare for Sarah's birthday party on Saturday"
                            }

                            QuickExampleCard(
                                icon: "fork.knife",
                                title: "Meal Prep",
                                example: "Weekly meal prep routine"
                            ) {
                                prompt = "Weekly meal prep routine for healthy eating"
                            }

                            QuickExampleCard(
                                icon: "hammer.fill",
                                title: "Home Project",
                                example: "Home renovation project"
                            ) {
                                prompt = "Kitchen renovation project with timeline"
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(.vertical)
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .padding(.top)

                    if let result = generationResult {
                        Text("Generated \(result.totalItemCount) items")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(result.metadata.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button {
                        withAnimation {
                            generationResult = nil
                            selectedTaskIds.removeAll()
                            selectedEventIds.removeAll()
                            selectedSmartListIds.removeAll()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Start Over")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }

                // Generated tasks
                if let tasks = generationResult?.tasks, !tasks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                            Text("Tasks (\(tasks.count))")
                                .font(.headline)
                            Spacer()
                            Button(selectedTaskIds.count == tasks.count ? "Deselect All" : "Select All") {
                                if selectedTaskIds.count == tasks.count {
                                    selectedTaskIds.removeAll()
                                } else {
                                    selectedTaskIds = Set(tasks.map { $0.id })
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)

                        ForEach(tasks) { task in
                            GeneratedTaskPreviewView(
                                task: task,
                                isSelected: selectedTaskIds.contains(task.id)
                            ) {
                                if selectedTaskIds.contains(task.id) {
                                    selectedTaskIds.remove(task.id)
                                } else {
                                    selectedTaskIds.insert(task.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Generated events
                if let events = generationResult?.events, !events.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple)
                            Text("Events (\(events.count))")
                                .font(.headline)
                            Spacer()
                            Button(selectedEventIds.count == events.count ? "Deselect All" : "Select All") {
                                if selectedEventIds.count == events.count {
                                    selectedEventIds.removeAll()
                                } else {
                                    selectedEventIds = Set(events.map { $0.id })
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)

                        ForEach(events) { event in
                            GeneratedEventPreviewView(
                                event: event,
                                isSelected: selectedEventIds.contains(event.id)
                            ) {
                                if selectedEventIds.contains(event.id) {
                                    selectedEventIds.remove(event.id)
                                } else {
                                    selectedEventIds.insert(event.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Smart lists
                if let smartLists = generationResult?.smartLists, !smartLists.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.green)
                            Text("Smart Lists (\(smartLists.count))")
                                .font(.headline)
                            Spacer()
                            Button(selectedSmartListIds.count == smartLists.count ? "Deselect All" : "Select All") {
                                if selectedSmartListIds.count == smartLists.count {
                                    selectedSmartListIds.removeAll()
                                } else {
                                    selectedSmartListIds = Set(smartLists.map { $0.id })
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)

                        ForEach(smartLists) { smartList in
                            GeneratedSmartListPreviewView(
                                smartList: smartList,
                                isSelected: selectedSmartListIds.contains(smartList.id)
                            ) {
                                if selectedSmartListIds.contains(smartList.id) {
                                    selectedSmartListIds.remove(smartList.id)
                                } else {
                                    selectedSmartListIds.insert(smartList.id)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Generation Overlay

    private var generationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated sparkles
                ZStack {
                    ForEach(0..<3) { index in
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(Double(index) * 120))
                            .opacity(generator.isGenerating ? 0.3 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.0)
                                    .repeatForever()
                                    .delay(Double(index) * 0.3),
                                value: generator.isGenerating
                            )
                    }
                }
                .frame(width: 100, height: 100)

                VStack(spacing: 8) {
                    Text(generator.generationProgress.description)
                        .font(.headline)
                        .foregroundColor(.white)

                    ProgressView()
                        .tint(.white)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }

    // MARK: - Actions

    private func generateItems() {
        isPromptFocused = false

        _Concurrency.Task {
            do {
                let result = try await generator.generateFromPrompt(prompt)

                // Auto-select all items
                selectedTaskIds = Set(result.tasks.map { $0.id })
                selectedEventIds = Set(result.events.map { $0.id })
                selectedSmartListIds = Set(result.smartLists.map { $0.id })

                withAnimation {
                    generationResult = result
                }
            } catch {
                showError = true
            }
        }
    }

    private func createSelectedItems() {
        guard let result = generationResult else { return }

        isCreating = true

        _Concurrency.Task {
            do {
                try await generator.createItems(
                    from: result,
                    selectedTaskIds: selectedTaskIds,
                    selectedEventIds: selectedEventIds,
                    selectedSmartListIds: selectedSmartListIds
                )

                // Success - dismiss view
                dismiss()
            } catch {
                showError = true
            }

            isCreating = false
        }
    }
}

// MARK: - Quick Example Card

struct QuickExampleCard: View {
    let icon: String
    let title: String
    let example: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(example)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 140)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    SmartGeneratorView()
}
