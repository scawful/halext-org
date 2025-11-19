//
//  ClipboardMonitor.swift
//  Cafe
//
//  Smart clipboard monitoring for task suggestions
//

import UIKit
import SwiftUI
import Combine

@MainActor
class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published var hasClipboardSuggestion = false
    @Published var currentSuggestion: ClipboardSuggestion?

    private var lastChangeCount: Int = 0
    private var monitorTimer: Timer?
    private var lastProcessedContent: String?

    // Settings
    private let monitoringInterval: TimeInterval = 2.0
    private let minimumTextLength = 10
    private let userDefaultsKey = "clipboardMonitoringEnabled"

    var isMonitoringEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
            if newValue {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    private init() {
        // Enable by default
        if !UserDefaults.standard.bool(forKey: "\(userDefaultsKey)_initialized") {
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
            UserDefaults.standard.set(true, forKey: "\(userDefaultsKey)_initialized")
        }

        if isMonitoringEnabled {
            startMonitoring()
        }
    }

    // MARK: - Monitoring Control

    func startMonitoring() {
        print("📋 Starting clipboard monitoring...")

        // Update initial change count
        lastChangeCount = UIPasteboard.general.changeCount

        // Start timer
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(
            withTimeInterval: monitoringInterval,
            repeats: true
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.checkClipboard()
            }
        }
    }

    func stopMonitoring() {
        print("📋 Stopping clipboard monitoring")
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    // MARK: - Clipboard Checking

    private func checkClipboard() {
        let currentChangeCount = UIPasteboard.general.changeCount

        // Check if clipboard changed
        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        // Process clipboard content
        processClipboardContent()
    }

    private func processClipboardContent() {
        // Check for URL
        if let url = UIPasteboard.general.url {
            processURL(url)
            return
        }

        // Check for string
        if let string = UIPasteboard.general.string {
            processString(string)
            return
        }

        // Check for image
        if let image = UIPasteboard.general.image {
            processImage(image)
            return
        }
    }

    // MARK: - Content Processing

    private func processURL(_ url: URL) {
        // Skip if already processed
        guard url.absoluteString != lastProcessedContent else { return }
        lastProcessedContent = url.absoluteString

        print("📋 Detected URL in clipboard: \(url.absoluteString)")

        // Create suggestion
        let title = url.host ?? "Link"
        let description = url.absoluteString

        let suggestion = ClipboardSuggestion(
            id: UUID(),
            type: .url,
            title: title,
            description: description,
            url: url,
            detectedAt: Date()
        )

        showSuggestion(suggestion)
    }

    private func processString(_ string: String) {
        // Skip short strings
        guard string.count >= minimumTextLength else { return }

        // Skip if already processed
        guard string != lastProcessedContent else { return }
        lastProcessedContent = string

        // Skip if it's just a URL (already handled above)
        if let _ = URL(string: string), string.hasPrefix("http") {
            return
        }

        print("📋 Detected text in clipboard: \(string.prefix(50))...")

        // Check if text looks like a task
        if looksLikeTask(string) {
            let lines = string.components(separatedBy: .newlines)
            let title = String(lines.first?.prefix(100) ?? "")
            let description = lines.count > 1 ? lines.dropFirst().joined(separator: "\n") : nil

            let suggestion = ClipboardSuggestion(
                id: UUID(),
                type: .text,
                title: title,
                description: description,
                detectedAt: Date()
            )

            showSuggestion(suggestion)
        }
    }

    private func processImage(_ image: UIImage) {
        // Skip if already processed (use hash of image)
        let imageHash = "\(image.size.width)x\(image.size.height)"
        guard imageHash != lastProcessedContent else { return }
        lastProcessedContent = imageHash

        print("📋 Detected image in clipboard")

        let suggestion = ClipboardSuggestion(
            id: UUID(),
            type: .image,
            title: "Image Task",
            description: "Create task from copied image",
            image: image,
            detectedAt: Date()
        )

        showSuggestion(suggestion)
    }

    // MARK: - Suggestion Logic

    private func looksLikeTask(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Keywords that suggest task-like content
        let taskKeywords = [
            "todo", "task", "remember", "don't forget",
            "need to", "have to", "must", "should",
            "buy", "call", "email", "send", "write",
            "meeting", "appointment", "deadline"
        ]

        // Check for task keywords
        if taskKeywords.contains(where: { lowercased.contains($0) }) {
            return true
        }

        // Check for imperative verbs at start
        let imperativeVerbs = [
            "add", "create", "make", "do", "finish",
            "complete", "review", "check", "update"
        ]

        if imperativeVerbs.contains(where: { lowercased.hasPrefix($0) }) {
            return true
        }

        // Check for list-like format (multiple lines with bullets/numbers)
        let lines = text.components(separatedBy: .newlines)
        if lines.count > 1 {
            let bulletLines = lines.filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed.hasPrefix("•") ||
                       trimmed.hasPrefix("-") ||
                       trimmed.hasPrefix("*") ||
                       trimmed.range(of: "^\\d+\\.", options: .regularExpression) != nil
            }

            if bulletLines.count >= 2 {
                return true
            }
        }

        return false
    }

    private func showSuggestion(_ suggestion: ClipboardSuggestion) {
        currentSuggestion = suggestion
        hasClipboardSuggestion = true

        // Show notification
        _Concurrency.Task {
            await NotificationManager.shared.showLocalNotification(
                title: "Create task from clipboard?",
                body: suggestion.title,
                identifier: "clipboard-\(suggestion.id.uuidString)"
            )
        }
    }

    // MARK: - Actions

    func acceptSuggestion() async {
        guard let suggestion = currentSuggestion else { return }

        print("✅ Accepting clipboard suggestion: \(suggestion.title)")

        // Create task from suggestion
        let taskCreate = TaskCreate(
            title: suggestion.title,
            description: suggestion.description,
            dueDate: nil,
            labels: ["clipboard"] // Tag with clipboard label
        )

        do {
            if NetworkMonitor.shared.isConnected {
                let task = try await APIClient.shared.createTask(taskCreate)
                try? StorageManager.shared.saveTask(task)
                print("✅ Created task from clipboard: \(task.title)")
            } else {
                let task = try await SyncManager.shared.createTaskOffline(taskCreate)
                print("📱 Created task offline from clipboard: \(task.title)")
            }

            // Update widgets
            WidgetUpdateManager.shared.reloadTaskWidgets()

            // Show success notification
            await NotificationManager.shared.showLocalNotification(
                title: "Task Created",
                body: "Created from clipboard: \(suggestion.title)"
            )

            // Clear suggestion
            dismissSuggestion()

        } catch {
            print("❌ Failed to create task from clipboard: \(error.localizedDescription)")
        }
    }

    func dismissSuggestion() {
        currentSuggestion = nil
        hasClipboardSuggestion = false
    }

    // MARK: - Manual Check

    func checkClipboardNow() {
        // Force check clipboard immediately
        lastChangeCount = -1 // Reset to force check
        checkClipboard()
    }
}

// MARK: - Clipboard Suggestion

struct ClipboardSuggestion: Identifiable {
    let id: UUID
    let type: SuggestionType
    let title: String
    let description: String?
    var url: URL?
    var image: UIImage?
    let detectedAt: Date

    enum SuggestionType {
        case url
        case text
        case image
    }
}
