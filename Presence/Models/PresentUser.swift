//  PresenceApp
//  PresentUser.swift
//  Created: 2026-04-26
//  Purpose: Represents one nearby presence as returned by GET /api/presence/nearby.
//           Maps 1:1 to the row shape from the nearby_presences RPC, with
//           coordinates already privacy-reduced server-side.

import Foundation

struct PresentUser: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    let userId: UUID
    let username: String
    let bio: String?
    let lat: Double
    let lng: Double
    let venueName: String?
    let expiresAt: Date

    var coordinate: (lat: Double, lng: Double) { (lat, lng) }
}
