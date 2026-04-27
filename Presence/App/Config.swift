//  PresenceApp
//  Config.swift
//  Created: 2026-04-26
//  Purpose: Central read of environment-supplied configuration. Reads first
//           from process environment (set in the Xcode scheme during dev),
//           then from Info.plist (baked in at archive via xcconfig).
//
//  Why we don't fatalError on missing values:
//  An earlier draft of this file crashed at launch when SUPABASE_URL was
//  missing. That broke `xcodebuild test` in CI (no env vars) and any
//  developer running the app fresh from a clone. Network calls will fail
//  loudly the first time someone tries to use them — that's a clearer
//  signal than a crash on the splash screen, and it lets the app boot
//  far enough for tests to run.

import Foundation

enum Config {
    /// Stable placeholders so URL(string:) succeeds and ServiceContainer
    /// can construct without crashing. Any real network call will fail
    /// against these hosts — the failure surfaces at the BackendClient /
    /// SupabaseClient call site, not at launch.
    private static let placeholderURL: URL = {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "unconfigured.local"
        // The chained fallback is unreachable in practice — URLComponents
        // with a valid scheme + host always produces a URL — but it lets
        // the SwiftLint --strict force-unwrap rule stay clean.
        return components.url ?? URL(filePath: "/unconfigured")
    }()
    private static let placeholderKey = ""

    static let supabaseURL: URL = {
        if let raw = readValue(for: "SUPABASE_URL"), let url = URL(string: raw) {
            return url
        }
        return placeholderURL
    }()

    static let supabaseAnonKey: String =
        readValue(for: "SUPABASE_ANON_KEY") ?? placeholderKey

    static let backendURL: URL = {
        if let raw = readValue(for: "BACKEND_URL"), let url = URL(string: raw) {
            return url
        }
        return placeholderURL
    }()

    static let revenueCatAPIKey: String = readValue(for: "REVENUECAT_API_KEY") ?? ""
    static let posthogAPIKey: String = readValue(for: "POSTHOG_API_KEY") ?? ""
    static let posthogHost: String =
        readValue(for: "POSTHOG_HOST") ?? "https://us.i.posthog.com"
    static let sentryDSN: String = readValue(for: "SENTRY_DSN") ?? ""

    /// True only when ALL required keys are present. Use this from a
    /// future "is this build production-ready?" health check.
    static var isFullyConfigured: Bool {
        readValue(for: "SUPABASE_URL")?.isEmpty == false
            && readValue(for: "SUPABASE_ANON_KEY")?.isEmpty == false
            && readValue(for: "BACKEND_URL")?.isEmpty == false
    }

    private static func readValue(for key: String) -> String? {
        if let env = ProcessInfo.processInfo.environment[key], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: key) as? String, !plist.isEmpty {
            return plist
        }
        return nil
    }
}
