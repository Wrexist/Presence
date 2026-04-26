//  PresenceApp
//  AppCoordinator.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — adds deep-link state + waveCompose modal.
//  Purpose: Root navigation state. Owns the top-level route, the current
//           tab, any presented modal, deep-link payloads coming from push
//           notifications, and the persisted current user. Views read/write
//           via @Environment.

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
        case waveCompose(PresentUser)

        var id: String {
            switch self {
            case .goPresent:                  return "goPresent"
            case .wave(let w):                return "wave-\(w.id)"
            case .waveCompose(let target):    return "waveCompose-\(target.id)"
            }
        }
    }

    /// Pending action handed off from a push-notification tap. Views consume
    /// it via .onChange(of: coordinator.deepLink) and then clear it.
    enum DeepLink: Equatable {
        case waveReceived(id: UUID)
        case waveMutual(id: UUID)
    }

    var route: Route = .launching
    var tab: AppTab = .map
    var modal: Modal?
    var deepLink: DeepLink?
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

    func consumeDeepLink() { self.deepLink = nil }
}
