//
//  DashboardViewModel.swift
//  Cafe
//
//  Dashboard data management
//

import Foundation
import SwiftUI

@Observable
class DashboardViewModel {
    var tasks: [Task] = []
    var events: [Event] = []
    var isLoading = false
    var errorMessage: String?

    // Stats
    var completedToday: Int = 0
    var upcomingEventsCount: Int = 0
    var tasksThisWeek: Int = 0

    private let api = APIClient.shared
    private let syncManager = SyncManager.shared
    private let networkMonitor = NetworkMonitor.shared

    @MainActor
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load from cache first (offline-first)
            tasks = try syncManager.loadTasksFromCache()
            events = try syncManager.loadEventsFromCache()
            calculateStats()
            isLoading = false

            // Sync with server if online
            if networkMonitor.isConnected {
                await syncManager.syncAll()
                tasks = try syncManager.loadTasksFromCache()
                events = try syncManager.loadEventsFromCache()
                calculateStats()
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func fetchTasks() async throws -> [Task] {
        try syncManager.loadTasksFromCache()
    }

    private func fetchEvents() async throws -> [Event] {
        try syncManager.loadEventsFromCache()
    }

    private func calculateStats() {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        // Tasks completed today
        completedToday = tasks.filter { task in
            task.completed && task.createdAt >= startOfToday && task.createdAt < endOfToday
        }.count

        // Upcoming events (next 7 days)
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
        upcomingEventsCount = events.filter { event in
            event.startTime >= now && event.startTime <= weekFromNow
        }.count

        // Tasks this week (incomplete)
        tasksThisWeek = tasks.filter { task in
            !task.completed &&
            (task.dueDate == nil || (task.dueDate! >= now && task.dueDate! <= weekFromNow))
        }.count
    }

    var todaysTasks: [Task] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        return tasks.filter { task in
            !task.completed &&
            (task.dueDate ?? now) >= startOfToday &&
            (task.dueDate ?? now) < endOfToday
        }
    }

    var upcomingEvents: [Event] {
        let now = Date()
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        return events
            .filter { $0.startTime >= now && $0.startTime <= weekFromNow }
            .sorted { $0.startTime < $1.startTime }
            .prefix(3)
            .map { $0 }
    }

    var overdueTasks: [Task] {
        let now = Date()
        return tasks.filter { task in
            !task.completed &&
            task.dueDate != nil &&
            task.dueDate! < now
        }
    }
}
