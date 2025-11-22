//
//  CardConfigurationView.swift
//  Cafe
//
//  Individual card settings and configuration
//

import SwiftUI

struct CardConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var card: DashboardCard

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Settings") {
                    Toggle("Show Card", isOn: $card.isVisible)

                    Picker("Size", selection: $card.size) {
                        ForEach([CardSize.small, .medium, .large], id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }

                    Toggle("Show Header", isOn: $card.configuration.showHeader)

                    Toggle("Auto-hide When Empty", isOn: $card.configuration.autoHideWhenEmpty)
                }

                // Card-specific configuration
                cardSpecificConfiguration

                Section("Time-based Display") {
                    Toggle("Show Only at Specific Times", isOn: Binding(
                        get: { card.configuration.showOnlyAtTime != nil },
                        set: { enabled in
                            if enabled {
                                card.configuration.showOnlyAtTime = TimeRange(startHour: 9, endHour: 17)
                            } else {
                                card.configuration.showOnlyAtTime = nil
                            }
                        }
                    ))

                    if let timeRange = card.configuration.showOnlyAtTime {
                        Picker("Start Hour", selection: Binding(
                            get: { timeRange.startHour },
                            set: { card.configuration.showOnlyAtTime?.startHour = $0 }
                        )) {
                            ForEach(0..<24) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }

                        Picker("End Hour", selection: Binding(
                            get: { timeRange.endHour },
                            set: { card.configuration.showOnlyAtTime?.endHour = $0 }
                        )) {
                            ForEach(0..<24) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }
                    }
                }
            }
            .navigationTitle(card.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private var cardSpecificConfiguration: some View {
        switch card.type {
        case .todayTasks, .upcomingTasks, .overdueTasks:
            taskConfiguration

        case .upcomingEvents, .calendar:
            eventConfiguration

        case .customList:
            customListConfiguration

        default:
            EmptyView()
        }
    }

    private var taskConfiguration: some View {
        Section("Task Settings") {
            Stepper("Max Tasks: \(card.configuration.maxTasksToShow)",
                    value: $card.configuration.maxTasksToShow,
                    in: 1...20)

            Toggle("Show Completed Tasks", isOn: $card.configuration.showCompletedTasks)
        }
    }

    private var eventConfiguration: some View {
        Section("Event Settings") {
            Stepper("Max Events: \(card.configuration.maxEventsToShow)",
                    value: $card.configuration.maxEventsToShow,
                    in: 1...10)

            Stepper("Days Ahead: \(card.configuration.calendarDaysAhead)",
                    value: $card.configuration.calendarDaysAhead,
                    in: 1...30)
        }
    }

    private var customListConfiguration: some View {
        Section("Custom List Settings") {
            TextField("List Title", text: Binding(
                get: { card.configuration.customListTitle ?? "" },
                set: { card.configuration.customListTitle = $0.isEmpty ? nil : $0 }
            ))

            Text("Configure list items in the main app")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    CardConfigurationView(card: .constant(
        DashboardCard(type: .todayTasks, position: 0)
    ))
}
