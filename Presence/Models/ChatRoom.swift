//  PresenceApp
//  ChatRoom.swift
//  Created: 2026-04-26
//  Purpose: Wire types for the 10-minute chat room created on a mutual wave.
//           The endsAt field is the server-enforced close time — the iOS
//           UI countdown is derived from it but never authoritative.

import Foundation

struct ChatRoom: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let waveId: UUID
    let userA: UUID
    let userB: UUID
    let startedAt: Date
    let endsAt: Date

    func otherParticipant(from caller: UUID) -> UUID {
        caller == userA ? userB : userA
    }

    var remaining: TimeInterval {
        max(0, endsAt.timeIntervalSinceNow)
    }
}

struct ChatMessage: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let roomId: UUID
    let senderId: UUID
    let body: String
    let createdAt: Date
}

struct ChatLoadResponse: Sendable, Codable {
    let room: ChatRoom
    let messages: [ChatMessage]
}

struct PostChatMessageRequest: Encodable, Sendable {
    let body: String
}
