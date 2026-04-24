//  PresenceApp
//  AppCoordinator.swift
//  Created: 2026-04-24
//  Purpose: Root navigation state. Owns the top-level route, the current
//           tab, and any presented modal. Views read/write via @Environment.

import SwiftUI

@MainActor
@Observable
final class AppCoordinator {
    enum Route: Equatable {
        case onboarding
        case main
    }

    enum Modal: Equatable, Identifiable {
        case goPresent
        case wave(IncomingWave)

        var id: String {
            switch self {
            case .goPresent:     return "goPresent"
            case .wave(let w):   return "wave-\(w.id)"
            }
        }
    }

    var route: Route = .main     // Onboarding-skip until AuthService lands.
    var tab: AppTab = .map
    var modal: Modal?

    func completeOnboarding() { route = .main }
    func resetToOnboarding()  { route = .onboarding }

    func present(_ modal: Modal) { self.modal = modal }
    func dismissModal()          { self.modal = nil }
}
