//  PresenceApp
//  AppCoordinator.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — added .launching state for async session restore.
//  Purpose: Root navigation state. Owns the top-level route, the current
//           tab, any presented modal, and the persisted current user.
//           Views read/write via @Environment.

import SwiftUI

@MainActor
@Observable
final class AppCoordinator {
    enum Route: Equatable {
        case launching
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

    var route: Route = .launching
    var tab: AppTab = .map
    var modal: Modal?
    var currentUser: User?

    /// Called once on launch with the live AuthService. Resolves a session
    /// from Keychain if one exists and routes accordingly. Falls back to
    /// the onboarding flow on any failure.
    func boot(auth: AuthService) async {
        let restored = await auth.restoreSession()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            if let user = restored {
                self.currentUser = user
                self.route = .main
            } else {
                self.route = .onboarding
            }
        }
    }

    func completeOnboarding(with user: User) {
        currentUser = user
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            route = .main
        }
    }

    func resetToOnboarding() {
        currentUser = nil
        route = .onboarding
    }

    func present(_ modal: Modal) { self.modal = modal }
    func dismissModal() { self.modal = nil }
}
