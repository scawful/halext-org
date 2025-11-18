//
//  LoginView.swift
//  Cafe
//
//  Login screen for authentication
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) var appState

    @State private var username = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var useProduction = UserDefaults.standard.bool(forKey: "useProductionAPI")

    private func performLogin() {
        _Concurrency.Task {
            await appState.login(username: username, password: password)
        }
    }

    private func handleEnvironmentChange(_ newValue: Bool) {
        // Clear any existing auth state first
        appState.logout()

        // Then update the environment setting
        useProduction = newValue
        UserDefaults.standard.set(newValue, forKey: "useProductionAPI")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Logo and branding
                VStack(spacing: 16) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.brown, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Cafe")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Your productivity companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)

                // Login form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if let error = appState.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if appState.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .controlSize(.large)
                    } else {
                        Button(action: performLogin) {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(username.isEmpty || password.isEmpty)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Environment toggle (DEBUG only)
                #if DEBUG
                VStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { useProduction },
                        set: handleEnvironmentChange
                    )) {
                        HStack {
                            Image(systemName: useProduction ? "cloud.fill" : "laptopcomputer")
                                .foregroundColor(useProduction ? .green : .blue)
                            Text(useProduction ? "Production API" : "Local Dev API")
                                .font(.caption)
                        }
                    }
                    .tint(.green)
                    .padding(.horizontal, 32)

                    if !useProduction {
                        Text("http://127.0.0.1:8000")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("https://org.halext.org/api")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Clear Keychain button
                    Button(action: {
                        KeychainManager.shared.clearAll()
                        appState.logout()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.caption)
                            Text("Clear Keychain")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                    }
                }
                .padding(.bottom, 16)
                #endif

                // Register link
                Button(action: {
                    showingRegister = true
                }) {
                    Text("Don't have an account? **Register**")
                        .font(.subheadline)
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
