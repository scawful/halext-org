//
//  UserProfileView.swift
//  Cafe
//
//  User profile management and connection interface
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var socialManager = SocialManager.shared
    @State private var currentUser: User?

    @State private var displayName: String = ""
    @State private var statusMessage: String = ""
    @State private var currentActivity: String = ""

    @State private var showingInviteCode = false
    @State private var showingConnectSheet = false
    @State private var generatedInviteCode: InviteCode?
    @State private var connectCode: String = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRetry = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    if let profile = socialManager.currentProfile {
                        HStack(spacing: 16) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 80, height: 80)

                                Text(profile.username.prefix(2).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.displayName ?? profile.username)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("@\(profile.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(profile.isOnline ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)

                                    Text(profile.isOnline ? "Online" : "Offline")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        Button(action: createProfile) {
                            Label("Create Social Profile", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                } header: {
                    Text("Profile")
                }

                // Status Section
                if socialManager.currentProfile != nil {
                    Section {
                        TextField("Display Name", text: $displayName)

                        TextField("Status Message", text: $statusMessage)
                            .textInputAutocapitalization(.sentences)

                        TextField("Current Activity", text: $currentActivity)
                            .textInputAutocapitalization(.sentences)

                        Button(action: updateProfileInfo) {
                            Label("Update Profile", systemImage: "checkmark.circle.fill")
                        }
                        .disabled(isLoading)
                    } header: {
                        Text("Status & Info")
                    }
                }

                // Connections Section
                Section {
                    if socialManager.connections.isEmpty {
                        Text("No connections yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(socialManager.connections) { connection in
                            ConnectionRowView(connection: connection)
                        }
                    }

                    Button(action: { showingInviteCode = true }) {
                        Label("Generate Invite Code", systemImage: "qrcode")
                    }
                    .disabled(socialManager.currentProfile == nil)

                    Button(action: { showingConnectSheet = true }) {
                        Label("Connect with Code", systemImage: "link")
                    }
                    .disabled(socialManager.currentProfile == nil)
                } header: {
                    Text("Connections")
                }

                // CloudKit Status
                Section {
                    HStack {
                        Text("iCloud Status")
                        Spacer()
                        Image(systemName: socialManager.isCloudKitAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(socialManager.isCloudKitAvailable ? .green : .red)
                        Text(socialManager.isCloudKitAvailable ? "Available" : "Unavailable")
                            .foregroundColor(.secondary)
                    }

                    if let error = socialManager.syncError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Sync Status")
                }
            }
            .navigationTitle("Social Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingInviteCode) {
                InviteCodeSheet(inviteCode: generatedInviteCode)
            }
            .sheet(isPresented: $showingConnectSheet) {
                ConnectWithCodeSheet(connectCode: $connectCode, onConnect: connectWithCode)
            }
            .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
                Button("OK") {
                    errorMessage = nil
                    showRetry = false
                }
                if showRetry {
                    Button("Retry") {
                        errorMessage = nil
                        showRetry = false
                        _Concurrency.Task {
                            await loadUserProfile()
                        }
                    }
                }
            } message: { message in
                Text(message)
            }
            .task {
                await loadUserProfile()
                try? await socialManager.fetchConnections()
            }
        }
    }

    // MARK: - Actions

    private func loadUserProfile() async {
        do {
            currentUser = try await APIClient.shared.getCurrentUser()

            if socialManager.currentProfile == nil {
                // Check if profile exists in CloudKit
                if let profile = try await socialManager.fetchProfile(byUserId: currentUser?.id ?? 0) {
                    socialManager.currentProfile = profile
                }
            }

            if let profile = socialManager.currentProfile {
                displayName = profile.displayName ?? ""
                statusMessage = profile.statusMessage ?? ""
                currentActivity = profile.currentActivity ?? ""
            }
            
            await MainActor.run {
                errorMessage = nil
                showRetry = false
            }
        } catch {
            await MainActor.run {
                // Provide user-friendly error messages and determine if retry should be shown
                let friendlyMessage: String
                var shouldShowRetry = false
                
                if let apiError = error as? APIError {
                    friendlyMessage = apiError.errorDescription ?? "Failed to load user profile. Please try again."
                    // Show retry for transient errors
                    shouldShowRetry = apiError != .unauthorized && apiError != .notAuthenticated
                } else if let urlError = error as? URLError {
                    friendlyMessage = "Network error: \(urlError.localizedDescription). Please check your connection and try again."
                    shouldShowRetry = true
                } else {
                    friendlyMessage = "Failed to load user profile: \(error.localizedDescription)"
                    shouldShowRetry = true
                }
                
                errorMessage = friendlyMessage
                showRetry = shouldShowRetry
            }
        }
    }

    private func createProfile() {
        guard let user = currentUser else {
            errorMessage = "No user found. Please log in first."
            return
        }

        isLoading = true

        _Concurrency.Task {
            do {
                let profile = try await socialManager.createProfile(
                    username: user.username,
                    displayName: user.fullName,
                    userId: user.id
                )

                displayName = profile.displayName ?? ""

                // Update presence
                try await socialManager.updatePresence(isOnline: true)

                isLoading = false
            } catch {
                errorMessage = "Failed to create profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func updateProfileInfo() {
        guard var profile = socialManager.currentProfile else {
            return
        }

        isLoading = true

        profile = SocialProfile(
            id: profile.id,
            userId: profile.userId,
            username: profile.username,
            displayName: displayName.isEmpty ? nil : displayName,
            avatarURL: profile.avatarURL,
            statusMessage: statusMessage.isEmpty ? nil : statusMessage,
            currentActivity: currentActivity.isEmpty ? nil : currentActivity,
            isOnline: profile.isOnline,
            lastSeen: profile.lastSeen,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )

        _Concurrency.Task {
            do {
                try await socialManager.updateProfile(profile)

                // Update presence
                try await socialManager.updatePresence(
                    isOnline: true,
                    currentActivity: currentActivity.isEmpty ? nil : currentActivity,
                    statusMessage: statusMessage.isEmpty ? nil : statusMessage
                )

                isLoading = false
            } catch {
                errorMessage = "Failed to update profile: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func generateInviteCode() {
        isLoading = true

        _Concurrency.Task {
            do {
                let code = try await socialManager.generateInviteCode()
                generatedInviteCode = code
                showingInviteCode = true
                isLoading = false
            } catch {
                errorMessage = "Failed to generate invite code: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func connectWithCode() {
        guard !connectCode.isEmpty else {
            return
        }

        isLoading = true

        _Concurrency.Task {
            do {
                _ = try await socialManager.connectWithInviteCode(connectCode)
                showingConnectSheet = false
                connectCode = ""
                isLoading = false

                // Refresh connections
                try? await socialManager.fetchConnections()
            } catch {
                errorMessage = "Failed to connect: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// MARK: - Connection Row

struct ConnectionRowView: View {
    let connection: Connection
    @State private var socialManager = SocialManager.shared

    var partner: SocialProfile? {
        let partnerId = connection.partnerProfileId
        return socialManager.partnerProfiles[partnerId]
    }

    var body: some View {
        HStack(spacing: 12) {
            // Partner Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)

                if let partner = partner {
                    Text(partner.username.prefix(2).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(partner?.displayName ?? partner?.username ?? "Unknown")
                    .font(.headline)

                HStack(spacing: 4) {
                    Circle()
                        .fill(partner?.isOnline == true ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)

                    if let activity = partner?.currentActivity {
                        Text(activity)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(partner?.isOnline == true ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if connection.status == .accepted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Invite Code Sheet

struct InviteCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let inviteCode: InviteCode?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let code = inviteCode {
                    Spacer()

                    // QR Code
                    if let qrImage = generateQRCode(from: code.code) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(radius: 8)
                    }

                    // Code Display
                    VStack(spacing: 8) {
                        Text("Invite Code")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(code.code)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .tracking(8)
                            .foregroundColor(.primary)
                    }

                    // Expiry Info
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)

                        Text("Expires \(code.expiresAt.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Share Button
                    ShareLink(item: code.code) {
                        Label("Share Code", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)

                    Spacer()
                } else {
                    ProgressView("Generating Code...")
                }
            }
            .navigationTitle("Your Invite Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return nil
    }
}

// MARK: - Connect with Code Sheet

struct ConnectWithCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var connectCode: String
    let onConnect: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "link.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Connect with Partner")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter the 6-digit invite code your partner shared with you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Code Input
                TextField("000000", text: $connectCode)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: connectCode) { _, newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            connectCode = String(newValue.prefix(6))
                        }
                    }

                Button(action: {
                    onConnect()
                }) {
                    Text("Connect")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(connectCode.count != 6)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
