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

    private func performLogin() {
        let _ = Task { @MainActor in
            await appState.login(username: username, password: password)
        }
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
