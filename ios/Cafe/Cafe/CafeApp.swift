//
//  CafeApp.swift
//  Cafe
//
//  Created by Justin Scofield on 11/17/25.
//

import SwiftUI

@main
struct CafeApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
