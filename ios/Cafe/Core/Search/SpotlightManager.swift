//
//  SpotlightManager.swift
//  Cafe
//
//  Spotlight search integration for tasks and events
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import UniformTypeIdentifiers
import UIKit

@MainActor
class SpotlightManager {
    static let shared = SpotlightManager()

    private init() {}

    // MARK: - Index Tasks

    func indexTask(_ task: Task) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

        // Basic info
        attributeSet.title = task.title
        attributeSet.contentDescription = task.description ?? "Tap to view task details"
        attributeSet.keywords = task.labels.map { $0.name }

        // Status
        attributeSet.completionDate = task.completed ? task.createdAt : nil

        // Dates
        attributeSet.contentCreationDate = task.createdAt
        if let dueDate = task.dueDate {
            attributeSet.dueDate = dueDate
            attributeSet.endDate = dueDate
        }

        // Priority (based on due date) - using ranking instead
        if let dueDate = task.dueDate, dueDate < Date() {
            attributeSet.rankingHint = 1.0 // High priority for overdue
        } else {
            attributeSet.rankingHint = 0.5
        }

        // Thumbnail
        attributeSet.thumbnailData = generateTaskThumbnail(task: task)

        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: "task-\(task.id)",
            domainIdentifier: "org.halext.cafe.tasks",
            attributeSet: attributeSet
        )

        // Index the item
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("❌ Failed to index task \(task.id): \(error.localizedDescription)")
            } else {
                print("✅ Indexed task: \(task.title)")
            }
        }
    }

    func indexTasks(_ tasks: [Task]) {
        let items = tasks.map { task -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.title = task.title
            attributeSet.contentDescription = task.description ?? "Task"
            attributeSet.keywords = task.labels.map { $0.name }
            attributeSet.contentCreationDate = task.createdAt
            attributeSet.dueDate = task.dueDate
            attributeSet.completionDate = task.completed ? task.createdAt : nil

            return CSSearchableItem(
                uniqueIdentifier: "task-\(task.id)",
                domainIdentifier: "org.halext.cafe.tasks",
                attributeSet: attributeSet
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("❌ Failed to batch index tasks: \(error.localizedDescription)")
            } else {
                print("✅ Indexed \(items.count) tasks")
            }
        }
    }

    func removeTask(id: Int) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["task-\(id)"]) { error in
            if let error = error {
                print("❌ Failed to remove task from index: \(error.localizedDescription)")
            } else {
                print("🗑️ Removed task \(id) from index")
            }
        }
    }

    // MARK: - Index Events

    func indexEvent(_ event: Event) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)

        // Basic info
        attributeSet.title = event.title
        attributeSet.contentDescription = event.description ?? "Tap to view event details"

        // Location
        if let location = event.location {
            attributeSet.namedLocation = location
            attributeSet.keywords = [location]
        }

        // Dates
        attributeSet.startDate = event.startTime
        attributeSet.endDate = event.endTime
        attributeSet.dueDate = event.startTime

        // Recurrence
        if event.recurrenceType != "none" {
            attributeSet.keywords?.append(event.recurrenceType)
        }

        // Thumbnail
        attributeSet.thumbnailData = generateEventThumbnail(event: event)

        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: "event-\(event.id)",
            domainIdentifier: "org.halext.cafe.events",
            attributeSet: attributeSet
        )

        // Index the item
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("❌ Failed to index event \(event.id): \(error.localizedDescription)")
            } else {
                print("✅ Indexed event: \(event.title)")
            }
        }
    }

    func indexEvents(_ events: [Event]) {
        let items = events.map { event -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.title = event.title
            attributeSet.contentDescription = event.description ?? "Event"
            attributeSet.startDate = event.startTime
            attributeSet.endDate = event.endTime
            if let location = event.location {
                attributeSet.namedLocation = location
            }

            return CSSearchableItem(
                uniqueIdentifier: "event-\(event.id)",
                domainIdentifier: "org.halext.cafe.events",
                attributeSet: attributeSet
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("❌ Failed to batch index events: \(error.localizedDescription)")
            } else {
                print("✅ Indexed \(items.count) events")
            }
        }
    }

    func removeEvent(id: Int) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["event-\(id)"]) { error in
            if let error = error {
                print("❌ Failed to remove event from index: \(error.localizedDescription)")
            } else {
                print("🗑️ Removed event \(id) from index")
            }
        }
    }

    // MARK: - Clear Index

    func clearAllTasks() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["org.halext.cafe.tasks"]) { error in
            if let error = error {
                print("❌ Failed to clear tasks from index: \(error.localizedDescription)")
            } else {
                print("🗑️ Cleared all tasks from Spotlight")
            }
        }
    }

    func clearAllEvents() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["org.halext.cafe.events"]) { error in
            if let error = error {
                print("❌ Failed to clear events from index: \(error.localizedDescription)")
            } else {
                print("🗑️ Cleared all events from Spotlight")
            }
        }
    }

    func clearAll() {
        clearAllTasks()
        clearAllEvents()
    }

    // MARK: - Thumbnail Generation

    private func generateTaskThumbnail(task: Task) -> Data? {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Circle icon
            let iconColor = task.completed ? UIColor.systemGreen : UIColor.systemBlue
            iconColor.setFill()

            let iconSize: CGFloat = 80
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )

            let iconPath = UIBezierPath(ovalIn: iconRect)
            iconPath.fill()

            // Checkmark if completed
            if task.completed {
                UIColor.white.setStroke()
                let checkPath = UIBezierPath()
                checkPath.lineWidth = 6
                checkPath.move(to: CGPoint(x: iconRect.midX - 15, y: iconRect.midY))
                checkPath.addLine(to: CGPoint(x: iconRect.midX - 5, y: iconRect.midY + 10))
                checkPath.addLine(to: CGPoint(x: iconRect.midX + 15, y: iconRect.midY - 10))
                checkPath.stroke()
            }
        }

        return image.pngData()
    }

    private func generateEventThumbnail(event: Event) -> Data? {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Calendar icon background
            UIColor.systemPurple.setFill()
            let iconRect = CGRect(x: 50, y: 50, width: 100, height: 100)
            let roundedRect = UIBezierPath(roundedRect: iconRect, cornerRadius: 15)
            roundedRect.fill()

            // Date text
            let day = Calendar.current.component(.day, from: event.startTime)
            let dayString = "\(day)" as NSString

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .bold),
                .foregroundColor: UIColor.white
            ]

            let textSize = dayString.size(withAttributes: attributes)
            let textRect = CGRect(
                x: iconRect.midX - textSize.width / 2,
                y: iconRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )

            dayString.draw(in: textRect, withAttributes: attributes)
        }

        return image.pngData()
    }
}
