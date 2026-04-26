//  PresenceApp
//  BackendEndpoint.swift
//  Created: 2026-04-26
//  Purpose: Typed endpoint definitions for BackendClient. New routes added
//           here so misuse fails at compile time, not at runtime.

import Foundation

struct BackendEndpoint: Sendable {
    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    let method: Method
    let path: String
    let query: [URLQueryItem]
    let requiresAuth: Bool

    init(_ method: Method, _ path: String, query: [URLQueryItem] = [], requiresAuth: Bool = true) {
        self.method = method
        self.path = path
        self.query = query
        self.requiresAuth = requiresAuth
    }

    // MARK: - Catalog

    static let health = BackendEndpoint(.get, "/health", requiresAuth: false)

    static func icebreaker() -> BackendEndpoint {
        BackendEndpoint(.post, "/api/icebreaker")
    }

    static func activatePresence() -> BackendEndpoint {
        BackendEndpoint(.post, "/api/presence")
    }

    static func nearbyPresences(lat: Double, lng: Double, radiusM: Int = 500) -> BackendEndpoint {
        BackendEndpoint(
            .get,
            "/api/presence/nearby",
            query: [
                URLQueryItem(name: "lat", value: String(lat)),
                URLQueryItem(name: "lng", value: String(lng)),
                URLQueryItem(name: "radiusM", value: String(radiusM))
            ]
        )
    }

    static func deactivatePresence(id: UUID) -> BackendEndpoint {
        BackendEndpoint(.delete, "/api/presence/\(id.uuidString)")
    }

    static func sendWave() -> BackendEndpoint {
        BackendEndpoint(.post, "/api/waves")
    }

    static func respondToWave(id: UUID) -> BackendEndpoint {
        BackendEndpoint(.post, "/api/waves/\(id.uuidString)/respond")
    }

    static func myWaves() -> BackendEndpoint {
        BackendEndpoint(.get, "/api/waves")
    }

    static func loadChat(roomId: UUID) -> BackendEndpoint {
        BackendEndpoint(.get, "/api/chat/\(roomId.uuidString)")
    }

    static func sendChatMessage(roomId: UUID) -> BackendEndpoint {
        BackendEndpoint(.post, "/api/chat/\(roomId.uuidString)/messages")
    }

    static func registerPushToken() -> BackendEndpoint {
        BackendEndpoint(.post, "/api/users/me/push-token")
    }

    static func syncSubscription() -> BackendEndpoint {
        BackendEndpoint(.post, "/api/users/me/subscription")
    }
}
