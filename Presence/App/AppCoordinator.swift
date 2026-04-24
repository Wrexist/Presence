//  PresenceApp
//  AppCoordinator.swift
//  Created: 2026-04-24
//  Purpose: Root navigation state. Owns the top-level route, the current
//           tab, any presented modal, and the persisted current user.
//           Views read/write via @Environment.

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

    private static let onboardingCompleteKey = "presence.onboarding.complete.v1"

    var route: Route
    var tab: AppTab = .map
    var modal: Modal?
    var currentUser: User?

    init() {
        let done = UserDefaults.standard.bool(forKey: Self.onboardingCompleteKey)
        self.route = done ? .main : .onboarding
    }

    func completeOnboarding(with user: User) {
        currentUser = user
        UserDefaults.standard.set(true, forKey: Self.onboardingCompleteKey)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            route = .main
        }
    }

    func resetToOnboarding() {
        UserDefaults.standard.removeObject(forKey: Self.onboardingCompleteKey)
        currentUser = nil
        route = .onboarding
    }

    func present(_ modal: Modal) { self.modal = modal }
    func dismissModal() { self.modal = nil }
}
