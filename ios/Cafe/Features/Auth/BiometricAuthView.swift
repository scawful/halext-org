//
//  BiometricAuthView.swift
//  Cafe
//
//  App lock screen with biometric authentication
//

import SwiftUI

struct BiometricAuthView: View {
    @State private var authManager = BiometricAuthManager.shared
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    let onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App logo/icon
                VStack(spacing: 16) {
                    Image(systemName: authManager.biometricType.icon)
                        .font(.system(size: 80))
                        .foregroundColor(.white)

                    Text("Cafe")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Unlock to continue")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Authentication button
                VStack(spacing: 16) {
                    Button {
                        _Concurrency.Task {
                            await authenticate()
                        }
                    } label: {
                        HStack {
                            Image(systemName: authManager.biometricType.icon)
                                .font(.title3)

                            Text("Unlock with \(authManager.biometricType.displayName)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                    }
                    .disabled(isAuthenticating)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .task {
            // Automatically trigger authentication when view appears
            await authenticate()
        }
    }

    private func authenticate() async {
        isAuthenticating = true
        errorMessage = nil

        let result = await authManager.authenticate()

        switch result {
        case .success:
            onAuthenticated()
        case .failure(let error):
            if case .userCancel = error {
                // Don't show error for user cancel
                errorMessage = nil
            } else {
                errorMessage = error.errorDescription
            }
        }

        isAuthenticating = false
    }
}

#Preview {
    BiometricAuthView {
        print("Authenticated!")
    }
}
