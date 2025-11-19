//
//  GestureManager.swift
//  Cafe
//
//  Manages custom gesture settings for task interactions
//

import Foundation
import SwiftUI

@MainActor
@Observable
class GestureManager {
    static let shared = GestureManager()

    var swipeRightAction: SwipeAction {
        didSet {
            saveSwipeRightAction()
        }
    }

    var swipeLeftAction: SwipeAction {
        didSet {
            saveSwipeLeftAction()
        }
    }

    var longPressAction: LongPressAction {
        didSet {
            saveLongPressAction()
        }
    }

    var doubleTapAction: DoubleTapAction {
        didSet {
            saveDoubleTapAction()
        }
    }

    private let defaults = UserDefaults.standard
    private let swipeRightKey = "swipeRightAction"
    private let swipeLeftKey = "swipeLeftAction"
    private let longPressKey = "longPressAction"
    private let doubleTapKey = "doubleTapAction"

    private init() {
        // Load saved gestures
        if let savedRight = defaults.string(forKey: swipeRightKey),
           let action = SwipeAction(rawValue: savedRight) {
            self.swipeRightAction = action
        } else {
            self.swipeRightAction = .complete
        }

        if let savedLeft = defaults.string(forKey: swipeLeftKey),
           let action = SwipeAction(rawValue: savedLeft) {
            self.swipeLeftAction = action
        } else {
            self.swipeLeftAction = .delete
        }

        if let savedLongPress = defaults.string(forKey: longPressKey),
           let action = LongPressAction(rawValue: savedLongPress) {
            self.longPressAction = action
        } else {
            self.longPressAction = .quickEdit
        }

        if let savedDoubleTap = defaults.string(forKey: doubleTapKey),
           let action = DoubleTapAction(rawValue: savedDoubleTap) {
            self.doubleTapAction = action
        } else {
            self.doubleTapAction = .startTimer
        }
    }

    // MARK: - Persistence

    private func saveSwipeRightAction() {
        defaults.set(swipeRightAction.rawValue, forKey: swipeRightKey)
    }

    private func saveSwipeLeftAction() {
        defaults.set(swipeLeftAction.rawValue, forKey: swipeLeftKey)
    }

    private func saveLongPressAction() {
        defaults.set(longPressAction.rawValue, forKey: longPressKey)
    }

    private func saveDoubleTapAction() {
        defaults.set(doubleTapAction.rawValue, forKey: doubleTapKey)
    }
}

// MARK: - Swipe Actions

enum SwipeAction: String, CaseIterable, Identifiable {
    case complete = "Complete"
    case archive = "Archive"
    case snooze = "Snooze"
    case delete = "Delete"
    case addLabel = "Add Label"
    case setDueDate = "Set Due Date"
    case duplicate = "Duplicate"
    case share = "Share"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .complete: return "checkmark.circle.fill"
        case .archive: return "archivebox.fill"
        case .snooze: return "clock.fill"
        case .delete: return "trash.fill"
        case .addLabel: return "tag.fill"
        case .setDueDate: return "calendar.badge.clock"
        case .duplicate: return "doc.on.doc.fill"
        case .share: return "square.and.arrow.up.fill"
        }
    }

    var color: Color {
        switch self {
        case .complete: return .green
        case .archive: return .blue
        case .snooze: return .orange
        case .delete: return .red
        case .addLabel: return .purple
        case .setDueDate: return .indigo
        case .duplicate: return .cyan
        case .share: return .blue
        }
    }

    var description: String {
        switch self {
        case .complete: return "Mark task as complete"
        case .archive: return "Archive the task"
        case .snooze: return "Snooze for 1 hour"
        case .delete: return "Delete the task"
        case .addLabel: return "Quick add label"
        case .setDueDate: return "Set or update due date"
        case .duplicate: return "Create a copy"
        case .share: return "Share the task"
        }
    }
}

// MARK: - Long Press Actions

enum LongPressAction: String, CaseIterable, Identifiable {
    case quickEdit = "Quick Edit"
    case duplicate = "Duplicate"
    case share = "Share"
    case viewDetails = "View Details"
    case addSubtask = "Add Subtask"
    case moveToList = "Move to List"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .quickEdit: return "pencil.circle.fill"
        case .duplicate: return "doc.on.doc.fill"
        case .share: return "square.and.arrow.up.fill"
        case .viewDetails: return "info.circle.fill"
        case .addSubtask: return "list.bullet.indent"
        case .moveToList: return "folder.fill"
        }
    }

    var description: String {
        switch self {
        case .quickEdit: return "Quick edit task details"
        case .duplicate: return "Create a duplicate task"
        case .share: return "Share task with others"
        case .viewDetails: return "Open full task details"
        case .addSubtask: return "Add a subtask"
        case .moveToList: return "Move to another list"
        }
    }
}

// MARK: - Double Tap Actions

enum DoubleTapAction: String, CaseIterable, Identifiable {
    case startTimer = "Start Timer"
    case addSubtask = "Add Subtask"
    case viewDetails = "View Details"
    case duplicate = "Duplicate"
    case togglePriority = "Toggle Priority"
    case quickComplete = "Quick Complete"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .startTimer: return "timer"
        case .addSubtask: return "list.bullet.indent"
        case .viewDetails: return "info.circle"
        case .duplicate: return "doc.on.doc"
        case .togglePriority: return "exclamationmark.triangle"
        case .quickComplete: return "checkmark.circle"
        }
    }

    var description: String {
        switch self {
        case .startTimer: return "Start focus timer for task"
        case .addSubtask: return "Add a subtask"
        case .viewDetails: return "Open full task details"
        case .duplicate: return "Create a duplicate"
        case .togglePriority: return "Mark as priority"
        case .quickComplete: return "Mark complete immediately"
        }
    }
}

// MARK: - Gesture Result

enum GestureResult {
    case complete(taskId: Int)
    case archive(taskId: Int)
    case snooze(taskId: Int, minutes: Int)
    case delete(taskId: Int)
    case addLabel(taskId: Int)
    case setDueDate(taskId: Int)
    case duplicate(taskId: Int)
    case share(taskId: Int)
    case quickEdit(taskId: Int)
    case viewDetails(taskId: Int)
    case addSubtask(taskId: Int)
    case moveToList(taskId: Int)
    case startTimer(taskId: Int)
    case togglePriority(taskId: Int)
}
