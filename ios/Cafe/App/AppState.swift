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
            self.authToken = token
            self.isAuthenticated = true
            // Fetch current user in background
            Task {
                await self.loadCurrentUser()
            }
        }
    }

    // MARK: - Authentication

    @MainActor
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.login(username: username, password: password)
            authToken = response.accessToken
            isAuthenticated = true

            // Fetch user info
            await loadCurrentUser()

            isLoading = false
        } catch {
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
    }

    @MainActor
    private func loadCurrentUser() async {
        do {
            currentUser = try await APIClient.shared.getCurrentUser()
        } catch {
            print("❌ Failed to load current user:", error)
            // If fetching user fails, token might be invalid
            if let apiError = error as? APIError, apiError == .unauthorized {
                logout()
            }
        }
    }
}
