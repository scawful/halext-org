//
//  BiometricAuthManager.swift
//  Cafe
//
//  Face ID and Touch ID authentication
//

import Foundation
import LocalAuthentication
import SwiftUI

@MainActor
@Observable
class BiometricAuthManager {
    static let shared = BiometricAuthManager()

    var isAvailable = false
    var biometricType: BiometricType = .none
    var isEnabled = false

    enum BiometricType {
        case none
        case faceID
        case touchID
        case opticID // For Vision Pro

        var displayName: String {
            switch self {
            case .none: return "None"
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            }
        }

        var icon: String {
            switch self {
            case .none: return "lock.slash"
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .opticID: return "opticid"
            }
        }
    }

    private let context = LAContext()
    private let enabledKey = "biometric_auth_enabled"

    init() {
        checkBiometricAvailability()
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }

    // MARK: - Availability Check

    func checkBiometricAvailability() {
        var error: NSError?
        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if isAvailable {
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .opticID
            case .none:
                biometricType = .none
                isAvailable = false
            @unknown default:
                biometricType = .none
                isAvailable = false
            }

            print("✅ Biometric auth available: \(biometricType.displayName)")
        } else {
            biometricType = .none
            print("❌ Biometric auth not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    // MARK: - Authentication

    func authenticate(reason: String = "Authenticate to access Cafe") async -> Result<Bool, BiometricAuthError> {
        guard isAvailable else {
            return .failure(.notAvailable)
        }

        guard isEnabled else {
            return .failure(.notEnabled)
        }

        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        context.localizedFallbackTitle = "Enter Password"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            if success {
                print("✅ Biometric authentication successful")
                return .success(true)
            } else {
                print("❌ Biometric authentication failed")
                return .failure(.authenticationFailed)
            }
        } catch let error as LAError {
            print("❌ Biometric error: \(error.localizedDescription)")
            return .failure(BiometricAuthError.from(error))
        } catch {
            print("❌ Unknown biometric error: \(error)")
            return .failure(.unknown(error))
        }
    }

    // MARK: - Settings

    func enableBiometricAuth() {
        guard isAvailable else {
            print("⚠️ Cannot enable - biometric auth not available")
            return
        }

        isEnabled = true
        UserDefaults.standard.set(true, forKey: enabledKey)
        print("✅ Biometric auth enabled")
    }

    func disableBiometricAuth() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: enabledKey)
        print("🔓 Biometric auth disabled")
    }

    // MARK: - App Lock

    func shouldRequireAuthentication() -> Bool {
        isEnabled && isAvailable
    }
}

// MARK: - Errors

enum BiometricAuthError: LocalizedError {
    case notAvailable
    case notEnabled
    case authenticationFailed
    case userCancel
    case userFallback
    case biometryNotEnrolled
    case biometryLockout
    case passcodeNotSet
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnabled:
            return "Biometric authentication is not enabled"
        case .authenticationFailed:
            return "Authentication failed. Please try again"
        case .userCancel:
            return "Authentication cancelled by user"
        case .userFallback:
            return "User selected fallback authentication"
        case .biometryNotEnrolled:
            return "Biometric authentication is not set up. Please add Face ID or Touch ID in Settings"
        case .biometryLockout:
            return "Biometric authentication is locked. Please use your passcode"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .unknown(let error):
            return error.localizedDescription
        }
    }

    static func from(_ error: LAError) -> BiometricAuthError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .passcodeNotSet:
            return .passcodeNotSet
        default:
            return .unknown(error)
        }
    }
}
