//  PresenceApp
//  Wave.swift
//  Created: 2026-04-26
//  Updated: 2026-04-26 — adds hydrated `other` party + chat-room fields on
//                        respond response.
//  Purpose: Wire types for wave persistence + the icebreaker endpoint.
//           Mirrors the Zod schemas in Backend/src/routes/{waves,icebreaker}.ts.

import Foundation

// MARK: - Wave persistence (GET /api/waves response)

struct Wave: Identifiable, Hashable, Sendable, Codable {
    enum Status: String, Sendable, Codable {
        case sent
        case wavedBack = "waved_back"
        case expired
        case blocked
    }

    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let icebreaker: String
    let status: Status
    let sentAt: Date
    let expiresAt: Date

    /// Profile of the OTHER party — for incoming waves this is the sender,
    /// for outgoing it's the receiver. Backend hydrates this in a single
    /// batched lookup on GET /api/waves.
    let other: Other?

    struct Other: Hashable, Sendable, Codable {
        let id: UUID
        let username: String
        let bio: String?
    }
}

struct WaveListResponse: Sendable, Codable {
    let incoming: [Wave]
    let outgoing: [Wave]
}

// MARK: - Wave send / respond

struct SendWaveRequest: Encodable, Sendable {
    let receiverId: UUID
    let icebreaker: String
}

struct SendWaveResponse: Decodable, Sendable {
    let id: UUID
    let expiresAt: Date
    let status: Wave.Status
}

struct RespondWaveRequest: Encodable, Sendable {
    let accepted: Bool
}

struct RespondWaveResponse: Decodable, Sendable {
    let mutual: Bool
    let waveId: UUID?
    let chatRoomId: UUID?
    let chatEndsAt: Date?
}

// MARK: - Icebreaker generation

struct IcebreakerRequest: Encodable, Sendable {
    let venue: Venue
    let timeContext: TimeContext
    let userA: PartyContext
    let userB: PartyContext

    struct Venue: Encodable, Sendable {
        let name: String
        let type: String
        let vibe: String
    }

    struct TimeContext: Encodable, Sendable {
        let hour: Int
        let dayOfWeek: String
        let isWeekend: Bool
    }

    struct PartyContext: Encodable, Sendable {
        let bio: String
        let connectionCount: Int
    }
}

struct IcebreakerResponse: Decodable, Sendable {
    enum Source: String, Decodable, Sendable {
        case claude
        case fallback
    }
    let icebreaker: String
    let source: Source
}
