//
//  DashboardLayoutManager.swift
//  Cafe
//
//  Manages dashboard layout persistence and syncing
//

import Foundation
import Combine
import SwiftUI

@Observable
class DashboardLayoutManager {
    static let shared = DashboardLayoutManager()

    var currentLayout: DashboardLayout
    var savedLayouts: [DashboardLayout] = []

    private let userDefaults = UserDefaults.standard
    private let currentLayoutKey = "dashboard.currentLayout"
    private let savedLayoutsKey = "dashboard.savedLayouts"

    init() {
        // Load current layout from UserDefaults
        if let data = userDefaults.data(forKey: currentLayoutKey),
           let layout = try? JSONDecoder().decode(DashboardLayout.self, from: data) {
            self.currentLayout = layout
        } else {
            // Use default layout if no saved layout exists
            self.currentLayout = DashboardLayout.defaultLayout
            saveCurrentLayout()
        }

        // Ensure we always start with cards to edit
        if currentLayout.cards.isEmpty {
            currentLayout = DashboardLayout.defaultLayout
            saveCurrentLayout()
        }

        // Load saved layouts
        loadSavedLayouts()
    }

    // MARK: - Current Layout Management

    func updateCurrentLayout(_ layout: DashboardLayout) {
        self.currentLayout = layout
        saveCurrentLayout()
    }

    func resetToDefaultLayout() {
        self.currentLayout = DashboardLayout.defaultLayout
        saveCurrentLayout()
    }

    func applyPreset(_ preset: DashboardLayout) {
        var newLayout = preset
        newLayout.id = UUID() // Create new instance
        newLayout.createdAt = Date()
        self.currentLayout = newLayout
        saveCurrentLayout()
    }

    // MARK: - Card Management

    func addCard(_ card: DashboardCard) {
        currentLayout.cards.append(card)
        saveCurrentLayout()
    }

    func removeCard(_ card: DashboardCard) {
        currentLayout.cards.removeAll { $0.id == card.id }
        reorderCards()
        saveCurrentLayout()
    }

    func updateCard(_ card: DashboardCard) {
        if let index = currentLayout.cards.firstIndex(where: { $0.id == card.id }) {
            currentLayout.cards[index] = card
            saveCurrentLayout()
        }
    }

    func moveCard(from source: Int, to destination: Int) {
        var sortedCards = currentLayout.cards.sorted(by: { $0.position < $1.position })
        let card = sortedCards.remove(at: source)
        sortedCards.insert(card, at: destination)

        for (index, card) in sortedCards.enumerated() {
            if let cardIndex = currentLayout.cards.firstIndex(where: { $0.id == card.id }) {
                currentLayout.cards[cardIndex].position = index
            }
        }
        saveCurrentLayout()
    }

    func reorderCards() {
        let sortedCards = currentLayout.cards.sorted(by: { $0.position < $1.position })
        for (index, card) in sortedCards.enumerated() {
            if let cardIndex = currentLayout.cards.firstIndex(where: { $0.id == card.id }) {
                currentLayout.cards[cardIndex].position = index
            }
        }
    }

    // MARK: - Saved Layouts

    func saveLayoutAs(name: String) {
        var layoutToSave = currentLayout
        layoutToSave.id = UUID()
        layoutToSave.name = name
        layoutToSave.createdAt = Date()
        layoutToSave.isDefault = false

        savedLayouts.append(layoutToSave)
        saveSavedLayouts()
    }

    func deleteLayout(_ layout: DashboardLayout) {
        savedLayouts.removeAll { $0.id == layout.id }
        saveSavedLayouts()
    }

    func loadLayout(_ layout: DashboardLayout) {
        currentLayout = layout
        saveCurrentLayout()
    }

    // MARK: - Visibility & Smart Hiding

    func visibleCards(at date: Date = Date()) -> [DashboardCard] {
        currentLayout.cards
            .filter { card in
                // Check if card is visible
                guard card.isVisible else { return false }

                // Check time-based visibility
                if let timeRange = card.configuration.showOnlyAtTime {
                    guard timeRange.isCurrentlyActive else { return false }
                }

                return true
            }
            .sorted { $0.position < $1.position }
    }

    func shouldShowCard(_ card: DashboardCard, isEmpty: Bool) -> Bool {
        guard card.isVisible else { return false }

        if card.configuration.autoHideWhenEmpty && isEmpty {
            return false
        }

        if let timeRange = card.configuration.showOnlyAtTime {
            return timeRange.isCurrentlyActive
        }

        return true
    }

    // MARK: - Persistence

    private func saveCurrentLayout() {
        if let encoded = try? JSONEncoder().encode(currentLayout) {
            userDefaults.set(encoded, forKey: currentLayoutKey)
        }
    }

    private func loadSavedLayouts() {
        if let data = userDefaults.data(forKey: savedLayoutsKey),
           let layouts = try? JSONDecoder().decode([DashboardLayout].self, from: data) {
            self.savedLayouts = layouts
        } else {
            self.savedLayouts = []
        }
    }

    private func saveSavedLayouts() {
        if let encoded = try? JSONEncoder().encode(savedLayouts) {
            userDefaults.set(encoded, forKey: savedLayoutsKey)
        }
    }

    // MARK: - Cloud Sync (Future Enhancement)

    // TODO: Add CloudKit sync
    func syncWithCloud() async {
        // Implementation for CloudKit sync
        // This would sync layouts across devices
    }
}
