//
//  SocialPresenceManager.swift
//  Cafe
//
//  Enhanced presence manager for social features with CloudKit integration
//

import Foundation
import SwiftUI
import Combine

@MainActor
@Observable
class SocialPresenceManager {
    static let shared = SocialPresenceManager()

    // MARK: - Properties

    private var socialManager = SocialManager.shared
    private var updateTimer: Timer?
    private var backgroundTask: _Concurrency.Task<Void, Never>?

    var isTrackingPresence: Bool = false
    var lastPresenceUpdate: Date?

    // Presence update interval (in seconds)
    private let updateInterval: TimeInterval = 60 // Update every minute

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Presence Tracking

    func startTrackingPresence() {
        guard !isTrackingPresence else {
            return
        }
        
        // Only start tracking if CloudKit is available and profile exists
        guard socialManager.isCloudKitAvailable, socialManager.currentProfile != nil else {
            print("⚠️ Presence tracking not started: CloudKit unavailable or no profile")
            return
        }

        isTrackingPresence = true
        print("Starting presence tracking...")

        // Initial presence update
        _Concurrency.Task {
            await updatePresence(isOnline: true)
        }

        // Schedule periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor [weak self] in
                guard let self = self,
                      self.socialManager.isCloudKitAvailable,
                      self.socialManager.currentProfile != nil else {
                    // Stop tracking if conditions are no longer met
                    self?.stopTrackingPresence()
                    return
                }
                await self.updatePresence(isOnline: true)
            }
        }

        print("Presence tracking started")
    }

    func stopTrackingPresence() {
        guard isTrackingPresence else {
            return
        }

        isTrackingPresence = false
        updateTimer?.invalidate()
        updateTimer = nil

        // Final presence update
        _Concurrency.Task {
            await updatePresence(isOnline: false)
        }

        print("Presence tracking stopped")
    }

    func updatePresence(isOnline: Bool, currentActivity: String? = nil, statusMessage: String? = nil) async {
        // Check if CloudKit is available and profile exists before attempting update
        guard socialManager.isCloudKitAvailable else {
            // CloudKit not available - presence features disabled
            return
        }
        
        guard socialManager.currentProfile != nil else {
            // No profile yet - presence features require a profile
            // This is expected on first launch before profile is created
            return
        }
        
        do {
            try await socialManager.updatePresence(
                isOnline: isOnline,
                currentActivity: currentActivity,
                statusMessage: statusMessage
            )

            lastPresenceUpdate = Date()
            print("Updated presence: online=\(isOnline)")
        } catch {
            // Only log errors that aren't expected (like noProfile or cloudKitUnavailable)
            if let socialError = error as? SocialError {
                switch socialError {
                case .noProfile, .cloudKitUnavailable:
                    // These are expected when CloudKit/profile isn't set up
                    return
                default:
                    print("Failed to update presence: \(error)")
                }
            } else {
                print("Failed to update presence: \(error)")
            }
        }
    }

    func updateCurrentActivity(_ activity: String?) async {
        guard let profile = socialManager.currentProfile else {
            return
        }

        await updatePresence(
            isOnline: profile.isOnline,
            currentActivity: activity,
            statusMessage: profile.statusMessage
        )
    }

    func updateStatusMessage(_ message: String?) async {
        guard let profile = socialManager.currentProfile else {
            return
        }

        await updatePresence(
            isOnline: profile.isOnline,
            currentActivity: profile.currentActivity,
            statusMessage: message
        )
    }

    // MARK: - Partner Presence

    func startMonitoringPartnerPresence() {
        // Start background task to periodically fetch partner presence
        backgroundTask?.cancel()
        backgroundTask = _Concurrency.Task {
            while !_Concurrency.Task.isCancelled {
                await fetchPartnerPresence()

                // Wait before next check
                try? await _Concurrency.Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
            }
        }

        print("Started monitoring partner presence")
    }

    func stopMonitoringPartnerPresence() {
        backgroundTask?.cancel()
        backgroundTask = nil

        print("Stopped monitoring partner presence")
    }

    func fetchPartnerPresence() async {
        // Only fetch if CloudKit is available
        guard socialManager.isCloudKitAvailable else {
            return
        }
        
        do {
            try await socialManager.fetchPartnerPresence()
        } catch {
            // Only log unexpected errors
            if let socialError = error as? SocialError {
                switch socialError {
                case .cloudKitUnavailable:
                    return
                default:
                    print("Failed to fetch partner presence: \(error)")
                }
            } else {
                print("Failed to fetch partner presence: \(error)")
            }
        }
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        // App lifecycle notifications
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor [weak self] in
                await self?.handleAppWillEnterForeground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor [weak self] in
                await self?.handleAppDidEnterBackground()
            }
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor [weak self] in
                await self?.handleAppWillTerminate()
            }
        }
    }

    private func handleAppWillEnterForeground() async {
        print("App entering foreground - updating presence")
        startTrackingPresence()
        startMonitoringPartnerPresence()
        await updatePresence(isOnline: true)
    }

    private func handleAppDidEnterBackground() async {
        print("App entering background - marking offline")
        await updatePresence(isOnline: false)
        stopTrackingPresence()
        stopMonitoringPartnerPresence()
    }

    private func handleAppWillTerminate() async {
        print("App terminating - marking offline")
        await updatePresence(isOnline: false)
    }

    // MARK: - Status Presets

    enum StatusPreset {
        case working
        case meeting
        case lunch
        case onBreak
        case focusMode
        case custom(String)

        var text: String {
            switch self {
            case .working:
                return "Working on tasks"
            case .meeting:
                return "In a meeting"
            case .lunch:
                return "Out for lunch"
            case .onBreak:
                return "Taking a break"
            case .focusMode:
                return "Focus mode"
            case .custom(let text):
                return text
            }
        }

        var icon: String {
            switch self {
            case .working:
                return "laptopcomputer"
            case .meeting:
                return "person.3"
            case .lunch:
                return "fork.knife"
            case .onBreak:
                return "cup.and.saucer"
            case .focusMode:
                return "moon.stars"
            case .custom:
                return "pencil"
            }
        }
    }

    func setStatusPreset(_ preset: StatusPreset) async {
        await updateCurrentActivity(preset.text)
    }

    // MARK: - Cleanup

    deinit {
        _Concurrency.Task { @MainActor in
            updateTimer?.invalidate()
            backgroundTask?.cancel()
        }
    }
}

// MARK: - Presence Status View

struct SocialPresenceStatusView: View {
    let presence: SocialPresenceStatus
    let profile: SocialProfile?

    var body: some View {
        HStack(spacing: 8) {
            // Status Indicator
            ZStack {
                Circle()
                    .fill(presence.isOnline ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)

                if presence.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .opacity(0.3)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: presence.isOnline)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if let activity = presence.currentActivity {
                    Text(activity)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text(presence.isOnline ? "Online" : "Offline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let statusMessage = presence.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !presence.isOnline, let profile = profile, let lastSeen = profile.lastSeen {
                    Text("Last seen \(lastSeen.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Status Picker View

struct SocialStatusPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var presenceManager = SocialPresenceManager.shared
    @State private var customStatus: String = ""
    @State private var showingCustomInput = false

    let presets: [SocialPresenceManager.StatusPreset] = [
        .working,
        .meeting,
        .lunch,
        .onBreak,
        .focusMode
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(presets, id: \.text) { preset in
                        Button(action: {
                            setStatus(preset)
                        }) {
                            HStack {
                                Image(systemName: preset.icon)
                                    .frame(width: 30)
                                    .foregroundColor(.blue)

                                Text(preset.text)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Quick Status")
                }

                Section {
                    if showingCustomInput {
                        HStack {
                            TextField("Enter custom status", text: $customStatus)
                                .textInputAutocapitalization(.sentences)

                            Button("Set") {
                                setCustomStatus()
                            }
                            .disabled(customStatus.isEmpty)
                        }
                    } else {
                        Button(action: {
                            showingCustomInput = true
                        }) {
                            Label("Custom Status", systemImage: "pencil")
                        }
                    }
                } header: {
                    Text("Custom")
                }

                Section {
                    Button(role: .destructive, action: clearStatus) {
                        Label("Clear Status", systemImage: "xmark.circle")
                    }
                }
            }
            .navigationTitle("Set Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func setStatus(_ preset: SocialPresenceManager.StatusPreset) {
        _Concurrency.Task {
            await presenceManager.setStatusPreset(preset)
            dismiss()
        }
    }

    private func setCustomStatus() {
        guard !customStatus.isEmpty else {
            return
        }

        _Concurrency.Task {
            await presenceManager.updateCurrentActivity(customStatus)
            dismiss()
        }
    }

    private func clearStatus() {
        _Concurrency.Task {
            await presenceManager.updateCurrentActivity(nil)
            dismiss()
        }
    }
}

#Preview {
    SocialStatusPickerView()
}
