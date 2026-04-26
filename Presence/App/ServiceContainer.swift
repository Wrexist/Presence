//  PresenceApp
//  ServiceContainer.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — adds PresenceService wired to BackendClient + LocationService.
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
    let presence: PresenceService

    // MatchingService, SocketService arrive in later slices.

    init(
        supabase: SupabaseClient,
        auth: AuthService,
        location: LocationService,
        backend: BackendClient,
        presence: PresenceService
    ) {
        self.supabase = supabase
        self.auth = auth
        self.location = location
        self.backend = backend
        self.presence = presence
    }

    static func live() -> ServiceContainer {
        let client = SupabaseClientFactory.make()
        let auth = AuthService(client: client)
        let location = LocationService()
        let backend = BackendClient(baseURL: Config.backendURL, authProvider: auth)
        let presence = PresenceService(backend: backend, location: location)
        return ServiceContainer(
            supabase: client,
            auth: auth,
            location: location,
            backend: backend,
            presence: presence
        )
    }

    /// Preview-safe container — same wiring, but no network requests will
    /// fire from previews unless explicitly invoked.
    static func preview() -> ServiceContainer {
        let client = SupabaseClientFactory.make()
        let auth = AuthService(client: client)
        let location = LocationService()
        let backend = BackendClient(baseURL: Config.backendURL, authProvider: auth)
        let presence = PresenceService(backend: backend, location: location)
        return ServiceContainer(
            supabase: client,
            auth: auth,
            location: location,
            backend: backend,
            presence: presence
        )
    }
}
