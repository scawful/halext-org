//
//  GeneratedTaskPreviewView.swift
//  Cafe
//
//  Preview and edit cards for AI-generated tasks and events
//

import SwiftUI

// MARK: - Generated Task Preview

struct GeneratedTaskPreviewView: View {
    let task: GeneratedTask
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            HStack(alignment: .top, spacing: 12) {
                // Selection checkbox
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    // Metadata row
                    HStack(spacing: 12) {
                        // Priority
                        HStack(spacing: 4) {
                            Image(systemName: priorityIcon(task.priority))
                                .font(.caption2)
                            Text(task.priority.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(Color(task.priority.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: task.priority.color).opacity(0.15))
                        )

                        // Due date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(dueDate, style: .date)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }

                        // Estimated time
                        if let minutes = task.estimatedMinutes {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text("\(minutes)m")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    // Labels
                    if !task.labels.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(task.labels, id: \.self) { label in
                                    Text(label)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    // Subtasks indicator
                    if let subtasks = task.subtasks, !subtasks.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.indent")
                                .font(.caption2)
                            Text("\(subtasks.count) subtasks")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Show details button
                    Button {
                        withAnimation {
                            showDetails.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showDetails ? "Hide Details" : "Show Details")
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                Spacer()
            }
            .padding()

            // Expandable details
            if showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // Description
                    if let description = task.description {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }

                    // Subtasks list
                    if let subtasks = task.subtasks, !subtasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subtasks")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            ForEach(Array(subtasks.enumerated()), id: \.offset) { index, subtask in
                                HStack(spacing: 8) {
                                    Image(systemName: "circle")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(subtask)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }

                    // AI reasoning
                    if let reasoning = task.aiReasoning {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text("AI Insight")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.purple)

                            Text(reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple.opacity(0.05))
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private func priorityIcon(_ priority: TaskPriority) -> String {
        switch priority {
        case .low:
            return "arrow.down"
        case .medium:
            return "minus"
        case .high:
            return "arrow.up"
        case .urgent:
            return "exclamationmark.2"
        }
    }
}

// MARK: - Generated Event Preview

struct GeneratedEventPreviewView: View {
    let event: GeneratedEvent
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            HStack(alignment: .top, spacing: 12) {
                // Selection checkbox
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .purple : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    // Time and duration
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(event.startTime, style: .date)
                                .font(.caption)
                        }
                        .foregroundColor(.purple)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(event.startTime, style: .time)
                                .font(.caption)
                            Text("-")
                                .font(.caption)
                            Text(event.endTime, style: .time)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Location
                    if let location = event.location {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(location)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(.secondary)
                    }

                    // Recurrence
                    if event.recurrenceType != "none" {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption2)
                            Text(event.recurrenceType.capitalized)
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                    }

                    // Show details button
                    Button {
                        withAnimation {
                            showDetails.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showDetails ? "Hide Details" : "Show Details")
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }

                Spacer()
            }
            .padding()

            // Expandable details
            if showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // Description
                    if let description = event.description {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }

                    // Duration calculation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(formatDuration(from: event.startTime, to: event.endTime))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }

                    // AI reasoning
                    if let reasoning = event.aiReasoning {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text("AI Insight")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.purple)

                            Text(reasoning)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple.opacity(0.05))
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
        )
    }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Color Extension
// Note: Color hex initializer is defined in ColorExtensions.swift

// MARK: - Preview

#Preview("Task Preview") {
    VStack(spacing: 16) {
        GeneratedTaskPreviewView(
            task: GeneratedTask(
                id: UUID(),
                title: "Book flights to Tokyo",
                description: "Compare prices on different airlines and book round-trip tickets",
                dueDate: Date().addingTimeInterval(86400 * 7),
                priority: .high,
                labels: ["Travel", "Important"],
                estimatedMinutes: 45,
                subtasks: ["Research flight options", "Compare prices", "Book tickets"],
                parentTaskId: nil,
                aiReasoning: "High priority because flights should be booked early for better prices"
            ),
            isSelected: true,
            onToggle: {}
        )

        GeneratedTaskPreviewView(
            task: GeneratedTask(
                id: UUID(),
                title: "Pack suitcase",
                description: nil,
                dueDate: Date().addingTimeInterval(86400 * 30),
                priority: .medium,
                labels: ["Travel"],
                estimatedMinutes: 60,
                subtasks: nil,
                parentTaskId: nil,
                aiReasoning: nil
            ),
            isSelected: false,
            onToggle: {}
        )
    }
    .padding()
}

#Preview("Event Preview") {
    VStack(spacing: 16) {
        GeneratedEventPreviewView(
            event: GeneratedEvent(
                id: UUID(),
                title: "Flight to Tokyo",
                description: "Depart from SFO to NRT",
                startTime: Date().addingTimeInterval(86400 * 30),
                endTime: Date().addingTimeInterval(86400 * 30 + 3600 * 12),
                location: "San Francisco Airport",
                recurrenceType: "none",
                aiReasoning: "Scheduled based on your trip timeline"
            ),
            isSelected: true,
            onToggle: {}
        )

        GeneratedEventPreviewView(
            event: GeneratedEvent(
                id: UUID(),
                title: "Morning workout",
                description: "Cardio and strength training",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(3600 * 2),
                location: "Local Gym",
                recurrenceType: "daily",
                aiReasoning: "Recurring event to maintain consistency"
            ),
            isSelected: false,
            onToggle: {}
        )
    }
    .padding()
}
