//  PresenceApp
//  Typography.swift
//  Created: 2026-04-24
//  Purpose: Type scale. SF Pro Rounded across the board — warm, friendly, on-brand.

import SwiftUI

enum Typography {
    // Onboarding hero, celebration moments
    static let display = Font.system(size: 40, weight: .semibold, design: .rounded)
    // Screen titles, paywall hero
    static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
    // Card titles, sheet headers
    static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
    // Primary text content
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    // Icebreaker text, secondary content
    static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
    // Bios, metadata, countdowns
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    // Smallest readable — accessibility floor
    static let footnote = Font.system(size: 11, weight: .regular, design: .rounded)
}
