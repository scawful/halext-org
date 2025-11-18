//
//  KeychainManager.swift
//  Cafe
//
//  Secure storage for authentication tokens using iOS Keychain
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private let service = "org.halext.Cafe"
    private let tokenKey = "authToken"
    private let accessCodeKey = "accessCode"

    private init() {}

    // MARK: - Token Management

    func saveToken(_ token: String) {
        save(token, forKey: tokenKey)
    }

    func getToken() -> String? {
        return retrieve(forKey: tokenKey)
    }

    func deleteToken() {
        delete(forKey: tokenKey)
    }

    // MARK: - Access Code Management

    func saveAccessCode(_ code: String) {
        save(code, forKey: accessCodeKey)
    }

    func getAccessCode() -> String? {
        return retrieve(forKey: accessCodeKey)
    }

    func deleteAccessCode() {
        delete(forKey: accessCodeKey)
    }

    // MARK: - Generic Keychain Operations

    private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item if it exists
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("❌ Keychain save error for \(key): \(status)")
        } else {
            print("✅ Saved to Keychain: \(key)")
        }
    }

    private func retrieve(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            if status != errSecItemNotFound {
                print("❌ Keychain retrieve error for \(key): \(status)")
            }
            return nil
        }

        return value
    }

    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            print("❌ Keychain delete error for \(key): \(status)")
        }
    }

    // MARK: - Clear All

    func clearAll() {
        deleteToken()
        deleteAccessCode()
        print("🗑️ Cleared all Keychain data")
    }
}
