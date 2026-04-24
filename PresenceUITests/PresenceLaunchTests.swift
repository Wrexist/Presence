//  PresenceApp
//  PresenceLaunchTests.swift
//  Created: 2026-04-24
//  Purpose: Smoke test — app launches without crashing.

import XCTest

final class PresenceLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // Default route is .main → MainTabShell, so the "Nearby" tab button
        // from GlassTabBar is always visible on a successful launch.
        XCTAssert(app.buttons["Nearby"].waitForExistence(timeout: 5))
    }
}
