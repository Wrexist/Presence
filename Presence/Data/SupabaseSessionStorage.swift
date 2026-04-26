//  PresenceApp
//  SupabaseSessionStorage.swift
//  Created: 2026-04-26
//  Purpose: Bridges supabase-swift's AuthLocalStorage protocol onto our
//           KeychainStore. Default supabase-swift storage is UserDefaults,
//           which is the wrong place for an OAuth-style refresh token.

import Auth
import Foundation

struct SupabaseSessionStorage: AuthLocalStorage {
    let keychain: KeychainStore

    init(keychain: KeychainStore = KeychainStore()) {
        self.keychain = keychain
    }

    func store(key: String, value: Data) throws {
        try keychain.set(value, for: key)
    }

    func retrieve(key: String) throws -> Data? {
        try keychain.get(key)
    }

    func remove(key: String) throws {
        try keychain.remove(key)
    }
}
