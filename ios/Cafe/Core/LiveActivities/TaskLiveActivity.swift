//
//  TaskLiveActivity.swift
//  Cafe
//
//  Live Activities for Dynamic Island - Task Timer
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - TimeInterval Extension

extension TimeInterval {
    func formatted(pattern: TimeFormatPattern) -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60

        switch pattern {
        case .hourMinuteSecond:
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        case .hourMinute:
            return String(format: "%02d:%02d", hours, minutes)
        }
    }

    enum TimeFormatPattern {
        case hourMinuteSecond
        case hourMinute
    }
}

// MARK: - Activity Attributes

struct TaskActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var taskTitle: String
        var isRunning: Bool
        var elapsedTime: TimeInterval
        var startTime: Date
    }

    var taskId: Int
    var taskTitle: String
}

// MARK: - Live Activity Widget

@available(iOS 16.1, *)
struct TaskLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TaskActivityAttributes.self) { context in
            // Lock screen / banner UI
            TaskLiveActivityView(context: context)
                .padding()
                .activityBackgroundTint(Color.black.opacity(0.25))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(context.state.taskTitle)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Image(systemName: context.state.isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(context.state.isRunning ? .orange : .green)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 12) {
                        // Timer display
                        HStack {
                            Spacer()
                            Text(context.state.elapsedTime.formatted(pattern: .hourMinuteSecond))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Spacer()
                        }

                        // Controls
                        HStack(spacing: 20) {
                            Button(intent: ToggleTaskTimerIntent(taskId: context.attributes.taskId)) {
                                Label(
                                    context.state.isRunning ? "Pause" : "Resume",
                                    systemImage: context.state.isRunning ? "pause.fill" : "play.fill"
                                )
                            }
                            .buttonStyle(.bordered)
                            .tint(context.state.isRunning ? .orange : .green)

                            Button(intent: StopTaskTimerIntent(taskId: context.attributes.taskId)) {
                                Label("Complete", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                // Compact leading view (left side of pill)
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact trailing view (right side of pill)
                Text(context.state.elapsedTime.formatted(pattern: .hourMinute))
                    .font(.caption)
                    .monospacedDigit()
            } minimal: {
                // Minimal view (smallest state)
                Image(systemName: context.state.isRunning ? "clock.fill" : "clock")
                    .foregroundColor(context.state.isRunning ? .blue : .gray)
            }
        }
    }
}

// MARK: - Lock Screen View

struct TaskLiveActivityView: View {
    let context: ActivityViewContext<TaskActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Task title
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text(context.state.taskTitle)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }

            // Timer
            HStack {
                Spacer()
                Text(context.state.elapsedTime.formatted(pattern: .hourMinuteSecond))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Spacer()
            }

            // Status
            HStack {
                Image(systemName: context.state.isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .foregroundColor(context.state.isRunning ? .orange : .green)
                Text(context.state.isRunning ? "In Progress" : "Paused")
                    .font(.subheadline)
                Spacer()
                Text("Started \(context.state.startTime, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - App Intents for Live Activity Controls

struct ToggleTaskTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Timer"

    @Parameter(title: "Task ID")
    var taskId: Int

    init(taskId: Int) {
        self.taskId = taskId
    }

    init() {
        self.taskId = 0
    }

    func perform() async throws -> some IntentResult {
        // Toggle the timer state in the Live Activity
        await TaskLiveActivityManager.shared.toggleTimer(taskId: taskId)
        return .result()
    }
}

struct StopTaskTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Timer"

    @Parameter(title: "Task ID")
    var taskId: Int

    init(taskId: Int) {
        self.taskId = taskId
    }

    init() {
        self.taskId = 0
    }

    func perform() async throws -> some IntentResult {
        // Stop the timer and mark task as complete
        await TaskLiveActivityManager.shared.stopTimer(taskId: taskId)
        return .result()
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 16.1, *)
#Preview("Live Activity", as: .dynamicIsland(.compact), using: TaskActivityAttributes(taskId: 1, taskTitle: "Write documentation")) {
    TaskLiveActivity()
} contentStates: {
    TaskActivityAttributes.ContentState(
        taskTitle: "Write documentation",
        isRunning: true,
        elapsedTime: 3725,
        startTime: Date().addingTimeInterval(-3725)
    )

    TaskActivityAttributes.ContentState(
        taskTitle: "Write documentation",
        isRunning: false,
        elapsedTime: 3725,
        startTime: Date().addingTimeInterval(-3725)
    )
}
#endif
