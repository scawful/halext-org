//
//  RootView.swift
//  Cafe
//
//  Main navigation and app structure
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                if appState.isAppLocked {
                    BiometricAuthView {
                        appState.unlockApp()
                    }
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) var appState
    @State private var navManager = NavigationBarManager.shared

    var body: some View {
        TabView {
            ForEach(navManager.visibleTabs) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: NavigationTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .tasks:
            TaskListView()
        case .calendar:
            CalendarView()
        case .chat:
            ChatView()
        case .finance:
            FinanceView()
        case .settings:
            SettingsView()
        case .templates:
            TaskTemplatesView()
        case .smartLists:
            SmartListsView()
        case .pages:
            PagesView()
        case .messages:
            MessagesView()
        case .more:
            MoreView()
        }
    }
}

// Placeholder for Pages view
struct PagesView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Pages feature coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Pages")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AppState.self) var appState
    @State private var notificationManager = NotificationManager.shared
    @State private var biometricManager = BiometricAuthManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let user = appState.currentUser {
                        LabeledContent("Username", value: user.username)
                        LabeledContent("Email", value: user.email)
                        if let fullName = user.fullName {
                            LabeledContent("Name", value: fullName)
                        }
                    }
                }

                Section("Security") {
                    if biometricManager.isAvailable {
                        Toggle(isOn: Binding(
                            get: { biometricManager.isEnabled },
                            set: { enabled in
                                if enabled {
                                    biometricManager.enableBiometricAuth()
                                } else {
                                    biometricManager.disableBiometricAuth()
                                }
                            }
                        )) {
                            Label {
                                Text("App Lock with \(biometricManager.biometricType.displayName)")
                            } icon: {
                                Image(systemName: biometricManager.biometricType.icon)
                                    .foregroundColor(.blue)
                            }
                        }

                        Text("Require \(biometricManager.biometricType.displayName) to unlock the app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label {
                            Text("Biometric Auth Not Available")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }

                        Text("Set up Face ID or Touch ID in System Settings to use app lock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Notifications") {
                    if notificationManager.isAuthorized {
                        Label {
                            Text("Notifications Enabled")
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }

                        Button("Manage in System Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else {
                        Label {
                            Text("Notifications Disabled")
                        } icon: {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.secondary)
                        }

                        Button("Enable Notifications") {
                            _Concurrency.Task {
                                _ = await appState.requestNotificationPermissions()
                            }
                        }
                    }

                    Text("Get reminders for tasks and events")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Appearance") {
                    ThemeSwitcherView()

                    NavigationLink(destination: AdvancedThemeSettingsView()) {
                        Label("Advanced Theming", systemImage: "paintbrush")
                    }

                    NavigationLink(destination: NavigationBarSettingsView()) {
                        Label("Navigation Bar", systemImage: "square.split.bottomrightquarter")
                    }

                    NavigationLink(destination: GestureSettingsView()) {
                        Label("Gestures", systemImage: "hand.point.up.left")
                    }
                }

                Section("Communication") {
                    NavigationLink(destination: ChatSettingsView()) {
                        Label("Chat & AI Agents", systemImage: "bubble.left.and.bubble.right")
                    }
                }

                Section {
                    Button(role: .destructive, action: {
                        _Concurrency.Task {
                            await appState.logout()
                        }
                    }) {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
