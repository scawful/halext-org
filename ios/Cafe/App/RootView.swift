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


#Preview {
    RootView()
        .environment(AppState())
}
