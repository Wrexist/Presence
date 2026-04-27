//  PresenceApp
//  AppDelegate.swift
//  Created: 2026-04-26
//  Purpose: Bridges UIKit lifecycle hooks SwiftUI doesn't expose — the
//           remote-notification device-token callback and the
//           notification-tap callback. Both forward into the
//           ServiceContainer / AppCoordinator via late-bound references
//           that PresenceApp wires up at launch.

import UIKit
import UserNotifications

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Set by PresenceApp at launch so callbacks can reach our state.
    var notifications: NotificationService?
    var coordinator: AppCoordinator?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Remote notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        guard let notifications else { return }
        Task { await notifications.registerDeviceToken(deviceToken) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Common in the simulator; non-fatal. The next launch on a real
        // device retries the registration through requestAuthorization().
        _ = error
    }

    // MARK: - Notification taps + foreground presentation

    /// Foreground-banner default: still show the banner for incoming waves
    /// even if the app is open, so the user sees them while on a different tab.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let type = userInfo["type"] as? String
        let waveIdString = userInfo["waveId"] as? String
        let waveId = waveIdString.flatMap(UUID.init(uuidString:))

        // Dispatch the deep-link work to the main actor without dragging
        // `completionHandler` across the boundary — Swift 6 strict refuses
        // to send a non-Sendable closure into an isolated Task. Apple just
        // needs us to call completionHandler before the system reclaims
        // the call; right after scheduling the Task is fine.
        Task { @MainActor [weak self] in
            self?.handleNotificationTap(type: type, waveId: waveId)
        }
        completionHandler()
    }

    private func handleNotificationTap(type: String?, waveId: UUID?) {
        guard let coordinator else { return }
        switch type {
        case "wave_received":
            if let waveId {
                coordinator.deepLink = .waveReceived(id: waveId)
            }
        case "wave_mutual":
            if let waveId {
                coordinator.deepLink = .waveMutual(id: waveId)
            }
        default:
            break
        }
    }
}
