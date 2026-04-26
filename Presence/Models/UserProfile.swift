//  PresenceApp
//  UserProfile.swift
//  Created: 2026-04-26
//  Purpose: Wire types for /api/users/me, /api/users/me/journey, blocks,
//           and reports. Mirrors the Zod schemas in Backend/src/routes/.

import Foundation

// MARK: - GET /api/users/me

struct UserProfile: Sendable, Codable, Equatable {
    let id: UUID
    var username: String
    var bio: String?
    var avatarUrl: URL?
    let createdAt: Date
    let isPlus: Bool
    let plusExpiresAt: Date?
    let connectionCount: Int
    let weeklyPresenceCount: Int
    let weeklyResetsAt: Date
}

struct UpdateProfileRequest: Encodable, Sendable {
    let username: String?
    let bio: String?
}

// MARK: - GET /api/users/me/journey

struct Journey: Sendable, Codable, Equatable {
    let connectionCount: Int
    let wavesSentCount: Int
    let glowingSeconds: Int
    let activity: [DayBucket]

    struct DayBucket: Sendable, Codable, Equatable, Identifiable {
        let day: String   // YYYY-MM-DD
        let count: Int
        var id: String { day }
    }
}

// MARK: - Blocks

struct BlockedUser: Sendable, Codable, Identifiable, Hashable {
    let blockedId: UUID
    let username: String
    let createdAt: Date

    var id: UUID { blockedId }
}

struct BlockListResponse: Sendable, Codable {
    let blocks: [BlockedUser]
}

struct BlockRequest: Encodable, Sendable {
    let blockedId: UUID
}

// MARK: - Reports

struct ReportRequest: Encodable, Sendable {
    enum Category: String, Codable, Sendable, CaseIterable {
        case harassment
        case spam
        case inappropriate
        case unwantedAdvances = "unwanted_advances"
        case underage
        case other

        var label: String {
            switch self {
            case .harassment:       return "Harassment"
            case .spam:             return "Spam"
            case .inappropriate:    return "Inappropriate"
            case .unwantedAdvances: return "Unwanted advances"
            case .underage:         return "Looks underage"
            case .other:            return "Something else"
            }
        }
    }

    enum Context: String, Codable, Sendable {
        case wave, chat, presence, other
    }

    let reportedId: UUID
    let category: Category
    let context: Context
    let referenceId: UUID?
    let detail: String?
}
