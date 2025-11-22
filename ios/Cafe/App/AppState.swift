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

    // AI Models Cache
    var aiModels: AIModelsResponse?
    var isLoadingModels: Bool = false
    var aiProviderInfo: AIProviderInfo?
    var isLoadingProviderInfo: Bool = false

    init() {
        // Setup notification categories
        NotificationManager.shared.setupNotificationCategories()

        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()
        print("🌍 Network monitoring started")

        // Listen for token expiration notifications
        NotificationCenter.default.addObserver(
            forName: .tokenExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                await self?.handleTokenExpiration()
            }
        }

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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
            print("Local cache cleared on logout")
        } catch {
            print("Failed to clear cache: \(error.localizedDescription)")
        }

        authToken = nil
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }

    /// Delete the user's account permanently
    /// This performs a two-phase cleanup:
    /// 1. Calls the backend API to delete the account
    /// 2. Clears all local data (Keychain, SwiftData, UserDefaults, Spotlight)
    @MainActor
    func deleteAccount() async throws {
        isLoading = true
        errorMessage = nil

        do {
            print("Starting account deletion process...")

            // Phase 1: Call backend API to delete account
            try await APIClient.shared.deleteAccount()
            print("Account deleted from server")

            // Phase 2: Clear all local data
            await performFullLocalDataCleanup()

            // Reset app state
            authToken = nil
            currentUser = nil
            isAuthenticated = false
            isLoading = false

            print("Account deletion completed successfully")
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("Account deletion failed: \(error.localizedDescription)")
            throw error
        }
    }

    /// Performs comprehensive cleanup of all local data
    /// Called during account deletion and can be reused for data reset scenarios
    @MainActor
    private func performFullLocalDataCleanup() async {
        // Clear Keychain (tokens, access codes)
        KeychainManager.shared.clearAll()
        print("Keychain data cleared")

        // Clear notifications
        NotificationManager.shared.removeAllPendingNotifications()
        NotificationManager.shared.clearBadge()
        print("Notifications cleared")

        // Clear SwiftData local storage
        do {
            try await SyncManager.shared.clearCache()
            print("SwiftData cache cleared")
        } catch {
            print("Failed to clear SwiftData cache: \(error.localizedDescription)")
        }

        // Clear Spotlight index
        SpotlightManager.shared.clearAll()
        print("Spotlight index cleared")

        // Clear UserDefaults for this app
        clearUserDefaults()
        print("UserDefaults cleared")

        // Clear AI state
        aiModels = nil
        aiProviderInfo = nil
        print("AI state cleared")
    }

    /// Clears app-specific UserDefaults entries
    private func clearUserDefaults() {
        let defaults = UserDefaults.standard

        // Known app-specific keys
        let keysToRemove = [
            "currentUsername",
            "currentUserId",
            "useProductionAPI",
            "lastSyncDate",
            "preferredAIModel",
            "dashboardLayout",
            "themePreference",
            "accentColor",
            "fontSizePreference",
            "quietHoursEnabled",
            "quietHoursStart",
            "quietHoursEnd",
            "analyticsEnabled",
            "crashReportingEnabled",
            "iCloudSyncEnabled",
            "offlineMode",
            "labsEnabled",
            "enabledLabsFeatures",
            "recentlyChangedSettings",
            "preferredContactUsername"
        ]

        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }

        // Also clear any keys with our app's prefix if using one
        if let bundleId = Bundle.main.bundleIdentifier {
            let allKeys = defaults.dictionaryRepresentation().keys
            for key in allKeys where key.hasPrefix(bundleId) {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.synchronize()
    }
    
    @MainActor
    private func handleTokenExpiration() async {
        print("🚨 Token expired notification received")
        errorMessage = "Your session has expired. Please sign in again."
        await logout()
    }

    @MainActor
    private func validateStoredToken() async {
        print("🔍 Validating stored token...")

        do {
            // Try to load current user with stored token
            currentUser = try await APIClient.shared.getCurrentUser()
            print("✅ Token valid - user: \(currentUser?.username ?? "unknown")")
            if let user = currentUser {
                KeychainManager.shared.saveUserId(user.id)
                UserDefaults.standard.set(user.username, forKey: "currentUsername")
            }

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
            if let user = currentUser {
                KeychainManager.shared.saveUserId(user.id)
                UserDefaults.standard.set(user.username, forKey: "currentUsername")
            }

            // Load AI models after user is loaded
            await loadAIModels()
            await loadAIProviderInfo()
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

    // MARK: - AI Models

    @MainActor
    func loadAIModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }

        do {
            print("🤖 Loading AI models...")
            aiModels = try await APIClient.shared.fetchAiModels()
            print("✅ AI models loaded: \(aiModels?.models.count ?? 0) models")
        } catch {
            print("❌ Failed to load AI models:", error)
            // Don't throw error, just log - models are optional feature
        }
    }

    @MainActor
    func refreshAIModels() async {
        await loadAIModels()
    }

    @MainActor
    func loadAIProviderInfo() async {
        isLoadingProviderInfo = true
        defer { isLoadingProviderInfo = false }

        do {
            print("🛡️ Loading AI provider info...")
            aiProviderInfo = try await APIClient.shared.getAIInfo()
        } catch {
            print("❌ Failed to load AI provider info:", error)
        }
    }
}
