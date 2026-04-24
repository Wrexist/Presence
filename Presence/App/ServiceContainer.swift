//  PresenceApp
//  ServiceContainer.swift
//  Created: 2026-04-24
//  Purpose: Lightweight DI container. Holds service singletons that views
//           read via @Environment. Use .live() in app, .preview() in #Previews.

import SwiftUI

@MainActor
@Observable
final class ServiceContainer {
    let location: LocationService

    // PresenceService, MatchingService, SocketService arrive in later slices.

    init(location: LocationService) {
        self.location = location
    }

    static func live() -> ServiceContainer {
        ServiceContainer(location: LocationService())
    }

    static func preview() -> ServiceContainer {
        ServiceContainer(location: LocationService())
    }
}
