//
//  TaskLiveActivityManager.swift
//  Cafe
//
//  Manager for Task Live Activities
//

import Foundation
import ActivityKit

@MainActor
class TaskLiveActivityManager {
    static let shared = TaskLiveActivityManager()

    private var activeActivities: [Int: Activity<TaskActivityAttributes>] = [:]
    private var timers: [Int: Timer] = [:]
    private var startTimes: [Int: Date] = [:]
    private var elapsedTimes: [Int: TimeInterval] = [:]

    private init() {}

    // MARK: - Start Live Activity

    @available(iOS 16.1, *)
    func startTaskTimer(taskId: Int, taskTitle: String) async {
        // Check if already running
        if activeActivities[taskId] != nil {
            print("⚠️ Live Activity already running for task \(taskId)")
            return
        }

        let attributes = TaskActivityAttributes(
            taskId: taskId,
            taskTitle: taskTitle
        )

        let initialState = TaskActivityAttributes.ContentState(
            taskTitle: taskTitle,
            isRunning: true,
            elapsedTime: 0,
            startTime: Date()
        )

        do {
            let activity = try Activity<TaskActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            activeActivities[taskId] = activity
            startTimes[taskId] = Date()
            elapsedTimes[taskId] = 0

            // Start timer to update every second
            startUpdateTimer(taskId: taskId)

            print("✅ Started Live Activity for task: \(taskTitle)")
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    // MARK: - Toggle Timer

    @available(iOS 16.1, *)
    func toggleTimer(taskId: Int) async {
        guard let activity = activeActivities[taskId] else { return }

        let currentState = activity.content.state
        let isRunning = !currentState.isRunning

        if isRunning {
            // Resume timer
            startTimes[taskId] = Date()
            startUpdateTimer(taskId: taskId)
        } else {
            // Pause timer
            stopUpdateTimer(taskId: taskId)
            if let startTime = startTimes[taskId] {
                let additionalTime = Date().timeIntervalSince(startTime)
                elapsedTimes[taskId, default: 0] += additionalTime
            }
        }

        let newState = TaskActivityAttributes.ContentState(
            taskTitle: currentState.taskTitle,
            isRunning: isRunning,
            elapsedTime: elapsedTimes[taskId] ?? 0,
            startTime: currentState.startTime
        )

        await updateActivity(taskId: taskId, state: newState)
    }

    // MARK: - Stop Timer

    @available(iOS 16.1, *)
    func stopTimer(taskId: Int) async {
        guard let activity = activeActivities[taskId] else { return }

        // Stop the update timer
        stopUpdateTimer(taskId: taskId)

        // End the activity
        let finalState = activity.content.state
        await activity.end(
            .init(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )

        // Cleanup
        activeActivities.removeValue(forKey: taskId)
        startTimes.removeValue(forKey: taskId)
        elapsedTimes.removeValue(forKey: taskId)

        print("🛑 Stopped Live Activity for task \(taskId)")
    }

    // MARK: - Update Activity

    @available(iOS 16.1, *)
    private func updateActivity(taskId: Int, state: TaskActivityAttributes.ContentState) async {
        guard let activity = activeActivities[taskId] else { return }

        await activity.update(.init(state: state, staleDate: nil))
    }

    // MARK: - Timer Management

    private func startUpdateTimer(taskId: Int) {
        stopUpdateTimer(taskId: taskId) // Stop existing timer if any

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                await self?.updateElapsedTime(taskId: taskId)
            }
        }

        timers[taskId] = timer
    }

    private func stopUpdateTimer(taskId: Int) {
        timers[taskId]?.invalidate()
        timers.removeValue(forKey: taskId)
    }

    @available(iOS 16.1, *)
    private func updateElapsedTime(taskId: Int) async {
        guard let activity = activeActivities[taskId],
              let startTime = startTimes[taskId] else { return }

        let baseElapsed = elapsedTimes[taskId] ?? 0
        let currentElapsed = baseElapsed + Date().timeIntervalSince(startTime)

        let currentState = activity.content.state

        let newState = TaskActivityAttributes.ContentState(
            taskTitle: currentState.taskTitle,
            isRunning: currentState.isRunning,
            elapsedTime: currentElapsed,
            startTime: currentState.startTime
        )

        await updateActivity(taskId: taskId, state: newState)
    }

    // MARK: - Cleanup

    @available(iOS 16.1, *)
    func endAllActivities() async {
        for (taskId, _) in activeActivities {
            await stopTimer(taskId: taskId)
        }
    }

    // MARK: - Check Availability

    var isLiveActivitySupported: Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }
}
