//  PresenceApp
//  AnalyticsService.swift
//  Created: 2026-04-26
//  Purpose: Typed-event analytics on top of PostHog. Privacy-first per
//           CLAUDE.md § Privacy: NO phone, NO exact location, NO message
//           bodies, NO bios. Only event metadata. Identify happens once
//           with the Supabase user id post-auth.
//
//  Concurrency: actor so multiple call sites can fire-and-forget without
//  worrying about thread affinity. PostHog SDK calls are thread-safe but
//  funneling through one actor keeps the surface tidy.

import Foundation
@preconcurrency import PostHog

actor AnalyticsService {
    /// Typed event catalog. The `name` is the wire string PostHog sees;
    /// the cases enforce that views can only fire known events. Add
    /// new events here, never inline strings at call sites.
    enum Event: Sendable {
        case onboardingStarted
        case onboardingCompleted
        case presenceActivated(durationMinutes: Int)
        case presenceDeactivated(reason: DeactivateReason)
        case dotTapped
        case waveSent(icebreakerSource: String)
        case waveReceived
        case waveAccepted
        case waveDeclined
        case chatOpened
        case chatMessageSent
        case connectionMade(connectionCount: Int?)
        case paywallShown(reason: PaywallReason)
        case paywallPurchased(plan: String)
        case paywallRestored
        case appBackgrounded
        case errorSurfaced(code: String)

        enum DeactivateReason: String, Sendable {
            case manual, expired, signOut
        }

        enum PaywallReason: String, Sendable {
            case freeLimit, upsell
        }

        fileprivate var name: String {
            switch self {
            case .onboardingStarted:    return "onboarding_started"
            case .onboardingCompleted:  return "onboarding_completed"
            case .presenceActivated:    return "presence_activated"
            case .presenceDeactivated:  return "presence_deactivated"
            case .dotTapped:            return "dot_tapped"
            case .waveSent:             return "wave_sent"
            case .waveReceived:         return "wave_received"
            case .waveAccepted:         return "wave_accepted"
            case .waveDeclined:         return "wave_declined"
            case .chatOpened:           return "chat_opened"
            case .chatMessageSent:      return "chat_message_sent"
            case .connectionMade:       return "connection_made"
            case .paywallShown:         return "paywall_shown"
            case .paywallPurchased:     return "paywall_purchased"
            case .paywallRestored:      return "paywall_restored"
            case .appBackgrounded:      return "app_backgrounded"
            case .errorSurfaced:        return "error_surfaced"
            }
        }

        fileprivate var properties: [String: Any] {
            switch self {
            case .presenceActivated(let mins):
                return ["duration_minutes": mins]
            case .presenceDeactivated(let reason):
                return ["reason": reason.rawValue]
            case .waveSent(let source):
                return ["icebreaker_source": source]
            case .connectionMade(let count):
                return count.map { ["connection_count": $0] } ?? [:]
            case .paywallShown(let reason):
                return ["reason": reason.rawValue]
            case .paywallPurchased(let plan):
                return ["plan": plan]
            case .errorSurfaced(let code):
                return ["code": code]
            default:
                return [:]
            }
        }
    }

    private var hasConfigured = false

    /// Idempotent. No-op when the API key is empty (dev / preview).
    func configureIfNeeded() {
        guard !hasConfigured else { return }
        let key = Config.posthogAPIKey
        guard !key.isEmpty else { return }
        let configuration = PostHogConfig(apiKey: key, host: Config.posthogHost)
        // PostHog defaults to capturing $screen and $autocapture — we
        // disable autocapture so events are 100% explicit and the privacy
        // story is deterministic.
        configuration.captureApplicationLifecycleEvents = true
        configuration.captureScreenViews = false
        PostHogSDK.shared.setup(configuration)
        hasConfigured = true
    }

    func identify(userId: UUID) {
        guard hasConfigured else { return }
        // We deliberately don't pass any user properties — PostHog accepts
        // a properties map here, but every property is a privacy decision.
        // Add only after a deliberate choice.
        PostHogSDK.shared.identify(userId.uuidString)
    }

    func reset() {
        guard hasConfigured else { return }
        PostHogSDK.shared.reset()
    }

    func capture(_ event: Event) {
        guard hasConfigured else { return }
        let props = event.properties
        if props.isEmpty {
            PostHogSDK.shared.capture(event.name)
        } else {
            PostHogSDK.shared.capture(event.name, properties: props)
        }
    }
}
