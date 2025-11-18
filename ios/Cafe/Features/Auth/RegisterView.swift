//
//  RegisterView.swift
//  Cafe
//
//  Registration screen for new users
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) var appState

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var accessCode = ""

    private var isValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        email.contains("@")
    }

    private var validationMessage: String? {
        if !password.isEmpty && password.count < 6 {
            return "Password must be at least 6 characters"
        }
        if !confirmPassword.isEmpty && password != confirmPassword {
            return "Passwords do not match"
        }
        if !email.isEmpty && !email.contains("@") {
            return "Please enter a valid email"
        }
        return nil
    }

    private func performRegistration() {
        let _ = Task { @MainActor in
            // Save access code if provided
            if !accessCode.isEmpty {
                KeychainManager.shared.saveAccessCode(accessCode)
            }

            await appState.register(
                username: username,
                email: email,
                password: password,
                fullName: fullName.isEmpty ? nil : fullName
            )

            // Dismiss if successful
            if appState.isAuthenticated {
                dismiss()
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    TextField("Full Name (Optional)", text: $fullName)
                } header: {
                    Text("Account Information")
                }

                Section {
                    SecureField("Password", text: $password)

                    SecureField("Confirm Password", text: $confirmPassword)

                    if let validation = validationMessage {
                        Text(validation)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } header: {
                    Text("Security")
                } footer: {
                    Text("Password must be at least 6 characters")
                        .font(.caption)
                }

                Section {
                    TextField("Access Code (Optional)", text: $accessCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Access")
                } footer: {
                    Text("An access code may be required for registration")
                        .font(.caption)
                }

                Section {
                    if let error = appState.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button(action: performRegistration) {
                        if appState.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isValid || appState.isLoading)
                }
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

#Preview {
    RegisterView()
        .environment(AppState())
}
