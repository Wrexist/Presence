//  PresenceApp
//  DesignSystemTests.swift
//  Created: 2026-04-24
//  Purpose: Sanity tests for design tokens — catch accidental refactors.

import Testing
import SwiftUI
@testable import Presence

@Suite("Design system")
struct DesignSystemTests {
    @Test("Aurora dot palette is non-empty and stable size")
    func dotPaletteSize() {
        #expect(PresenceColors.dotPalette.count == 5)
    }

    @Test("dotColor is deterministic for the same user id")
    func dotColorIsDeterministic() {
        let first = PresenceColors.dotColor(for: "user-abc-123")
        let second = PresenceColors.dotColor(for: "user-abc-123")
        #expect(first == second)
    }

    @Test("Glass token radii are non-negative")
    func radiiAreSane() {
        #expect(GlassTokens.Radius.card > 0)
        #expect(GlassTokens.Radius.pill > 0)
        #expect(GlassTokens.Radius.sheet > 0)
    }
}
