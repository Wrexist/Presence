//  PresenceApp
//  User.swift
//  Created: 2026-04-24
//  Purpose: Plain Sendable value type mirroring the users table in
//           Backend/supabase/migrations/0001_initial_schema.sql.

import Foundation

struct User: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var username: String
    var bio: String?
    var avatarURL: URL?
    let createdAt: Date

    static let placeholder = User(
        id: UUID(),
        username: "morningfern",
        bio: "loves coffee mornings",
        avatarURL: nil,
        createdAt: Date()
    )
}
