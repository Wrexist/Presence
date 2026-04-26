//  PresenceApp
//  ServiceContainer.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — owns the shared SupabaseClient + AuthService.
//  Purpose: Lightweight DI container. Holds service singletons that views
//           read via @Environment. Use .live() in app, .preview() in #Previews.

import SwiftUI
import Supabase

@MainActor
@Observable
final class ServiceContainer {
    let supabase: SupabaseClient
    let auth: AuthService
    let location: LocationService
    let backend: BackendClient

    // PresenceService, MatchingService, SocketService arrive in later slices.

    init(
        supabase: SupabaseClient,
        auth: AuthService,
        location: LocationService,
        backend: BackendClient
    ) {
        self.supabase = supabase
        self.auth = auth
        self.location = location
        self.backend = backend
    }

    static func live() -> ServiceContainer {
        let client = SupabaseClientFactory.make()
        let auth = AuthService(client: client)
        return ServiceContainer(
            supabase: client,
            auth: auth,
            location: LocationService(),
            backend: BackendClient(baseURL: Config.backendURL, authProvider: auth)
        )
    }

    /// Preview-safe container — same wiring, but keychain writes are namespaced
    /// and no network requests will fire from previews unless explicitly invoked.
    static func preview() -> ServiceContainer {
        let client = SupabaseClientFactory.make()
        let auth = AuthService(client: client)
        return ServiceContainer(
            supabase: client,
            auth: auth,
            location: LocationService(),
            backend: BackendClient(baseURL: Config.backendURL, authProvider: auth)
        )
    }
}
