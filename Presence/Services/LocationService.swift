//  PresenceApp
//  LocationService.swift
//  Created: 2026-04-24
//  Purpose: CoreLocation wrapper. @MainActor @Observable so SwiftUI views
//           can observe auth + currentLocation directly. whenInUse only —
//           CLAUDE.md forbids `always` authorization. The privacy-reduced
//           helper jitters the coordinate by ~50m before it ever leaves
//           the device, per the privacy model.

import CoreLocation
import Foundation

@MainActor
@Observable
final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var currentLocation: CLLocation?
    private(set) var isUpdating: Bool = false

    private let manager: CLLocationManager
    // Queue of continuations awaiting the system's authorization callback.
    // Using a list (not a single slot) so concurrent callers — e.g. a user
    // rapidly tapping Go Present before the system dialog returns — all get
    // resumed together instead of silently dropping the earlier await and
    // leaking the continuation.
    private var authorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []

    override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        // Per LEARNINGS.md: hundred-meter accuracy is plenty for presence
        // (we reduce precision further before sending) and is a big win
        // for battery.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 30 // meters
    }

    // MARK: - Authorization

    /// Requests whenInUse authorization if not yet decided, and resolves with
    /// the resulting status. If already decided, returns immediately. Safe
    /// under concurrent callers — all pending awaits resume together when
    /// the system delivers the authorization callback.
    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        let current = manager.authorizationStatus
        if current != .notDetermined {
            return current
        }
        return await withCheckedContinuation { continuation in
            let shouldKickOff = authorizationContinuations.isEmpty
            authorizationContinuations.append(continuation)
            // Only the first caller actually triggers the system prompt;
            // subsequent awaits just ride along on the same delegate callback.
            if shouldKickOff {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse
            || authorizationStatus == .authorizedAlways
    }

    // MARK: - Updates

    func startUpdating() {
        guard !isUpdating, isAuthorized else { return }
        isUpdating = true
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        guard isUpdating else { return }
        isUpdating = false
        manager.stopUpdatingLocation()
    }

    // MARK: - Privacy reduction

    /// Returns currentLocation with ~±50m random jitter applied. Per the
    /// privacy model, this is what we send to the backend — the server
    /// never sees the exact coordinate. Returns nil when no fix is available.
    func privacyReducedLocation() -> CLLocationCoordinate2D? {
        guard let loc = currentLocation else { return nil }
        // ~0.0005° latitude ≈ 55m; longitude jitter shrinks by cos(lat)
        // so the effective radius stays roughly constant across latitudes.
        let latOffset = Double.random(in: -0.00045...0.00045)
        let lonScale = max(0.2, cos(loc.coordinate.latitude * .pi / 180))
        let lonOffset = Double.random(in: -0.00045...0.00045) / lonScale
        return CLLocationCoordinate2D(
            latitude: loc.coordinate.latitude + latOffset,
            longitude: loc.coordinate.longitude + lonOffset
        )
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status
        // Resume every waiting caller with the resolved status and clear the
        // queue. Even a non-.notDetermined status is worth delivering — e.g.
        // iOS may re-fire this callback when the user returns from Settings.
        guard status != .notDetermined, !authorizationContinuations.isEmpty else { return }
        let pending = authorizationContinuations
        authorizationContinuations.removeAll()
        for continuation in pending {
            continuation.resume(returning: status)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        // Reject stale / wildly-inaccurate fixes. Android dumps indoor GPS
        // noise at 500m+ accuracy all the time — iOS is better but not
        // perfect, and the dot-on-map UX deserves a tight feed.
        guard last.horizontalAccuracy > 0, last.horizontalAccuracy < 200 else { return }
        guard abs(last.timestamp.timeIntervalSinceNow) < 15 else { return }
        currentLocation = last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location failures are common and transient (airplane mode, tunnel,
        // indoor dead zones). We swallow the error; the UI still reflects
        // the last-known fix and the MapKit control surfaces availability.
        // Hook PostHog here once analytics land.
        _ = error
    }
}
