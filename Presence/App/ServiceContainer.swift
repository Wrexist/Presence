//  PresenceApp
//  ServiceContainer.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — adds SubscriptionService.
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
    let socket: SocketService
    let notifications: NotificationService
    let subscription: SubscriptionService
    let wavesViewModel: WavesViewModel

    init(
        supabase: SupabaseClient,
        auth: AuthService,
        location: LocationService,
        backend: BackendClient,
        presence: PresenceService,
        socket: SocketService,
        notifications: NotificationService,
        subscription: SubscriptionService,
        wavesViewModel: WavesViewModel
    ) {
        self.supabase = supabase
        self.auth = auth
        self.location = location
        self.backend = backend
        self.presence = presence
        self.socket = socket
        self.notifications = notifications
        self.subscription = subscription
        self.wavesViewModel = wavesViewModel
    }

    static func live() -> ServiceContainer {
        let client = SupabaseClientFactory.make()
        let auth = AuthService(client: client)
        let location = LocationService()
        let backend = BackendClient(baseURL: Config.backendURL, authProvider: auth)
        let presence = PresenceService(backend: backend, location: location)
        let socket = SocketService(baseURL: Config.backendURL, auth: auth)
        let notifications = NotificationService(backend: backend)
        let subscription = SubscriptionService(backend: backend)
        let wavesViewModel = WavesViewModel(backend: backend, socket: socket)
        return ServiceContainer(
            supabase: client,
            auth: auth,
            location: location,
            backend: backend,
            presence: presence,
            socket: socket,
            notifications: notifications,
            subscription: subscription,
            wavesViewModel: wavesViewModel
        )
    }

    static func preview() -> ServiceContainer {
        let client = SupabaseClientFactory.make()
        let auth = AuthService(client: client)
        let location = LocationService()
        let backend = BackendClient(baseURL: Config.backendURL, authProvider: auth)
        let presence = PresenceService(backend: backend, location: location)
        let socket = SocketService(baseURL: Config.backendURL, auth: auth)
        let notifications = NotificationService(backend: backend)
        let subscription = SubscriptionService(backend: backend)
        let wavesViewModel = WavesViewModel(backend: backend, socket: socket)
        return ServiceContainer(
            supabase: client,
            auth: auth,
            location: location,
            backend: backend,
            presence: presence,
            socket: socket,
            notifications: notifications,
            subscription: subscription,
            wavesViewModel: wavesViewModel
        )
    }
}
