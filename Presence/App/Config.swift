//  PresenceApp
//  Config.swift
//  Created: 2026-04-26
//  Purpose: Central read of environment-supplied configuration. Reads first
//           from process environment (set in the Xcode scheme during dev),
//           then from Info.plist (baked in at archive via xcconfig). Crashes
//           loudly on missing required values — better at launch than at
//           the first auth call.

import Foundation

enum Config {
    static let supabaseURL: URL = {
        guard let url = URL(string: required("SUPABASE_URL")) else {
            fatalError("SUPABASE_URL is not a valid URL")
        }
        return url
    }()

    static let supabaseAnonKey: String = required("SUPABASE_ANON_KEY")

    static let backendURL: URL = {
        guard let url = URL(string: required("BACKEND_URL")) else {
            fatalError("BACKEND_URL is not a valid URL")
        }
        return url
    }()

    static let revenueCatAPIKey: String = optional("REVENUECAT_API_KEY") ?? ""
    static let posthogAPIKey: String = optional("POSTHOG_API_KEY") ?? ""
    static let posthogHost: String = optional("POSTHOG_HOST") ?? "https://us.i.posthog.com"
    static let sentryDSN: String = optional("SENTRY_DSN") ?? ""

    private static func required(_ key: String) -> String {
        if let v = readValue(for: key), !v.isEmpty { return v }
        fatalError("Missing required configuration value: \(key). Set it via the Xcode scheme env vars (dev) or xcconfig → Info.plist (release).")
    }

    private static func optional(_ key: String) -> String? {
        readValue(for: key).flatMap { $0.isEmpty ? nil : $0 }
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
