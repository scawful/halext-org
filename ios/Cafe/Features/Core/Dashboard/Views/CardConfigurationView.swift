//
//  CardConfigurationView.swift
//  Cafe
//
//  Individual card settings and configuration
//

import SwiftUI

struct CardConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ThemeManager.self) var themeManager
    @Binding var card: DashboardCard

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Settings") {
                    Toggle("Show Card", isOn: $card.isVisible)

                    // Enhanced size picker with visual previews
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Size")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach([CardSize.small, .medium, .large], id: \.self) { size in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        card.size = size
                                    }
                                    HapticManager.selection()
                                }) {
                                    VStack(spacing: 8) {
                                        // Visual preview
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                card.size == size
                                                    ? themeManager.accentColor.opacity(0.2)
                                                    : themeManager.cardBackgroundColor
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(
                                                        card.size == size
                                                            ? themeManager.accentColor
                                                            : themeManager.secondaryTextColor.opacity(0.3),
                                                        lineWidth: card.size == size ? 2 : 1
                                                    )
                                            )
                                            .frame(
                                                width: size == .small ? 60 : (size == .medium ? 80 : 100),
                                                height: size == .small ? 40 : (size == .medium ? 60 : 80)
                                            )
                                        
                                        Text(size.displayName)
                                            .font(.caption)
                                            .fontWeight(card.size == size ? .semibold : .regular)
                                            .foregroundColor(
                                                card.size == size
                                                    ? themeManager.accentColor
                                                    : themeManager.textColor
                                            )
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                card.size == size
                                                    ? themeManager.accentColor.opacity(0.1)
                                                    : Color.clear
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)

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
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
}

// MARK: - Preview

#Preview {
    CardConfigurationView(card: .constant(
        DashboardCard(type: .todayTasks, position: 0)
    ))
}
