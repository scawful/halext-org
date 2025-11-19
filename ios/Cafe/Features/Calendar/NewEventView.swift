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
}

#Preview {
    NewEventView(viewModel: CalendarViewModel())
}
