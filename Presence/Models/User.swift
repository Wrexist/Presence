//  PresenceApp
//  User.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — added snake_case CodingKeys for PostgREST decoding.
//  Purpose: Plain Sendable value type mirroring the users table in
//           Backend/supabase/migrations/0001_initial_schema.sql.

import Foundation

struct User: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var username: String
    var bio: String?
    var avatarURL: URL?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case bio
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }

    static let placeholder = User(
        id: UUID(),
        username: "morningfern",
        bio: "loves coffee mornings",
        avatarURL: nil,
        createdAt: Date()
    )
}
