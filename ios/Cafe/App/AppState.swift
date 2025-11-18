//
//  AppState.swift
//  Cafe
//
//  Observable app state for authentication and navigation
//

import Foundation
import SwiftUI

@Observable
class AppState {
    var isAuthenticated: Bool = false
    var currentUser: User?
    var authToken: String?
    var isLoading: Bool = false
    var errorMessage: String?

    init() {
        // Check if we have a stored token on app launch
        if let token = KeychainManager.shared.getToken() {
            print("🔑 Found stored token on app launch")
            print("🌍 Current environment: \(APIClient.shared.environment)")

            self.authToken = token
            self.isAuthenticated = true

            // Validate token with current environment
            _Concurrency.Task {
                await self.loadCurrentUser()
            }
        } else {
            print("🔓 No stored token found")
        }
    }

    // MARK: - Authentication

    @MainActor
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            print("📱 AppState: Starting login...")
            let response = try await APIClient.shared.login(username: username, password: password)
            authToken = response.accessToken
            isAuthenticated = true
            print("📱 AppState: Token saved, loading user...")

            // Fetch user info
            await loadCurrentUser()

            isLoading = false
            print("📱 AppState: Login complete")
        } catch {
            print("❌ AppState: Login failed - \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    func register(username: String, email: String, password: String, fullName: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await APIClient.shared.register(
                username: username,
                email: email,
                password: password,
                fullName: fullName
            )

            // After successful registration, log in
            await login(username: username, password: password)

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    func logout() {
        KeychainManager.shared.clearAll()
        authToken = nil
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }

    @MainActor
    private func loadCurrentUser() async {
        do {
            print("👤 Loading current user...")
            currentUser = try await APIClient.shared.getCurrentUser()
            print("✅ Current user loaded: \(currentUser?.username ?? "unknown")")
        } catch {
            print("❌ Failed to load current user:", error)
            // If fetching user fails, token might be invalid
            if let apiError = error as? APIError, apiError == .unauthorized {
                print("🚨 Unauthorized - logging out")
                errorMessage = "Session expired. Please sign in again."
                logout()
            }
        }
    }
}
