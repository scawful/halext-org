//
//  SettingsManager.swift
//  Cafe
//
//  Manages app settings and user preferences with persistence
//

import SwiftUI
import Foundation

@Observable
class SettingsManager {
    static let shared = SettingsManager()

    // MARK: - Recently Changed Settings

    @ObservationIgnored
    @AppStorage("recently_changed_settings") private var recentlyChangedSettingsData: Data = Data()

    var recentlyChangedSettings: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: recentlyChangedSettingsData)) ?? []
        }
        set {
            recentlyChangedSettingsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    // MARK: - Privacy & Security

    @ObservationIgnored
    @AppStorage("analytics_enabled") var analyticsEnabled: Bool = true

    @ObservationIgnored
    @AppStorage("crash_reporting_enabled") var crashReportingEnabled: Bool = true

    // MARK: - Notifications

    @ObservationIgnored
    @AppStorage("quiet_hours_enabled") var quietHoursEnabled: Bool = false

    @ObservationIgnored
    @AppStorage("quiet_hours_start") private var quietHoursStartString: String = "22:00"

    @ObservationIgnored
    @AppStorage("quiet_hours_end") private var quietHoursEndString: String = "07:00"

    var quietHoursStart: Date {
        get {
            dateFromTimeString(quietHoursStartString)
        }
        set {
            quietHoursStartString = timeStringFromDate(newValue)
        }
    }

    var quietHoursEnd: Date {
        get {
            dateFromTimeString(quietHoursEndString)
        }
        set {
            quietHoursEndString = timeStringFromDate(newValue)
        }
    }

    // MARK: - Storage & Sync

    @ObservationIgnored
    @AppStorage("icloud_sync_enabled") var iCloudSyncEnabled: Bool = true

    @ObservationIgnored
    @AppStorage("offline_mode") var offlineMode: Bool = false

    // MARK: - Advanced Features

    @ObservationIgnored
    @AppStorage("labs_enabled") var labsEnabled: Bool = false

    @ObservationIgnored
    @AppStorage("enabled_labs_features") private var enabledLabsFeaturesData: Data = Data()

    var enabledLabsFeatures: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: enabledLabsFeaturesData)) ?? []
        }
        set {
            enabledLabsFeaturesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    // MARK: - AI Settings

    @ObservationIgnored
    @AppStorage("selected_ai_model_id") var selectedAiModelId: String?

    @ObservationIgnored
    @AppStorage("ai_cloud_providers_disabled") var cloudProvidersDisabled: Bool = false

    // MARK: - Account & Profile

    var connectedDevicesCount: Int {
        // This would be fetched from the server
        3
    }

    // MARK: - Storage Info

    var storageUsageString: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(calculateStorageUsage()))
    }

    var cacheSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(calculateCacheSize()))
    }

    // MARK: - Private Init

    private init() {}

    // MARK: - Methods

    func recordSettingChange(_ settingKey: String) {
        var settings = recentlyChangedSettings
        settings.removeAll { $0 == settingKey }
        settings.insert(settingKey, at: 0)
        if settings.count > 10 {
            settings = Array(settings.prefix(10))
        }
        recentlyChangedSettings = settings
    }

    func settingItem(for key: String) -> SettingItem? {
        switch key {
        case "biometric_auth":
            return SettingItem(
                icon: "faceid",
                iconColor: .blue,
                title: "App Lock",
                currentValue: BiometricAuthManager.shared.isEnabled ? "On" : "Off"
            )
        case "analytics":
            return SettingItem(
                icon: "chart.bar.fill",
                iconColor: .green,
                title: "Analytics",
                currentValue: analyticsEnabled ? "On" : "Off"
            )
        case "crash_reporting":
            return SettingItem(
                icon: "exclamationmark.triangle.fill",
                iconColor: .orange,
                title: "Crash Reporting",
                currentValue: crashReportingEnabled ? "On" : "Off"
            )
        case "icloud_sync":
            return SettingItem(
                icon: "icloud.fill",
                iconColor: .blue,
                title: "iCloud Sync",
                currentValue: iCloudSyncEnabled ? "On" : "Off"
            )
        case "offline_mode":
            return SettingItem(
                icon: "wifi.slash",
                iconColor: .gray,
                title: "Offline Mode",
                currentValue: offlineMode ? "On" : "Off"
            )
        case "labs_enabled":
            return SettingItem(
                icon: "flask.fill",
                iconColor: .purple,
                title: "Labs",
                currentValue: labsEnabled ? "On" : "Off"
            )
        default:
            return nil
        }
    }

    func clearCache() async {
        // Clear various caches
        URLCache.shared.removeAllCachedResponses()

        // Clear temporary files
        let fileManager = FileManager.default
        if let tempDir = try? fileManager.contentsOfDirectory(atPath: NSTemporaryDirectory()) {
            for file in tempDir {
                try? fileManager.removeItem(atPath: NSTemporaryDirectory() + file)
            }
        }
    }

    // MARK: - Private Helpers

    private func calculateStorageUsage() -> Int {
        // Calculate app storage usage
        var totalSize = 0

        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let enumerator = FileManager.default.enumerator(at: documentsPath, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += fileSize
                    }
                }
            }
        }

        return totalSize
    }

    private func calculateCacheSize() -> Int {
        // Calculate cache size
        var totalSize = 0

        if let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let enumerator = FileManager.default.enumerator(at: cachesPath, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += fileSize
                    }
                }
            }
        }

        return totalSize
    }

    private func dateFromTimeString(_ timeString: String) -> Date {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return Date()
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        return Calendar.current.date(from: dateComponents) ?? Date()
    }

    private func timeStringFromDate(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            return "00:00"
        }
        return String(format: "%02d:%02d", hour, minute)
    }

    // MARK: - Labs Features

    func enableLabsFeature(_ featureId: String) {
        var features = enabledLabsFeatures
        features.insert(featureId)
        enabledLabsFeatures = features
    }

    func disableLabsFeature(_ featureId: String) {
        var features = enabledLabsFeatures
        features.remove(featureId)
        enabledLabsFeatures = features
    }

    func isLabsFeatureEnabled(_ featureId: String) -> Bool {
        enabledLabsFeatures.contains(featureId)
    }
}

// MARK: - Setting Item Model

struct SettingItem {
    let icon: String
    let iconColor: Color
    let title: String
    let currentValue: String
}
