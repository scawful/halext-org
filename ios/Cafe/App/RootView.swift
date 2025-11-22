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
    @State private var splitManager = SplitViewManager.shared

    var body: some View {
        ZStack {
            if splitManager.isSplitMode {
                // Split view mode
                SplitViewContainer()
            } else {
                // Normal tab view mode
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
            
            // Reorderable tab bar overlay (only in normal mode)
            if !splitManager.isSplitMode {
                ReorderableTabBarOverlay(
                    tabs: navManager.visibleTabs,
                    onReorder: { sourceIndex, destinationIndex in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            var tabs = navManager.visibleTabs
                            let item = tabs.remove(at: sourceIndex)
                            tabs.insert(item, at: destinationIndex)
                            navManager.updateVisibleTabs(tabs)
                        }
                    }
                )
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
        case .messages:
            MessagesView() // Unified: handles both AI and human conversations
        case .finance:
            FinanceView()
        case .pages:
            PagesView() // For AI context and notes
        case .admin:
            if appState.isAdmin {
                AdminView()
            } else {
                Text("Admin access required")
                    .foregroundColor(.secondary)
            }
        case .settings:
            SettingsView()
        case .templates:
            TaskTemplatesView()
        case .smartLists:
            SmartListsView()
        case .more:
            MoreView()
        }
    }
}


#Preview {
    RootView()
        .environment(AppState())
}
