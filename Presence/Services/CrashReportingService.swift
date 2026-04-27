//  PresenceApp
//  CrashReportingService.swift
//  Created: 2026-04-26
//  Purpose: Wraps Sentry-cocoa init + the breadcrumbs we want from
//           BackendError catches. Privacy-first: screenshots and view
//           hierarchy attachment are explicitly disabled — both can leak
//           bios, icebreakers, and chat bodies into bug reports.
//
//  When the DSN is empty (most dev / preview), the service no-ops. This
//  matches the AnalyticsService pattern so a missing key is a soft
//  degrade, not a crash.

import Foundation
@preconcurrency import Sentry

@MainActor
@Observable
final class CrashReportingService {
    private(set) var isConfigured: Bool = false

    /// Idempotent. Safe to call from PresenceApp's first .task.
    func configureIfNeeded() {
        guard !isConfigured else { return }
        let dsn = Config.sentryDSN
        guard !dsn.isEmpty else { return }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = Self.environmentForBuild()
            options.releaseName = Self.releaseName

            // Explicitly off — both can leak bios / chat / icebreakers
            // into the bug report sidebar.
            options.attachScreenshot = false
            options.attachViewHierarchy = false

            // Send fewer breadcrumbs than the default (no UI, no network
            // body) so PII can't sneak in via auto-capture.
            options.enableUserInteractionTracing = false
            options.enableAutoBreadcrumbTracking = true
            options.enableUIViewControllerTracing = false
            options.enableNetworkBreadcrumbs = false

            // Strip the user's IP and any auto-attached PII.
            options.sendDefaultPii = false

            options.tracesSampleRate = 0.1
            options.profilesSampleRate = 0
        }

        isConfigured = true
    }

    /// Identify the current user. Only the Supabase id — no phone, no
    /// username, no bio. The `Sentry.` qualifier disambiguates Sentry's
    /// User class from our own Models/User.swift type.
    func identify(userId: UUID) {
        guard isConfigured else { return }
        let user = Sentry.User()
        user.userId = userId.uuidString
        SentrySDK.setUser(user)
    }

    func clearUser() {
        guard isConfigured else { return }
        SentrySDK.setUser(nil)
    }

    /// Add a breadcrumb for a typed BackendError. Used from view-models
    /// at every catch site so we have context when crashes land.
    func breadcrumb(error: BackendError, location: String) {
        guard isConfigured else { return }
        let crumb = Sentry.Breadcrumb()
        crumb.category = "backend"
        crumb.level = .warning
        crumb.message = "\(location): \(label(for: error))"
        crumb.data = ["error": label(for: error)]
        SentrySDK.addBreadcrumb(crumb)
    }

    /// Manually capture an unexpected error. Use sparingly — most network
    /// errors are expected and don't need a Sentry event.
    func capture(_ error: Error, location: String) {
        guard isConfigured else { return }
        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: location, key: "location")
        }
    }

    // MARK: - Helpers

    private func label(for error: BackendError) -> String {
        switch error {
        case .unauthorized:                  return "unauthorized"
        case .forbidden:                     return "forbidden"
        case .notFound:                      return "not_found"
        case .rateLimited:                   return "rate_limited"
        case .freeLimitReached:              return "free_limit"
        case .server(let status, _):         return "server_\(status)"
        case .network(let code):
            if let code { return "network_\(code.rawValue)" }
            return "network"
        case .decode:                        return "decode"
        case .invalidRequest:                return "invalid_request"
        }
    }

    private static func environmentForBuild() -> String {
        #if DEBUG
        return "debug"
        #else
        return "release"
        #endif
    }

    private static var releaseName: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "presence@\(version)+\(build)"
    }
}
