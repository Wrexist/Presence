//  PresenceApp
//  KeychainStore.swift
//  Created: 2026-04-26
//  Purpose: Tiny generic-password Keychain wrapper used by the Supabase
//           session storage adapter. Sendable + thread-safe; the Security
//           framework calls already serialize internally.

import Foundation
import Security

struct KeychainStore: Sendable {
    enum KeychainError: Error, Equatable {
        case unexpectedStatus(OSStatus)
    }

    /// Service prefix written to every item — uniquely scopes Presence's
    /// keychain entries within the app's keychain partition.
    let service: String

    init(service: String = "app.presence.ios") {
        self.service = service
    }

    func set(_ data: Data, for key: String) throws {
        let query: [String: Any] = baseQuery(for: key)
        let attrs: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func get(_ key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func remove(_ key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
