//  PresenceApp
//  AppCoordinator.swift
//  Created: 2026-04-24
//  Purpose: Root navigation state. Owns the top-level route and any modal stack.

import SwiftUI

@MainActor
@Observable
final class AppCoordinator {
    enum Route: Equatable {
        case onboarding
        case map
    }

    var route: Route = .onboarding

    func completeOnboarding() {
        route = .map
    }

    func resetToOnboarding() {
        route = .onboarding
    }
}
