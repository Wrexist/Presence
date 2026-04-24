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
        XCTAssert(app.staticTexts["Presence"].waitForExistence(timeout: 5))
    }
}
