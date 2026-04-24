//  PresenceApp
//  GlassTokens.swift
//  Created: 2026-04-24
//  Purpose: Source-of-truth design tokens for every Liquid Glass surface.

import SwiftUI

enum GlassTokens {
    enum Radius {
        static let card: CGFloat = 28
        static let pill: CGFloat = 999
        static let sheet: CGFloat = 34
        static let dot: CGFloat = 22
        static let icon: CGFloat = 16
    }

    enum Padding {
        static let card = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        static let pill = EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
        static let iconButton = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        static let sheet = EdgeInsets(top: 28, leading: 24, bottom: 28, trailing: 24)
    }

    enum Opacity {
        static let primary: Double = 1.0
        static let secondary: Double = 0.7
        static let hint: Double = 0.45
    }

    enum Motion {
        static let pulseDuration: Double = 1.5
        static let lumaIdleLoop: Double = 3.5
        static let glassMorph: Double = 0.4
    }
}
