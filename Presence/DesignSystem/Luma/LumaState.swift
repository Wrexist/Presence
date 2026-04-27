//  PresenceApp
//  LumaState.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — adds Lottie animation-name + speed mappings.
//  Purpose: The mascot's emotional states. Each state maps to a body color,
//           a glow color, an expression, an animation tempo, and a Lottie
//           animation file name (consumed by LumaView when assets are
//           bundled; otherwise the pure-SwiftUI fallback is used).

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

    /// Lottie animation file name (without extension). LumaView looks this
    /// up in the main bundle via `LottieAnimation.named(_:)`. If the file
    /// isn't bundled, the pure-SwiftUI fallback renders instead — see
    /// `Presence/Resources/Luma/README.md` for the full asset spec.
    var animationName: String {
        switch self {
        case .idle:        return "luma_idle"
        case .excited:     return "luma_excited"
        case .waving:      return "luma_waving"
        case .connecting:  return "luma_connecting"
        case .celebrating: return "luma_celebrating"
        case .sleepy:      return "luma_sleepy"
        case .gentle:      return "luma_gentle"
        }
    }

    /// Lottie playback speed multiplier. Mirrors the floatDuration tempo so
    /// the visual cadence stays consistent whether we render Lottie or the
    /// pure-SwiftUI fallback.
    var lottieSpeed: CGFloat {
        switch self {
        case .idle, .gentle:       return 1.0
        case .sleepy:              return 0.7
        case .excited, .waving:    return 1.4
        case .connecting:          return 1.1
        case .celebrating:         return 1.6
        }
    }
}
