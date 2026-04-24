//  PresenceApp
//  LumaState.swift
//  Created: 2026-04-24
//  Purpose: The mascot's emotional states. Each state maps to a body color,
//           a glow color, an expression, and an animation tempo.

import SwiftUI

enum LumaState: String, CaseIterable, Sendable {
    case idle          // Soft floating, pearl glow.        Default at rest.
    case excited       // Faster float, golden glow.        Someone nearby is Present.
    case waving        // Tilted body, cyan glow.           Wave sent / received.
    case connecting    // Slow spin, violet glow.           Icebreaker loading.
    case celebrating   // Bright burst, spectrum glow.      Mutual wave / connection.
    case sleepy        // Dim blue, slow breathing.         Nobody nearby.
    case gentle        // Closed eyes, pulsing pearl.       Quiet moment.

    var bodyColor: Color {
        switch self {
        case .idle:        return PresenceColors.Luma.lavender
        case .excited:     return PresenceColors.Luma.peach
        case .waving:      return PresenceColors.Luma.blush
        case .connecting:  return PresenceColors.Luma.lavender
        case .celebrating: return PresenceColors.Luma.peach
        case .sleepy:      return PresenceColors.Luma.lavender.opacity(0.7)
        case .gentle:      return PresenceColors.Luma.pearl
        }
    }

    var glowColor: Color {
        switch self {
        case .idle:        return PresenceColors.Luma.pearl
        case .excited:     return PresenceColors.auroraAmber
        case .waving:      return PresenceColors.auroraBlue
        case .connecting:  return PresenceColors.auroraViolet
        case .celebrating: return PresenceColors.auroraPink
        case .sleepy:      return PresenceColors.auroraBlue.opacity(0.4)
        case .gentle:      return PresenceColors.Luma.pearl
        }
    }

    var floatDuration: Double {
        switch self {
        case .idle, .gentle:       return 3.5
        case .sleepy:              return 5.0
        case .excited, .waving:    return 1.8
        case .connecting:          return 2.5
        case .celebrating:         return 1.2
        }
    }

    var eyesClosed: Bool {
        self == .sleepy || self == .gentle
    }
}
