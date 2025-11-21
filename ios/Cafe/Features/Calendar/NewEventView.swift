//
//  NewEventView.swift
//  Cafe
//
//  Create new calendar events
//

import SwiftUI

struct NewEventView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: CalendarViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600) // 1 hour later
    @State private var recurrenceType = "none"
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showingPrepTasks = false
    @State private var prepTasks: [String] = []
    @State private var isLoadingPrepTasks = false

    private let recurrenceOptions = [
        ("none", "None"),
        ("daily", "Daily"),
        ("weekly", "Weekly"),
        ("monthly", "Monthly")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...5)

                    TextField("Location (optional)", text: $location)
                }

                Section("Time") {
                    DatePicker("Starts", selection: $startTime)

                    DatePicker("Ends", selection: $endTime)

                    if startTime >= endTime {
                        Text("End time must be after start time")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section("Recurrence") {
                    Picker("Repeat", selection: $recurrenceType) {
                        ForEach(recurrenceOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }
                    .pickerStyle(.menu)

                    if recurrenceType != "none" {
                        Text("This event will repeat \(recurrenceType)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(
                    header: Text("AI Assistant"),
                    footer: Text("Generate preparation tasks for this event")
                ) {
                    Button(action: generatePrepTasks) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Preparation Tasks")
                            Spacer()
                            if isLoadingPrepTasks {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(title.isEmpty || isLoadingPrepTasks)
                    
                    if !prepTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested Tasks:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(prepTasks.enumerated()), id: \.offset) { index, task in
                                HStack {
                                    Image(systemName: "circle")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(task)
                                        .font(.caption)
                                }
                            }
                            
                            Button(action: createPrepTasks) {
                                Text("Create All Tasks")
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.top, 4)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Event")
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
                            await createEvent()
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
        !title.isEmpty && startTime < endTime
    }

    private func createEvent() async {
        isSubmitting = true
        errorMessage = nil

        let event = EventCreate(
            title: title,
            description: description.isEmpty ? nil : description,
            startTime: startTime,
            endTime: endTime,
            location: location.isEmpty ? nil : location
        )

        do {
            try await viewModel.createEvent(event)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
    
    private func generatePrepTasks() {
        guard !title.isEmpty else { return }
        
        isLoadingPrepTasks = true
        prepTasks = []
        
        _Concurrency.Task {
            do {
                let analysis = try await APIClient.shared.analyzeEvent(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    startTime: startTime,
                    endTime: endTime
                )
                
                // Extract preparation tasks from analysis recommendations
                await MainActor.run {
                    if !analysis.recommendations.isEmpty {
                        // Use AI recommendations as prep tasks
                        prepTasks = analysis.recommendations
                    } else {
                        // Fallback: generate tasks based on event type
                        prepTasks = generateDefaultPrepTasks()
                    }
                    isLoadingPrepTasks = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to default tasks
                    prepTasks = generateDefaultPrepTasks()
                    isLoadingPrepTasks = false
                }
            }
        }
    }
    
    private func generateDefaultPrepTasks() -> [String] {
        var tasks: [String] = []
        
        // Generate tasks based on event title and time
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: startTime).day ?? 0
        
        if daysUntil > 7 {
            tasks.append("Confirm attendance/RSVP")
        }
        
        if daysUntil > 3 {
            tasks.append("Prepare materials or agenda")
        }
        
        if daysUntil > 1 {
            tasks.append("Review event details")
        }
        
        if !location.isEmpty {
            tasks.append("Plan route to \(location)")
        }
        
        if daysUntil == 0 {
            tasks.append("Final check before event")
        }
        
        return tasks.isEmpty ? ["Prepare for \(title)"] : tasks
    }
    
    private func createPrepTasks() {
        guard !prepTasks.isEmpty else { return }
        
        _Concurrency.Task {
            // Calculate due dates for prep tasks (before event)
            let prepDate = startTime.addingTimeInterval(-86400) // 1 day before
            
            for taskTitle in prepTasks {
                let task = TaskCreate(
                    title: taskTitle,
                    description: "Preparation for: \(title)",
                    dueDate: prepDate,
                    labels: ["Event Prep", title]
                )
                
                do {
                    _ = try await APIClient.shared.createTask(task)
                } catch {
                    print("Failed to create prep task: \(error)")
                }
            }
            
            await MainActor.run {
                prepTasks = []
            }
        }
    }
}

#Preview {
    NewEventView(viewModel: CalendarViewModel())
}
