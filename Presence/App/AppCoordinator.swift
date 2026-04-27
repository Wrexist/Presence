//  PresenceApp
//  AppCoordinator.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — adds celebration + chat modals, real Wave model.
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
        case waveReceived(Wave)
        case waveCompose(PresentUser)
        case celebration(CelebrationContext)
        case chat(roomId: UUID, otherUsername: String)
        case paywall(PaywallContext)
        case safety(SafetyContext)
        case settings
        case privacy

        var id: String {
            switch self {
            case .goPresent:                  return "goPresent"
            case .waveReceived(let w):        return "wave-\(w.id)"
            case .waveCompose(let target):    return "waveCompose-\(target.id)"
            case .celebration(let ctx):       return "celebration-\(ctx.waveId)"
            case .chat(let roomId, _):        return "chat-\(roomId.uuidString)"
            case .paywall(let ctx):           return "paywall-\(ctx.id)"
            case .safety(let ctx):            return "safety-\(ctx.id)"
            case .settings:                   return "settings"
            case .privacy:                    return "privacy"
            }
        }
    }

    /// Identifies which user the safety sheet acts on, plus the context
    /// that surfaced it (wave / chat / presence / other) for report
    /// triage.
    struct SafetyContext: Equatable, Sendable, Identifiable {
        let id: UUID
        let userId: UUID
        let username: String
        let context: ReportRequest.Context
        let referenceId: UUID?

        init(
            userId: UUID,
            username: String,
            context: ReportRequest.Context,
            referenceId: UUID? = nil
        ) {
            self.id = UUID()
            self.userId = userId
            self.username = username
            self.context = context
            self.referenceId = referenceId
        }
    }

    /// Why the paywall is being shown. The free-limit context drives
    /// extra copy ("You've hit this week's 3 free Presences"). A plain
    /// upsell context is for "Upgrade" buttons in profile/settings.
    struct PaywallContext: Equatable, Sendable, Identifiable {
        let id: UUID
        let reason: Reason

        enum Reason: Equatable, Sendable {
            case freeLimit(weeklyUsed: Int, resetsAt: Date?)
            case upsell
        }

        static let upsell = PaywallContext(id: UUID(), reason: .upsell)

        static func freeLimit(weeklyUsed: Int, resetsAt: Date?) -> PaywallContext {
            PaywallContext(id: UUID(), reason: .freeLimit(weeklyUsed: weeklyUsed, resetsAt: resetsAt))
        }
    }

    /// Snapshot passed into `CelebrationView`. Equatable so the modal
    /// case stays Equatable.
    struct CelebrationContext: Equatable, Sendable {
        let waveId: UUID
        let otherUsername: String
        let connectionCount: Int?
        let chatRoomId: UUID?
        let chatEndsAt: Date?
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

    func boot(auth: AuthService, analytics: AnalyticsService? = nil) async {
        let restored = await auth.restoreSession()
        if restored == nil {
            await analytics?.capture(.onboardingStarted)
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            if let user = restored {
                self.currentUser = user
                self.route = .main
            } else {
                self.route = .onboarding
            }
        }
    }

    func completeOnboarding(with user: User, analytics: AnalyticsService? = nil) {
        currentUser = user
        Task { await analytics?.capture(.onboardingCompleted) }
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
