//  PresenceApp
//  BackendError.swift
//  Created: 2026-04-26
//  Purpose: Typed error surface for BackendClient. Views and view-models
//           pattern-match on these instead of inspecting URLError directly.

import Foundation

enum BackendError: Error, Equatable, Sendable {
    case unauthorized
    case forbidden
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case freeLimitReached(weeklyUsed: Int, resetsAt: Date?)
    case server(status: Int, message: String?)
    case network(URLError.Code?)
    case decode
    case invalidRequest(String)

    var isRetryable: Bool {
        switch self {
        case .server(let status, _): return status >= 500
        case .network: return true
        case .rateLimited: return true
        default: return false
        }
    }
}
