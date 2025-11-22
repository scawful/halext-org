//
//  NewGoalView.swift
//  Cafe
//
//  Create a new shared goal
//

import SwiftUI

struct NewGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ThemeManager.self) var themeManager
    let viewModel: GoalsViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var preferredContactUsername: String = "magicalgirl"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Sharing") {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(themeManager.accentColor)
                        Text("Will be shared with \(preferredContactUsername.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(themeManager.errorColor)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        _Concurrency.Task {
                            await createGoal()
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    ProgressView()
                }
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty
    }
    
    private func createGoal() async {
        isSubmitting = true
        errorMessage = nil
        
        let goal = GoalCreate(
            title: title,
            description: description.isEmpty ? nil : description,
            sharedWith: [preferredContactUsername]
        )
        
        do {
            _ = try await viewModel.createGoal(goal)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
}

#Preview {
    NewGoalView(viewModel: GoalsViewModel())
}

