//
//  UserManagementView.swift
//  Cafe
//
//  User administration and management interface
//

import SwiftUI

struct UserManagementView: View {
    @State private var users: [AdminUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var showingUserDetail: AdminUser?

    var filteredUsers: [AdminUser] {
        if searchText.isEmpty {
            return users
        }
        return users.filter {
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            ($0.fullName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        List {
            if isLoading && users.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            } else {
                statisticsSection
                usersSection
            }
        }
        .navigationTitle("User Management")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search users")
        .refreshable {
            await loadUsers()
        }
        .task {
            await loadUsers()
        }
        .sheet(item: $showingUserDetail) { user in
            NavigationStack {
                UserDetailView(user: user) {
                    await loadUsers()
                }
            }
        }
    }

    private var statisticsSection: some View {
        Section("Overview") {
            HStack {
                Label("Total Users", systemImage: "person.3.fill")
                Spacer()
                Text("\(users.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            HStack {
                Label("Admin Users", systemImage: "shield.fill")
                Spacer()
                Text("\(users.filter { $0.isAdmin }.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }

            HStack {
                Label("Active Users", systemImage: "checkmark.circle.fill")
                Spacer()
                Text("\(users.filter { $0.isActive }.count)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
    }

    private var usersSection: some View {
        Section("Users") {
            if filteredUsers.isEmpty {
                Text("No users found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(filteredUsers) { user in
                    Button(action: { showingUserDetail = user }) {
                        UserRow(user: user)
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    @MainActor
    private func loadUsers() async {
        isLoading = true
        errorMessage = nil

        do {
            users = try await APIClient.shared.getAllUsers()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load users: \(error)")
        }

        isLoading = false
    }
}

// MARK: - User Row

struct UserRow: View {
    let user: AdminUser

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(user.username)
                    .font(.headline)

                if user.isAdmin {
                    Image(systemName: "shield.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                if !user.isActive {
                    Image(systemName: "pause.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let fullName = user.fullName {
                Text(fullName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Joined \(user.createdAt, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if let lastLogin = user.lastLoginAt {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Last login \(lastLogin, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Detail View

struct UserDetailView: View {
    let user: AdminUser
    let onUpdate: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var showingRoleChangeConfirmation = false

    var body: some View {
        List {
            Section("User Information") {
                LabeledContent("Username", value: user.username)
                LabeledContent("Email", value: user.email)

                if let fullName = user.fullName {
                    LabeledContent("Full Name", value: fullName)
                }

                LabeledContent("User ID", value: "\(user.id)")
            }

            Section("Status") {
                HStack {
                    Label("Admin Privileges", systemImage: "shield.fill")
                        .foregroundColor(.orange)
                    Spacer()
                    Text(user.isAdmin ? "Yes" : "No")
                        .foregroundColor(user.isAdmin ? .orange : .secondary)
                }

                HStack {
                    Label("Account Status", systemImage: user.isActive ? "checkmark.circle.fill" : "pause.circle.fill")
                        .foregroundColor(user.isActive ? .green : .gray)
                    Spacer()
                    Text(user.isActive ? "Active" : "Inactive")
                        .foregroundColor(user.isActive ? .green : .gray)
                }
            }

            Section("Activity") {
                LabeledContent("Joined", value: user.createdAt, format: .dateTime)

                if let lastLogin = user.lastLoginAt {
                    LabeledContent("Last Login", value: lastLogin, format: .dateTime)
                } else {
                    HStack {
                        Text("Last Login")
                        Spacer()
                        Text("Never")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Actions") {
                Button(action: { showingRoleChangeConfirmation = true }) {
                    Label(user.isAdmin ? "Remove Admin Access" : "Grant Admin Access", systemImage: "shield")
                }
                .disabled(isUpdating)

                Button(action: { _Concurrency.Task { await toggleActiveStatus() } }) {
                    Label(user.isActive ? "Deactivate Account" : "Activate Account", systemImage: user.isActive ? "pause.circle" : "play.circle")
                }
                .disabled(isUpdating)

                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Delete User", systemImage: "trash")
                }
                .disabled(isUpdating)
            }

            if let error = errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("User Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isUpdating {
                    ProgressView()
                } else {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("Change Admin Role", isPresented: $showingRoleChangeConfirmation) {
            Button(user.isAdmin ? "Remove Admin Access" : "Grant Admin Access", role: user.isAdmin ? .destructive : nil) {
                _Concurrency.Task {
                    await toggleAdminRole()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(user.isAdmin
                ? "This will remove admin privileges from \(user.username)"
                : "This will grant admin privileges to \(user.username)")
        }
        .confirmationDialog("Delete User", isPresented: $showingDeleteConfirmation) {
            Button("Delete User", role: .destructive) {
                _Concurrency.Task {
                    await deleteUser()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(user.username)? This action cannot be undone.")
        }
    }

    // MARK: - Actions

    @MainActor
    private func toggleAdminRole() async {
        isUpdating = true
        errorMessage = nil

        do {
            _ = try await APIClient.shared.updateUserRole(userId: user.id, isAdmin: !user.isAdmin)
            await onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to update user role: \(error)")
        }

        isUpdating = false
    }

    @MainActor
    private func toggleActiveStatus() async {
        isUpdating = true
        errorMessage = nil

        do {
            _ = try await APIClient.shared.updateUserStatus(userId: user.id, isActive: !user.isActive)
            await onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to update user status: \(error)")
        }

        isUpdating = false
    }

    @MainActor
    private func deleteUser() async {
        isUpdating = true
        errorMessage = nil

        do {
            try await APIClient.shared.deleteUser(userId: user.id)
            await onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to delete user: \(error)")
        }

        isUpdating = false
    }
}

#Preview {
    NavigationStack {
        UserManagementView()
    }
}
