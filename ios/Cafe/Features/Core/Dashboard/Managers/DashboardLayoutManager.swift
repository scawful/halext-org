//
//  DashboardLayoutManager.swift
//  Cafe
//
//  Manages dashboard layout persistence and syncing
//

import Foundation
import Combine
import SwiftUI
import CloudKit

// Typealias to avoid conflict with Task model from Models.swift
private typealias AsyncTask = _Concurrency.Task

@Observable
class DashboardLayoutManager {
    static let shared = DashboardLayoutManager()

    var currentLayout: DashboardLayout
    var savedLayouts: [DashboardLayout] = []

    // CloudKit sync state
    var isSyncing: Bool = false
    var lastSyncDate: Date?
    var syncError: String?
    var isCloudKitAvailable: Bool = false

    private let userDefaults = UserDefaults.standard
    private let currentLayoutKey = "dashboard.currentLayout"
    private let savedLayoutsKey = "dashboard.savedLayouts"
    private let lastSyncKey = "dashboard.lastSyncDate"

    // CloudKit configuration
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let layoutRecordType = "DashboardLayout"

    init() {
        // Initialize CloudKit container
        self.container = CKContainer.default()
        self.privateDatabase = container.privateCloudDatabase

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

        // Load last sync date
        if let syncDate = userDefaults.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = syncDate
        }

        // Check CloudKit availability
        AsyncTask { @MainActor in
            await checkCloudKitAvailability()
        }
    }

    // MARK: - Current Layout Management

    func updateCurrentLayout(_ layout: DashboardLayout) {
        self.currentLayout = layout
        saveCurrentLayout()

        // Queue for CloudKit sync
        queueForSync()
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

        // Sync to CloudKit if available
        AsyncTask { @MainActor in
            try? await saveLayoutToCloud(layoutToSave, isCurrentLayout: false)
        }
    }

    func deleteLayout(_ layout: DashboardLayout) {
        savedLayouts.removeAll { $0.id == layout.id }
        saveSavedLayouts()

        // Also delete from CloudKit if available
        AsyncTask { @MainActor in
            try? await deleteLayoutFromCloud(layout)
        }
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

    // MARK: - CloudKit Availability

    @MainActor
    func checkCloudKitAvailability() async {
        do {
            let status = try await container.accountStatus()
            isCloudKitAvailable = status == .available

            if !isCloudKitAvailable {
                syncError = "iCloud account not available"
                print("CloudKit not available: \(status)")
            } else {
                syncError = nil
                print("CloudKit is available for dashboard sync")
            }
        } catch {
            isCloudKitAvailable = false
            syncError = "Failed to check iCloud status: \(error.localizedDescription)"
            print("CloudKit error: \(error)")
        }
    }

    // MARK: - CloudKit Sync

    @MainActor
    func syncWithCloud() async {
        guard isCloudKitAvailable else {
            syncError = "iCloud is not available"
            return
        }

        isSyncing = true
        syncError = nil

        do {
            // Fetch remote layout
            let remoteLayout = try await fetchLayoutFromCloud()

            if let remote = remoteLayout {
                // Resolve conflicts - use most recently modified
                let localDate = currentLayout.createdAt
                let remoteDate = remote.createdAt

                if remoteDate > localDate {
                    // Remote is newer, update local
                    currentLayout = remote
                    saveCurrentLayout()
                    print("Updated local layout from CloudKit")
                } else if localDate > remoteDate {
                    // Local is newer, push to cloud
                    try await saveLayoutToCloud(currentLayout)
                    print("Updated CloudKit with local layout")
                }
                // If dates are equal, no action needed
            } else {
                // No remote layout exists, push local to cloud
                try await saveLayoutToCloud(currentLayout)
                print("Saved initial layout to CloudKit")
            }

            // Sync saved layouts
            try await syncSavedLayoutsWithCloud()

            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: lastSyncKey)
            print("CloudKit sync completed successfully")

        } catch {
            syncError = "Sync failed: \(error.localizedDescription)"
            print("CloudKit sync error: \(error)")
        }

        isSyncing = false
    }

    @MainActor
    private func fetchLayoutFromCloud() async throws -> DashboardLayout? {
        let predicate = NSPredicate(format: "isCurrentLayout == %@", NSNumber(value: true))
        let query = CKQuery(recordType: layoutRecordType, predicate: predicate)

        let results = try await privateDatabase.records(matching: query)

        guard let (_, result) = results.matchResults.first,
              let record = try? result.get() else {
            return nil
        }

        return layoutFromRecord(record)
    }

    @MainActor
    private func saveLayoutToCloud(_ layout: DashboardLayout, isCurrentLayout: Bool = true) async throws {
        let record = recordFromLayout(layout, isCurrentLayout: isCurrentLayout)

        // Check if record already exists
        let predicate = NSPredicate(format: "layoutId == %@", layout.id.uuidString)
        let query = CKQuery(recordType: layoutRecordType, predicate: predicate)

        let results = try await privateDatabase.records(matching: query)

        if let (existingRecordID, existingResult) = results.matchResults.first,
           var existingRecord = try? existingResult.get() {
            // Update existing record
            existingRecord["name"] = layout.name as CKRecordValue
            existingRecord["cardsData"] = try JSONEncoder().encode(layout.cards) as CKRecordValue
            existingRecord["isDefault"] = (layout.isDefault ? 1 : 0) as CKRecordValue
            existingRecord["isCurrentLayout"] = (isCurrentLayout ? 1 : 0) as CKRecordValue
            existingRecord["modifiedAt"] = Date() as CKRecordValue

            _ = try await privateDatabase.save(existingRecord)
        } else {
            // Save new record
            _ = try await privateDatabase.save(record)
        }
    }

    @MainActor
    private func syncSavedLayoutsWithCloud() async throws {
        // Fetch all saved layouts from cloud
        let predicate = NSPredicate(format: "isCurrentLayout == %@", NSNumber(value: false))
        let query = CKQuery(recordType: layoutRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let results = try await privateDatabase.records(matching: query)

        var remoteLayouts: [DashboardLayout] = []
        for (_, result) in results.matchResults {
            if let record = try? result.get(),
               let layout = layoutFromRecord(record) {
                remoteLayouts.append(layout)
            }
        }

        // Merge local and remote saved layouts
        var mergedLayouts = savedLayouts

        for remoteLayout in remoteLayouts {
            if !mergedLayouts.contains(where: { $0.id == remoteLayout.id }) {
                mergedLayouts.append(remoteLayout)
            }
        }

        // Push any local-only layouts to cloud
        for localLayout in savedLayouts {
            if !remoteLayouts.contains(where: { $0.id == localLayout.id }) {
                try await saveLayoutToCloud(localLayout, isCurrentLayout: false)
            }
        }

        savedLayouts = mergedLayouts
        saveSavedLayouts()
    }

    @MainActor
    func deleteLayoutFromCloud(_ layout: DashboardLayout) async throws {
        guard isCloudKitAvailable else {
            throw DashboardSyncError.cloudKitUnavailable
        }

        let predicate = NSPredicate(format: "layoutId == %@", layout.id.uuidString)
        let query = CKQuery(recordType: layoutRecordType, predicate: predicate)

        let results = try await privateDatabase.records(matching: query)

        if let (recordID, _) = results.matchResults.first {
            _ = try await privateDatabase.deleteRecord(withID: recordID)
            print("Deleted layout from CloudKit: \(layout.name)")
        }
    }

    // MARK: - CloudKit Record Conversion

    private func recordFromLayout(_ layout: DashboardLayout, isCurrentLayout: Bool = false) -> CKRecord {
        let record = CKRecord(recordType: layoutRecordType)

        record["layoutId"] = layout.id.uuidString as CKRecordValue
        record["name"] = layout.name as CKRecordValue
        record["isDefault"] = (layout.isDefault ? 1 : 0) as CKRecordValue
        record["isCurrentLayout"] = (isCurrentLayout ? 1 : 0) as CKRecordValue
        record["createdAt"] = layout.createdAt as CKRecordValue
        record["modifiedAt"] = Date() as CKRecordValue

        // Encode cards as JSON data
        if let cardsData = try? JSONEncoder().encode(layout.cards) {
            record["cardsData"] = cardsData as CKRecordValue
        }

        return record
    }

    private func layoutFromRecord(_ record: CKRecord) -> DashboardLayout? {
        guard let layoutIdString = record["layoutId"] as? String,
              let layoutId = UUID(uuidString: layoutIdString),
              let name = record["name"] as? String,
              let cardsData = record["cardsData"] as? Data,
              let cards = try? JSONDecoder().decode([DashboardCard].self, from: cardsData),
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        let isDefault = (record["isDefault"] as? Int) == 1

        return DashboardLayout(
            id: layoutId,
            name: name,
            cards: cards,
            isDefault: isDefault,
            createdAt: createdAt
        )
    }

    // MARK: - Conflict Resolution

    @MainActor
    func resolveConflict(useLocal: Bool) async {
        guard isCloudKitAvailable else { return }

        isSyncing = true
        do {
            if useLocal {
                // Push local layout to cloud, overwriting remote
                try await saveLayoutToCloud(currentLayout)
                print("Conflict resolved: Local layout pushed to cloud")
            } else {
                // Fetch and use remote layout
                if let remoteLayout = try await fetchLayoutFromCloud() {
                    currentLayout = remoteLayout
                    saveCurrentLayout()
                    print("Conflict resolved: Remote layout applied locally")
                }
            }
            syncError = nil
        } catch {
            syncError = "Conflict resolution failed: \(error.localizedDescription)"
        }
        isSyncing = false
    }

    // MARK: - Offline Support

    func queueForSync() {
        // Mark that sync is needed when connection is restored
        userDefaults.set(true, forKey: "dashboard.pendingSync")
    }

    func hasPendingSync() -> Bool {
        return userDefaults.bool(forKey: "dashboard.pendingSync")
    }

    @MainActor
    func processPendingSync() async {
        guard hasPendingSync(), isCloudKitAvailable else { return }

        await syncWithCloud()

        if syncError == nil {
            userDefaults.set(false, forKey: "dashboard.pendingSync")
        }
    }
}

// MARK: - Dashboard Sync Errors

enum DashboardSyncError: LocalizedError {
    case cloudKitUnavailable
    case encodingFailed
    case decodingFailed
    case recordNotFound
    case conflictDetected

    var errorDescription: String? {
        switch self {
        case .cloudKitUnavailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .encodingFailed:
            return "Failed to encode layout data."
        case .decodingFailed:
            return "Failed to decode layout from iCloud."
        case .recordNotFound:
            return "Layout not found in iCloud."
        case .conflictDetected:
            return "A conflict was detected between local and cloud layouts."
        }
    }
}
