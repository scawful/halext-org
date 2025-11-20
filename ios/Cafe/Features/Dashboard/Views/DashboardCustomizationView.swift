//
//  DashboardCustomizationView.swift
//  Cafe
//
//  Dashboard customization and card picker
//

import SwiftUI

struct DashboardCustomizationView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var layout: DashboardLayout
    @State private var showingCardPicker = false
    @State private var editingCard: DashboardCard?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(layout.cards.sorted(by: { $0.position < $1.position })) { card in
                        CardListRow(card: card)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    removeCard(card)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    editingCard = card
                                } label: {
                                    Label("Configure", systemImage: "gearshape")
                                }

                                Button {
                                    duplicateCard(card)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }

                                Button(role: .destructive) {
                                    removeCard(card)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                    }
                    .onMove { from, to in
                        moveCard(from: from, to: to)
                    }
                } header: {
                    Text("Dashboard Cards")
                } footer: {
                    Text("Drag to reorder, swipe to delete")
                }

                Section("Card Management") {
                    Button {
                        showingCardPicker = true
                    } label: {
                        Label("Add Card", systemImage: "plus.circle.fill")
                    }
                }

                Section("Layout Presets") {
                    ForEach(DashboardLayout.allPresets) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.name)
                                        .font(.headline)
                                    Text("\(preset.cards.count) cards")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if layout.name == preset.name {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Customize Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingCardPicker) {
                CardPickerView { cardType in
                    addCard(type: cardType)
                }
            }
            .sheet(item: $editingCard) { card in
                CardConfigurationView(card: binding(for: card))
            }
        }
    }

    private func binding(for card: DashboardCard) -> Binding<DashboardCard> {
        guard let index = layout.cards.firstIndex(where: { $0.id == card.id }) else {
            return .constant(card)
        }
        return $layout.cards[index]
    }

    private func addCard(type: DashboardCardType) {
        let newPosition = layout.cards.map(\.position).max() ?? -1
        let newCard = DashboardCard(
            type: type,
            position: newPosition + 1
        )
        layout.cards.append(newCard)
    }

    private func removeCard(_ card: DashboardCard) {
        layout.cards.removeAll { $0.id == card.id }
        reorderPositions()
    }

    private func duplicateCard(_ card: DashboardCard) {
        let newPosition = layout.cards.map(\.position).max() ?? -1
        let newCard = DashboardCard(
            type: card.type,
            size: card.size,
            position: newPosition + 1,
            isVisible: card.isVisible,
            configuration: card.configuration
        )
        layout.cards.append(newCard)
    }

    private func moveCard(from source: IndexSet, to destination: Int) {
        var sortedCards = layout.cards.sorted(by: { $0.position < $1.position })
        sortedCards.move(fromOffsets: source, toOffset: destination)
        for (index, card) in sortedCards.enumerated() {
            if let cardIndex = layout.cards.firstIndex(where: { $0.id == card.id }) {
                layout.cards[cardIndex].position = index
            }
        }
    }

    private func reorderPositions() {
        let sortedCards = layout.cards.sorted(by: { $0.position < $1.position })
        for (index, card) in sortedCards.enumerated() {
            if let cardIndex = layout.cards.firstIndex(where: { $0.id == card.id }) {
                layout.cards[cardIndex].position = index
            }
        }
    }

    private func applyPreset(_ preset: DashboardLayout) {
        layout.name = preset.name
        layout.cards = preset.cards
    }
}

// MARK: - Card List Row

struct CardListRow: View {
    let card: DashboardCard

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: card.type.icon)
                .font(.title3)
                .foregroundColor(card.type.color)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(card.type.color.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(card.type.displayName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(card.size.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )

                    if !card.isVisible {
                        Text("Hidden")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if card.configuration.autoHideWhenEmpty {
                        Text("Auto-hide")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .opacity(card.isVisible ? 1.0 : 0.5)
    }
}

// MARK: - Card Picker

struct CardPickerView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (DashboardCardType) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Tasks & Productivity") {
                    ForEach(productivityCards) { cardType in
                        CardTypeRow(cardType: cardType) {
                            onSelect(cardType)
                            dismiss()
                        }
                    }
                }

                Section("Calendar & Events") {
                    ForEach(calendarCards) { cardType in
                        CardTypeRow(cardType: cardType) {
                            onSelect(cardType)
                            dismiss()
                        }
                    }
                }

                Section("Information & Utilities") {
                    ForEach(utilityCards) { cardType in
                        CardTypeRow(cardType: cardType) {
                            onSelect(cardType)
                            dismiss()
                        }
                    }
                }

                Section("Social & Collaboration") {
                    ForEach(socialCards) { cardType in
                        CardTypeRow(cardType: cardType) {
                            onSelect(cardType)
                            dismiss()
                        }
                    }
                }

                Section("Other") {
                    ForEach(otherCards) { cardType in
                        CardTypeRow(cardType: cardType) {
                            onSelect(cardType)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var productivityCards: [DashboardCardType] {
        [.todayTasks, .upcomingTasks, .overdueTasks, .tasksStats, .aiGenerator, .quickActions]
    }

    private var calendarCards: [DashboardCardType] {
        [.calendar, .upcomingEvents]
    }

    private var utilityCards: [DashboardCardType] {
        [.weather, .notes, .aiSuggestions, .recentActivity, .mealPlanning, .iosFeatures]
    }

    private var socialCards: [DashboardCardType] {
        [.socialActivity]
    }

    private var otherCards: [DashboardCardType] {
        [.welcome, .allApps, .customList]
    }
}

struct CardTypeRow: View {
    let cardType: DashboardCardType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: cardType.icon)
                    .font(.title3)
                    .foregroundColor(cardType.color)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cardType.color.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(cardType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(cardType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardCustomizationView(layout: .constant(DashboardLayout.defaultLayout))
}
