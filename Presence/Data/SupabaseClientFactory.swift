//  PresenceApp
//  SupabaseClientFactory.swift
//  Created: 2026-04-26
//  Purpose: Single shared SupabaseClient configured with our Keychain-backed
//           session storage. Other services (AuthService, future repositories)
//           share this one instance.

import Auth
import Foundation
import Supabase

enum SupabaseClientFactory {
    static func make() -> SupabaseClient {
        let options = SupabaseClientOptions(
            auth: .init(storage: SupabaseSessionStorage())
        )
        return SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: options
        )
    }
}
