//
//  CalendarViewModel.swift
//  Cafe
//
//  Calendar and events management
//

import Foundation
import SwiftUI

@Observable
class CalendarViewModel {
    var events: [Event] = []
    var selectedDate: Date = Date()
    var isLoading = false
    var errorMessage: String?
    var showingNewEvent = false

    private let api = APIClient.shared
    private let syncManager = SyncManager.shared
    private let networkMonitor = NetworkMonitor.shared
    private let storage = StorageManager.shared

    @MainActor
    func loadEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load from cache first (offline-first)
            events = try syncManager.loadEventsFromCache()
            isLoading = false

            // Sync with server if online
            if networkMonitor.isConnected {
                await syncManager.syncAll()
                events = try syncManager.loadEventsFromCache()
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    func createEvent(_ eventCreate: EventCreate) async throws {
        let newEvent: Event

        if networkMonitor.isConnected {
            // Online: create via API
            newEvent = try await api.createEvent(eventCreate)
            try? storage.saveEvent(newEvent)
        } else {
            // Offline: create locally and queue for sync
            newEvent = try await syncManager.createEventOffline(eventCreate)
        }

        events.append(newEvent)
        showingNewEvent = false
    }

    // Get events for a specific date
    func events(for date: Date) -> [Event] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return events.filter { event in
            event.startTime >= startOfDay && event.startTime < endOfDay
        }.sorted { $0.startTime < $1.startTime }
    }

    // Get dates that have events
    func datesWithEvents(in month: Date) -> Set<DateComponents> {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!

        var eventDates: Set<DateComponents> = []

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                if !events(for: date).isEmpty {
                    eventDates.insert(calendar.dateComponents([.year, .month, .day], from: date))
                }
            }
        }

        return eventDates
    }

    var selectedDateEvents: [Event] {
        events(for: selectedDate)
    }

    var upcomingEvents: [Event] {
        let now = Date()
        return events
            .filter { $0.startTime >= now }
            .sorted { $0.startTime < $1.startTime }
    }
}
