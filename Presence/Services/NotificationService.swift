//  PresenceApp
//  NotificationService.swift
//  Created: 2026-04-26
//  Purpose: Owns push permission + device-token registration. Permission
//           is requested LAZILY — first time the user sends or receives
//           a wave — not during onboarding. That mirrors the location
//           permission pattern from CLAUDE.md § Privacy and the LEARNINGS
//           note about explanation-before-ask grant rates.

import Foundation
import UIKit
import UserNotifications

@MainActor
@Observable
final class NotificationService {
    enum AuthState: Sendable, Equatable {
        case notDetermined
        case authorized
        case denied
        case provisional

        init(_ status: UNAuthorizationStatus) {
            switch status {
            case .authorized:    self = .authorized
            case .provisional:   self = .provisional
            case .ephemeral:     self = .authorized
            case .denied:        self = .denied
            case .notDetermined: self = .notDetermined
            @unknown default:    self = .notDetermined
            }
        }
    }

    private(set) var auth: AuthState = .notDetermined
    private(set) var deviceToken: String?
    private(set) var lastError: BackendError?

    private let backend: BackendClient

    init(backend: BackendClient) {
        self.backend = backend
    }

    // MARK: - Authorization

    /// Reads the current system status without prompting. Call on app
    /// launch + foreground so the UI reflects user changes in Settings.
    /// Re-triggers remote-notification registration when the user is
    /// already authorized — this lets us pick up rotated APNs tokens.
    func refreshAuth() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let newAuth = AuthState(settings.authorizationStatus)
        auth = newAuth
        if newAuth == .authorized || newAuth == .provisional {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Triggers the system prompt the first time it's called. Returns true
    /// if the user granted (or had previously granted) permission. Calling
    /// this when already denied just resolves false — no second prompt.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuth()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Device token

    /// Called from AppDelegate.didRegisterForRemoteNotifications.
    func registerDeviceToken(_ data: Data) async {
        let token = data.map { String(format: "%02x", $0) }.joined()
        guard token != deviceToken else { return }
        deviceToken = token

        struct Body: Encodable, Sendable {
            let token: String
            let platform: String
            let environment: String
        }
        let body = Body(
            token: token,
            platform: "ios",
            environment: Self.environmentForBuild()
        )

        do {
            try await backend.sendVoid(.registerPushToken(), body: body)
            lastError = nil
        } catch let error as BackendError {
            lastError = error
        } catch {
            lastError = .network(nil)
        }
    }

    private static func environmentForBuild() -> String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }
}
