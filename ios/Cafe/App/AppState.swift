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

    // Notification Management
    var notificationsEnabled: Bool {
        NotificationManager.shared.isAuthorized
    }

    // Biometric Auth Management
    var isAppLocked: Bool = false
    var biometricAuthEnabled: Bool {
        BiometricAuthManager.shared.isEnabled
    }

    // Offline Support
    var isOnline: Bool {
        NetworkMonitor.shared.isConnected
    }
    var isSyncing: Bool {
        SyncManager.shared.isSyncing
    }

    // Admin Access
    var isAdmin: Bool {
        currentUser?.isAdmin ?? false
    }

    init() {
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()

        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()
        print("🌍 Network monitoring started")

        // Check if we have a stored token on app launch
        if let token = KeychainManager.shared.getToken() {
            print("🔑 Found stored token on app launch")
            print("🌍 Current environment: \(APIClient.shared.environment)")

            self.authToken = token
            // Don't set isAuthenticated = true yet, wait for token validation

            // Lock app if biometric auth is enabled
            if BiometricAuthManager.shared.shouldRequireAuthentication() {
                self.isAppLocked = true
                print("🔒 App locked - biometric auth required")
            }

            // Validate token with current environment
            _Concurrency.Task {
                await self.validateStoredToken()
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

            // Initial sync after login
            await SyncManager.shared.syncAll()

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
            _ = try await APIClient.shared.register(
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
    func logout() async {
        KeychainManager.shared.clearAll()
        NotificationManager.shared.removeAllPendingNotifications()
        NotificationManager.shared.clearBadge()

        // Clear local cache and pending actions
        do {
            try await SyncManager.shared.clearCache()
            print("🗑️ Local cache cleared on logout")
        } catch {
            print("❌ Failed to clear cache: \(error.localizedDescription)")
        }

        authToken = nil
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }

    @MainActor
    private func validateStoredToken() async {
        print("🔍 Validating stored token...")

        do {
            // Try to load current user with stored token
            currentUser = try await APIClient.shared.getCurrentUser()
            print("✅ Token valid - user: \(currentUser?.username ?? "unknown")")

            // Only set authenticated if token validation succeeded
            isAuthenticated = true

            // Initial sync after token validation
            await SyncManager.shared.syncAll()
        } catch {
            print("❌ Token validation failed: \(error.localizedDescription)")

            // If token is invalid, clear it and show login
            if let apiError = error as? APIError, apiError == .unauthorized {
                print("🚨 Token expired or invalid - clearing credentials")
                await logout()
            } else {
                // For other errors (network, etc), still set authenticated
                // so user can access offline data
                print("⚠️ Network or server error, but keeping token for offline access")
                isAuthenticated = true
            }
        }
    }

    // MARK: - Notifications

    @MainActor
    func requestNotificationPermissions() async -> Bool {
        await NotificationManager.shared.requestAuthorization()
    }

    // MARK: - Biometric Auth

    @MainActor
    func unlockApp() {
        isAppLocked = false
        print("🔓 App unlocked")
    }

    @MainActor
    func lockApp() {
        if BiometricAuthManager.shared.shouldRequireAuthentication() {
            isAppLocked = true
            print("🔒 App locked")
        }
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
                await logout()
            }
        }
    }
}
