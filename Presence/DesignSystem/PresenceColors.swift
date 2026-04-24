//  PresenceApp
//  PresenceColors.swift
//  Created: 2026-04-24
//  Purpose: Brand palette. Aurora powers presence dots, Luma glow, and CTAs.

import SwiftUI

enum PresenceColors {
    // Aurora — core brand. Dots cycle through this set, deterministic per user.
    static let auroraBlue = Color(hex: "#4FC3F7")
    static let auroraViolet = Color(hex: "#7C4DFF")
    static let auroraGreen = Color(hex: "#1DE9B6")
    static let auroraAmber = Color(hex: "#FFB84D")
    static let auroraPink = Color(hex: "#F48FB1")

    // Base
    static let presenceWhite = Color(hex: "#F8F8FF")
    static let deepNight = Color(hex: "#0A0A1A")
    static let softMidnight = Color(hex: "#141428")

    // Self-dot color — distinct from peer aurora set so user always recognizes themselves.
    static let selfGlow = presenceWhite

    // Stable peer dot palette. Pick by hashing user ID into this array.
    static let dotPalette: [Color] = [
        auroraBlue, auroraViolet, auroraGreen, auroraAmber, auroraPink
    ]

    static func dotColor(for userId: String) -> Color {
        let hash = userId.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return dotPalette[abs(hash) % dotPalette.count]
    }
}

extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: trimmed).scanHexInt64(&rgb)

        let r, g, b, a: Double
        switch trimmed.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255
            g = Double((rgb & 0x00FF00) >> 8) / 255
            b = Double(rgb & 0x0000FF) / 255
            a = 1
        case 8:
            r = Double((rgb & 0xFF000000) >> 24) / 255
            g = Double((rgb & 0x00FF0000) >> 16) / 255
            b = Double((rgb & 0x0000FF00) >> 8) / 255
            a = Double(rgb & 0x000000FF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
