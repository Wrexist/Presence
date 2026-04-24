//  PresenceApp
//  ServiceContainer.swift
//  Created: 2026-04-24
//  Purpose: Lightweight DI container. Holds singletons for services that views and
//           view models read via @Environment. Use .live() in app, .preview() in #Previews.

import SwiftUI

@MainActor
@Observable
final class ServiceContainer {
    // Services are added here as they're built. Sprint 0 keeps this empty —
    // LocationService, PresenceService, MatchingService, SocketService, etc.
    // arrive in Sprint 1 and 2.

    static func live() -> ServiceContainer {
        ServiceContainer()
    }

    static func preview() -> ServiceContainer {
        ServiceContainer()
    }
}
