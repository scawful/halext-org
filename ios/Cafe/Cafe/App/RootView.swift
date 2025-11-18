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
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

            TaskListView()
                .tabItem {
                    Label("Tasks", systemImage: "checkmark.circle")
                }

            EventListView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ChatView()
                .tabItem {
                    Label("AI Chat", systemImage: "bubble.left.and.bubble.right")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Placeholder Views

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("📊 Dashboard")
                        .font(.largeTitle)
                        .padding()

                    Text("Your personalized dashboard will appear here")
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct EventListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("📅 Events")
                    .font(.largeTitle)
                    .padding()

                Text("Your calendar events will appear here")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Calendar")
        }
    }
}

struct ChatView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("💬 AI Chat")
                    .font(.largeTitle)
                    .padding()

                Text("Chat with your AI assistant")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Chat")
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) var appState

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

                Section {
                    Button("Sign Out", role: .destructive) {
                        appState.logout()
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
