//  PresenceApp
//  PresenceEvent.swift
//  Created: 2026-04-26
//  Purpose: Realtime event payloads pushed to the iOS client via Socket.io.
//           Mirrors the broadcast shapes emitted from
//           Backend/src/routes/presence.ts.

import Foundation

enum PresenceEvent: Sendable, Equatable {
    case joined(JoinedPayload)
    case left(id: UUID)

    struct JoinedPayload: Sendable, Equatable, Codable {
        let id: UUID
        let userId: UUID
        let lat: Double
        let lng: Double
        let venueName: String?
        let expiresAt: Date

        /// Maps a `presence_joined` payload onto the same `PresentUser` shape
        /// the REST `/nearby` endpoint returns. Username/bio aren't carried
        /// on the realtime event — we fill in placeholders that the UI can
        /// replace via a follow-up REST hydrate when needed.
        func toPresentUser(username: String = "", bio: String? = nil) -> PresentUser {
            PresentUser(
                id: id,
                userId: userId,
                username: username,
                bio: bio,
                lat: lat,
                lng: lng,
                venueName: venueName,
                expiresAt: expiresAt
            )
        }
    }

    struct LeftPayload: Sendable, Equatable, Codable {
        let id: UUID
    }
}
