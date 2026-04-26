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
    case waveReceived(WaveReceivedPayload)
    case waveMutual(WaveMutualPayload)
    case chatMessage(ChatMessage)

    struct JoinedPayload: Sendable, Equatable, Codable {
        let id: UUID
        let userId: UUID
        let lat: Double
        let lng: Double
        let venueName: String?
        let expiresAt: Date

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

    struct WaveReceivedPayload: Sendable, Equatable, Codable {
        let id: UUID
        let senderId: UUID
        let senderUsername: String
        let senderBio: String?
        let icebreaker: String
        let sentAt: Date
        let expiresAt: Date
    }

    struct WaveMutualPayload: Sendable, Equatable, Codable {
        let waveId: UUID
        let senderId: UUID
        let receiverId: UUID
        let respondedAt: Date
        let chatRoomId: UUID?
        let chatStartedAt: Date?
        let chatEndsAt: Date?
        let connectionCount: Int?
    }
}
