//  PresenceApp
//  PresenceService.swift
//  Created: 2026-04-26
//  Purpose: Owns the active-presence lifecycle. activate() POSTs the
//           privacy-reduced location, schedules a 3h auto-deactivate, and
//           starts a 60s loop refreshing nearby presences. deactivate()
//           cancels timers and DELETEs the row.

import CoreLocation
import Foundation
import SwiftUI

@MainActor
@Observable
final class PresenceService {
    // MARK: - Public state

    private(set) var isActive: Bool = false
    private(set) var presenceID: UUID?
    private(set) var expiresAt: Date?
    private(set) var nearby: [PresentUser] = []
    private(set) var lastError: BackendError?

    // MARK: - Dependencies

    private let backend: BackendClient
    private let location: LocationService

    private var expiryTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?

    /// Refresh cadence for the nearby query while presence is active.
    /// 60s matches the LocationService update tempo and the privacy budget;
    /// over-polling here doesn't surface anything new because dot positions
    /// are jittered ±50m anyway.
    private let refreshIntervalNS: UInt64 = 60_000_000_000

    init(backend: BackendClient, location: LocationService) {
        self.backend = backend
        self.location = location
    }

    // MARK: - Activate

    func activate(venueName: String? = nil, venueType: String? = nil) async throws {
        guard !isActive else { return }

        guard let coord = location.privacyReducedLocation() else {
            throw BackendError.invalidRequest("location_unavailable")
        }

        let body = ActivateRequest(
            location: ActivateRequest.Location(lat: coord.latitude, lng: coord.longitude),
            venueName: venueName,
            venueType: venueType
        )

        do {
            let response: ActivateResponse = try await backend.send(
                .activatePresence(),
                body: body
            )
            self.presenceID = response.id
            self.expiresAt = response.expiresAt
            self.isActive = true
            self.lastError = nil
            scheduleExpiry(at: response.expiresAt)
            startNearbyRefresh()
            // Kick off an immediate first refresh so the map populates without
            // waiting a full minute.
            await refreshNearby(coord: coord)
        } catch let error as BackendError {
            self.lastError = error
            throw error
        }
    }

    // MARK: - Deactivate

    func deactivate() async {
        let id = presenceID
        cancelTimers()
        isActive = false
        expiresAt = nil
        presenceID = nil
        nearby = []
        guard let id else { return }
        do {
            _ = try await backend.sendVoid(.deactivatePresence(id: id))
        } catch let error as BackendError {
            // Already-deactivated server-side is fine — we just clear locally.
            // Anything else is logged onto lastError; the UI can surface it.
            if error != .notFound {
                lastError = error
            }
        } catch {
            lastError = .network(nil)
        }
    }

    // MARK: - Nearby

    func refreshNearby() async {
        guard isActive, let coord = location.privacyReducedLocation() else { return }
        await refreshNearby(coord: coord)
    }

    private func refreshNearby(coord: CLLocationCoordinate2D) async {
        do {
            let endpoint = BackendEndpoint.nearbyPresences(lat: coord.latitude, lng: coord.longitude)
            let response: NearbyResponse = try await backend.get(endpoint)
            self.nearby = response.presences
        } catch let error as BackendError {
            lastError = error
        } catch {
            lastError = .network(nil)
        }
    }

    // MARK: - Scheduling

    private func scheduleExpiry(at fireDate: Date) {
        expiryTask?.cancel()
        expiryTask = Task { [weak self] in
            let nanos = max(0, fireDate.timeIntervalSinceNow) * 1_000_000_000
            try? await Task.sleep(nanoseconds: UInt64(nanos))
            if Task.isCancelled { return }
            await self?.deactivate()
        }
    }

    private func startNearbyRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self, refreshIntervalNS] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: refreshIntervalNS)
                if Task.isCancelled { break }
                await self?.refreshNearby()
            }
        }
    }

    private func cancelTimers() {
        expiryTask?.cancel()
        expiryTask = nil
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Wire types

    private struct ActivateRequest: Encodable, Sendable {
        let location: Location
        let venueName: String?
        let venueType: String?

        struct Location: Encodable, Sendable {
            let lat: Double
            let lng: Double
        }
    }

    private struct ActivateResponse: Decodable, Sendable {
        let id: UUID
        let expiresAt: Date
    }

    private struct NearbyResponse: Decodable, Sendable {
        let presences: [PresentUser]
    }
}
