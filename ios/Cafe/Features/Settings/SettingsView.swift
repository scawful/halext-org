//
//  SettingsView.swift
//  Cafe
//
//  Enhanced settings with search, organization, and comprehensive options
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @State private var settingsManager = SettingsManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var biometricManager = BiometricAuthManager.shared
    @State private var themeManager = ThemeManager.shared

    @State private var searchText = ""
    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var showingDeleteAccount = false

    var body: some View {
        NavigationStack {
            List {
                // Search Bar
                if !settingsManager.recentlyChangedSettings.isEmpty {
                    recentlyChangedSection
                }

                // All Settings Sections
                if filteredSections.contains(.accountProfile) {
                    accountProfileSection
                }

                if filteredSections.contains(.appearance) {
                    appearanceSection
                }

                if filteredSections.contains(.privacySecurity) {
                    privacySecuritySection
                }

                if filteredSections.contains(.notifications) {
                    notificationsSection
                }

                if filteredSections.contains(.storageSync) {
                    storageSyncSection
                }

                if filteredSections.contains(.advancedFeatures) {
                    advancedFeaturesSection
                }

                if filteredSections.contains(.quickActions) {
                    quickActionsSection
                }

                if filteredSections.contains(.about) {
                    aboutSection
                }

                // Admin section - only visible to admin users
                if appState.isAdmin && filteredSections.contains(.admin) {
                    adminSection
                }

                // Sign Out
                signOutSection
            }
            .searchable(text: $searchText, prompt: "Search settings")
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingDataExport) {
                DataExportView()
            }
            .alert("Delete Account", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.")
            }
        }
    }

    // MARK: - Recently Changed Section

    private var recentlyChangedSection: some View {
        Section {
            ForEach(settingsManager.recentlyChangedSettings.prefix(5), id: \.self) { settingKey in
                if let item = settingsManager.settingItem(for: settingKey) {
                    SettingItemRow(item: item)
                }
            }
        } header: {
            Label("Recently Changed", systemImage: "clock.arrow.circlepath")
        }
    }

    // MARK: - Account & Profile Section

    private var accountProfileSection: some View {
        Section {
            if let user = appState.currentUser {
                // Profile Info
                HStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(user.username.prefix(1).uppercased())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.fullName ?? user.username)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Navigate to profile edit
                }
            }

            NavigationLink {
                ConnectedDevicesView()
            } label: {
                SettingsItemLabel(
                    icon: "iphone.and.ipad",
                    iconColor: .blue,
                    title: "Connected Devices",
                    subtitle: "\(settingsManager.connectedDevicesCount) devices"
                )
            }

            NavigationLink {
                SocialConnectionsView()
            } label: {
                SettingsItemLabel(
                    icon: "person.2.fill",
                    iconColor: .green,
                    title: "Social Connections",
                    subtitle: "Link accounts"
                )
            }
        } header: {
            Label("Account & Profile", systemImage: "person.crop.circle")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            NavigationLink {
                ThemeSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "paintbrush.fill",
                    iconColor: .purple,
                    title: "Theme",
                    subtitle: themeManager.currentTheme.name
                )
            }

            NavigationLink {
                FontSizeSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "textformat.size",
                    iconColor: .orange,
                    title: "Font Size",
                    subtitle: themeManager.fontSizePreference.rawValue
                )
            }

            NavigationLink {
                AccentColorSettingsView()
            } label: {
                HStack {
                    SettingsItemLabel(
                        icon: "circle.fill",
                        iconColor: themeManager.accentColor,
                        title: "Accent Color",
                        subtitle: nil
                    )

                    Spacer()

                    Circle()
                        .fill(themeManager.accentColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            NavigationLink {
                DashboardLayoutSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "square.grid.3x3.fill",
                    iconColor: .cyan,
                    title: "Dashboard Layout",
                    subtitle: "Customize widgets"
                )
            }

            NavigationLink {
                AdvancedThemeSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "paintpalette",
                    iconColor: .pink,
                    title: "Advanced Theming",
                    subtitle: nil
                )
            }

            NavigationLink {
                NavigationBarSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "menubar.rectangle",
                    iconColor: .indigo,
                    title: "Navigation Bar",
                    subtitle: nil
                )
            }

            NavigationLink {
                GestureSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "hand.point.up.left.fill",
                    iconColor: .orange,
                    title: "Gestures",
                    subtitle: nil
                )
            }
        } header: {
            Label("Appearance", systemImage: "paintbrush")
        }
    }

    // MARK: - Privacy & Security Section

    private var privacySecuritySection: some View {
        Section {
            if biometricManager.isAvailable {
                Toggle(isOn: Binding(
                    get: { biometricManager.isEnabled },
                    set: { enabled in
                        if enabled {
                            biometricManager.enableBiometricAuth()
                        } else {
                            biometricManager.disableBiometricAuth()
                        }
                        settingsManager.recordSettingChange("biometric_auth")
                    }
                )) {
                    SettingsItemLabel(
                        icon: biometricManager.biometricType.icon,
                        iconColor: .blue,
                        title: "App Lock",
                        subtitle: "Require \(biometricManager.biometricType.displayName)"
                    )
                }
            }

            Toggle(isOn: $settingsManager.analyticsEnabled.onChange { _ in
                settingsManager.recordSettingChange("analytics")
            }) {
                SettingsItemLabel(
                    icon: "chart.bar.fill",
                    iconColor: .green,
                    title: "Analytics",
                    subtitle: "Help improve the app"
                )
            }

            Toggle(isOn: $settingsManager.crashReportingEnabled.onChange { _ in
                settingsManager.recordSettingChange("crash_reporting")
            }) {
                SettingsItemLabel(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: "Crash Reporting",
                    subtitle: "Send crash reports"
                )
            }

            Button(action: { showingDataExport = true }) {
                SettingsItemLabel(
                    icon: "square.and.arrow.up",
                    iconColor: .blue,
                    title: "Export Data",
                    subtitle: "Download your data"
                )
            }

            Button(action: { showingDeleteAccount = true }) {
                SettingsItemLabel(
                    icon: "trash.fill",
                    iconColor: .red,
                    title: "Delete Account",
                    subtitle: "Permanently delete"
                )
            }
        } header: {
            Label("Privacy & Security", systemImage: "lock.shield")
        } footer: {
            Text("Your privacy is important. We only collect data necessary to improve your experience.")
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            if notificationManager.isAuthorized {
                Label {
                    Text("Notifications Enabled")
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }

                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    SettingsItemLabel(
                        icon: "bell.badge.fill",
                        iconColor: .purple,
                        title: "Notification Preferences",
                        subtitle: "Customize alerts"
                    )
                }

                NavigationLink {
                    QuietHoursSettingsView()
                } label: {
                    SettingsItemLabel(
                        icon: "moon.fill",
                        iconColor: .indigo,
                        title: "Quiet Hours",
                        subtitle: settingsManager.quietHoursEnabled ? "Enabled" : "Disabled"
                    )
                }

                NavigationLink {
                    NotificationSoundsView()
                } label: {
                    SettingsItemLabel(
                        icon: "speaker.wave.2.fill",
                        iconColor: .blue,
                        title: "Notification Sounds",
                        subtitle: nil
                    )
                }
            } else {
                Label {
                    Text("Notifications Disabled")
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: "bell.slash.fill")
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    _Concurrency.Task {
                        _ = await appState.requestNotificationPermissions()
                    }
                }) {
                    SettingsItemLabel(
                        icon: "bell.badge",
                        iconColor: .blue,
                        title: "Enable Notifications",
                        subtitle: nil
                    )
                }
            }
        } header: {
            Label("Notifications", systemImage: "bell")
        } footer: {
            Text("Control when and how you receive notifications from Cafe.")
        }
    }

    // MARK: - Storage & Sync Section

    private var storageSyncSection: some View {
        Section {
            Toggle(isOn: $settingsManager.iCloudSyncEnabled.onChange { _ in
                settingsManager.recordSettingChange("icloud_sync")
            }) {
                SettingsItemLabel(
                    icon: "icloud.fill",
                    iconColor: .blue,
                    title: "iCloud Sync",
                    subtitle: "Sync across devices"
                )
            }

            NavigationLink {
                StorageUsageView()
            } label: {
                SettingsItemLabel(
                    icon: "internaldrive.fill",
                    iconColor: .orange,
                    title: "Storage Usage",
                    subtitle: settingsManager.storageUsageString
                )
            }

            Button(action: {
                clearCache()
            }) {
                SettingsItemLabel(
                    icon: "trash.circle.fill",
                    iconColor: .red,
                    title: "Clear Cache",
                    subtitle: settingsManager.cacheSize
                )
            }

            Toggle(isOn: $settingsManager.offlineMode.onChange { _ in
                settingsManager.recordSettingChange("offline_mode")
            }) {
                SettingsItemLabel(
                    icon: "wifi.slash",
                    iconColor: .gray,
                    title: "Offline Mode",
                    subtitle: "Work without internet"
                )
            }
        } header: {
            Label("Storage & Sync", systemImage: "externaldrive.fill.badge.icloud")
        }
    }

    // MARK: - Advanced Features Section

    private var advancedFeaturesSection: some View {
        Section {
            Toggle(isOn: $settingsManager.labsEnabled.onChange { _ in
                settingsManager.recordSettingChange("labs_enabled")
            }) {
                SettingsItemLabel(
                    icon: "flask.fill",
                    iconColor: .purple,
                    title: "Labs",
                    subtitle: "Experimental features"
                )
            }

            if settingsManager.labsEnabled {
                NavigationLink {
                    LabsFeaturesView()
                } label: {
                    SettingsItemLabel(
                        icon: "sparkles",
                        iconColor: .pink,
                        title: "Experimental Features",
                        subtitle: "\(settingsManager.enabledLabsFeatures.count) enabled"
                    )
                }
            }

            NavigationLink {
                WidgetSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "square.stack.3d.up.fill",
                    iconColor: .green,
                    title: "Widgets",
                    subtitle: "Home & lock screen"
                )
            }

            NavigationLink {
                ShortcutsConfigView()
            } label: {
                SettingsItemLabel(
                    icon: "command",
                    iconColor: .blue,
                    title: "Shortcuts",
                    subtitle: "Siri & automation"
                )
            }

            NavigationLink {
                AdvancedFeaturesView()
            } label: {
                SettingsItemLabel(
                    icon: "wand.and.stars",
                    iconColor: .orange,
                    title: "Power User Features",
                    subtitle: "Advanced iOS features"
                )
            }

            NavigationLink {
                ChatSettingsView()
            } label: {
                SettingsItemLabel(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: .cyan,
                    title: "Chat & AI",
                    subtitle: "Configure AI agents"
                )
            }
        } header: {
            Label("Advanced Features", systemImage: "gearshape.2")
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        Section {
            Button(action: { showingDataExport = true }) {
                SettingsItemLabel(
                    icon: "square.and.arrow.up.fill",
                    iconColor: .blue,
                    title: "Export All Data",
                    subtitle: nil
                )
            }

            Button(action: { contactSupport() }) {
                SettingsItemLabel(
                    icon: "envelope.fill",
                    iconColor: .green,
                    title: "Contact Support",
                    subtitle: nil
                )
            }

            Button(action: { rateApp() }) {
                SettingsItemLabel(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Rate App",
                    subtitle: nil
                )
            }

            Button(action: { shareApp() }) {
                SettingsItemLabel(
                    icon: "square.and.arrow.up",
                    iconColor: .purple,
                    title: "Share App",
                    subtitle: nil
                )
            }
        } header: {
            Label("Quick Actions", systemImage: "bolt.fill")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            Button(action: { showingAbout = true }) {
                HStack {
                    SettingsItemLabel(
                        icon: "info.circle.fill",
                        iconColor: .blue,
                        title: "About Cafe",
                        subtitle: "Version \(appVersion)"
                    )
                    Spacer()
                }
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                SettingsItemLabel(
                    icon: "hand.raised.fill",
                    iconColor: .green,
                    title: "Privacy Policy",
                    subtitle: nil
                )
            }

            NavigationLink {
                TermsOfServiceView()
            } label: {
                SettingsItemLabel(
                    icon: "doc.text.fill",
                    iconColor: .orange,
                    title: "Terms of Service",
                    subtitle: nil
                )
            }

            NavigationLink {
                CreditsView()
            } label: {
                SettingsItemLabel(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Credits",
                    subtitle: nil
                )
            }

            NavigationLink {
                HelpView()
            } label: {
                SettingsItemLabel(
                    icon: "questionmark.circle.fill",
                    iconColor: .purple,
                    title: "Help & Documentation",
                    subtitle: nil
                )
            }
        } header: {
            Label("About", systemImage: "info.circle")
        } footer: {
            VStack(spacing: 8) {
                Text("Cafe v\(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Made with care for productivity enthusiasts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }

    // MARK: - Admin Section

    private var adminSection: some View {
        Section {
            NavigationLink {
                AdminView()
            } label: {
                SettingsItemLabel(
                    icon: "shield.fill",
                    iconColor: .orange,
                    title: "Admin Panel",
                    subtitle: "System management"
                )
            }
        } header: {
            Label("Administration", systemImage: "shield")
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        Section {
            Button(role: .destructive, action: {
                _Concurrency.Task {
                    await appState.logout()
                }
            }) {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Filtering

    private var filteredSections: Set<SettingsSection> {
        if searchText.isEmpty {
            return Set(SettingsSection.allCases)
        }

        let lowercased = searchText.lowercased()
        var sections = Set<SettingsSection>()

        // Search through all settings
        for section in SettingsSection.allCases {
            if section.searchableTerms.contains(where: { $0.lowercased().contains(lowercased) }) {
                sections.insert(section)
            }
        }

        return sections
    }

    // MARK: - Helper Methods

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private func clearCache() {
        _Concurrency.Task {
            await settingsManager.clearCache()
        }
    }

    private func deleteAccount() {
        _Concurrency.Task {
            // TODO: Implement delete account functionality
            // await appState.deleteAccount()
            print("Delete account requested")
        }
    }

    private func contactSupport() {
        if let url = URL(string: "mailto:support@cafe.app") {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id123456789") {
            UIApplication.shared.open(url)
        }
    }

    private func shareApp() {
        let text = "Check out Cafe - The ultimate productivity app!"
        let url = URL(string: "https://cafe.app")!
        let activityController = UIActivityViewController(activityItems: [text, url], applicationActivities: nil)

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = scene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - Settings Item Label

struct SettingsItemLabel: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Settings Section Enum

enum SettingsSection: String, CaseIterable {
    case accountProfile = "Account & Profile"
    case appearance = "Appearance"
    case privacySecurity = "Privacy & Security"
    case notifications = "Notifications"
    case storageSync = "Storage & Sync"
    case advancedFeatures = "Advanced Features"
    case quickActions = "Quick Actions"
    case about = "About"
    case admin = "Administration"

    var searchableTerms: [String] {
        switch self {
        case .accountProfile:
            return ["account", "profile", "user", "devices", "social", "connections"]
        case .appearance:
            return ["appearance", "theme", "font", "color", "accent", "dashboard", "layout", "navigation", "gestures"]
        case .privacySecurity:
            return ["privacy", "security", "biometric", "face id", "touch id", "analytics", "crash", "export", "delete", "data"]
        case .notifications:
            return ["notifications", "alerts", "quiet hours", "sounds", "badge"]
        case .storageSync:
            return ["storage", "sync", "icloud", "cache", "offline", "data"]
        case .advancedFeatures:
            return ["advanced", "labs", "experimental", "widgets", "shortcuts", "siri", "chat", "ai"]
        case .quickActions:
            return ["export", "support", "rate", "share", "contact"]
        case .about:
            return ["about", "version", "privacy", "terms", "credits", "help"]
        case .admin:
            return ["admin", "administrator", "management"]
        }
    }
}

// MARK: - Setting Item Row

struct SettingItemRow: View {
    let item: SettingItem

    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.iconColor)
                .frame(width: 24)

            Text(item.title)
                .font(.subheadline)

            Spacer()

            Text(item.currentValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Binding Extension

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(AppState())
}
