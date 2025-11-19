//
//  CafeApp.swift
//  Cafe
//
//  Created by Justin Scofield on 11/17/25.
//

import SwiftUI
import SwiftData

@main
struct CafeApp: App {
    @State private var appState = AppState()
    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(themeManager)
                .modelContainer(StorageManager.shared.modelContainer)
                .preferredColorScheme(themeManager.appearanceMode.colorScheme)
        }
    }
}
