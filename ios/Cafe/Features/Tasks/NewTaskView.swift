//
//  NewTaskView.swift
//  Cafe
//
//  Form for creating new tasks
//

import SwiftUI

struct NewTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (TaskCreate) async -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var labels: [String] = []
    @State private var labelInput = ""
    @State private var isCreating = false

    @State private var showingAISuggestions = false
    @State private var aiSuggestions: AITaskSuggestions?
    @State private var isLoadingSuggestions = false

    private var isValid: Bool {
        !title.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)

                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "Due Date",
                            selection: Binding(
                                get: { dueDate ?? Date() },
                                set: { dueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section("Labels") {
                    HStack {
                        TextField("Add label", text: $labelInput)
                            .textInputAutocapitalization(.never)

                        Button(action: {
                            if !labelInput.isEmpty {
                                labels.append(labelInput)
                                labelInput = ""
                            }
                        }) {
                            Text("Add")
                        }
                        .disabled(labelInput.isEmpty)
                    }

                    if !labels.isEmpty {
                        ForEach(labels, id: \.self) { label in
                            HStack {
                                Text(label)
                                Spacer()
                                Button(action: {
                                    labels.removeAll { $0 == label }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section {
                    Button(action: {
                        showingAISuggestions = true
                        Task { @MainActor in
                            await loadAISuggestions()
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Get AI Suggestions")
                            Spacer()
                            if isLoadingSuggestions {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(title.isEmpty || isLoadingSuggestions)
                } header: {
                    Text("AI Assistant")
                } footer: {
                    Text("Get smart suggestions for subtasks, labels, and estimated time")
                        .font(.caption)
                }

                if let suggestions = aiSuggestions {
                    Section("AI Suggestions") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Priority:")
                                    .fontWeight(.semibold)
                                Text(suggestions.priority)
                                    .foregroundColor(priorityColor(suggestions.priority))
                            }

                            Text(suggestions.priorityReasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Divider()

                            Text("Estimated: \(suggestions.estimatedHours, specifier: "%.1f") hours")
                                .font(.subheadline)

                            if !suggestions.subtasks.isEmpty {
                                Divider()
                                Text("Suggested Subtasks:")
                                    .fontWeight(.semibold)
                                ForEach(suggestions.subtasks, id: \.self) { subtask in
                                    Text("• \(subtask)")
                                        .font(.caption)
                                }
                            }

                            if !suggestions.labels.isEmpty {
                                Divider()
                                HStack {
                                    Text("Suggested Labels:")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Button(action: {
                                        for label in suggestions.labels {
                                            if !labels.contains(label) {
                                                labels.append(label)
                                            }
                                        }
                                    }) {
                                        Text("Add All")
                                    }
                                    .font(.caption)
                                }
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(suggestions.labels, id: \.self) { label in
                                            Text(label)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.blue.opacity(0.2))
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        createTask()
                    }) {
                        Text("Create")
                    }
                    .disabled(!isValid || isCreating)
                }
            }
        }
    }

    private func createTask() {
        isCreating = true

        let taskCreate = TaskCreate(
            title: title,
            description: description.isEmpty ? nil : description,
            dueDate: hasDueDate ? dueDate : nil,
            labels: labels
        )

        Task { @MainActor in
            await onCreate(taskCreate)
            isCreating = false
        }
    }

    private func loadAISuggestions() async {
        isLoadingSuggestions = true

        do {
            aiSuggestions = try await APIClient.shared.getTaskSuggestions(
                title: title,
                description: description.isEmpty ? nil : description
            )
            isLoadingSuggestions = false
        } catch {
            print("❌ Failed to load AI suggestions:", error)
            isLoadingSuggestions = false
        }
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .secondary
        }
    }
}

#Preview {
    NewTaskView { _ in }
}
