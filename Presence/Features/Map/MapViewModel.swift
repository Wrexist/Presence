//  PresenceApp
//  MapViewModel.swift
//  Created: 2026-04-26
//  Purpose: Owns the live set of nearby presences for HomeView. Initial
//           hydrate via REST GET /api/presence/nearby, then merges
//           presence_joined / presence_left events from SocketService.
//           Caps `visible` at 50 — the map's render budget per CLAUDE.md
//           § Known Pitfalls.

import CoreLocation
import Foundation
import SwiftUI

@MainActor
@Observable
final class MapViewModel {
    // MARK: - Public state

    /// All known presences, keyed by id. Internal source of truth.
    private(set) var presences: [UUID: PresentUser] = [:]
    private(set) var lastError: BackendError?
    private(set) var isHydrated: Bool = false

    /// Visible dots after the 50-cap. Sorted by distance from the user's
    /// current location when available, else insertion order.
    var visible: [PresentUser] {
        let all = Array(presences.values)
        guard let center = location.currentLocation?.coordinate else {
            return Array(all.prefix(Self.visibleCap))
        }
        return all
            .sorted { lhs, rhs in
                Self.squaredDistance(from: center, to: lhs) <
                    Self.squaredDistance(from: center, to: rhs)
            }
            .prefix(Self.visibleCap)
            .map { $0 }
    }

    /// How many additional presences exist beyond the visible cap. Drives
    /// the "+N more nearby" affordance in the header.
    var overflowCount: Int {
        max(0, presences.count - Self.visibleCap)
    }

    static let visibleCap = 50

    // MARK: - Dependencies

    private let backend: BackendClient
    private let socket: SocketService
    private let location: LocationService

    private var streamTask: Task<Void, Never>?
    private var hydrateTask: Task<Void, Never>?

    init(backend: BackendClient, socket: SocketService, location: LocationService) {
        self.backend = backend
        self.socket = socket
        self.location = location
    }

    // MARK: - Lifecycle

    func start() async {
        if streamTask == nil {
            streamTask = Task { [weak self] in
                await self?.consumeStream()
            }
        }
        await hydrate()

        if let coord = location.currentLocation?.coordinate {
            socket.subscribe(lat: coord.latitude, lng: coord.longitude)
        }
    }

    /// The socket itself is owned by the app shell — MapViewModel only
    /// stops its own stream consumer + hydrate task.
    func stop() {
        streamTask?.cancel()
        streamTask = nil
        hydrateTask?.cancel()
        hydrateTask = nil
    }

    // MARK: - Hydrate

    func hydrate() async {
        guard let coord = location.currentLocation?.coordinate else {
            // No fix yet — the .task waiting on this will retry when
            // LocationService publishes the first reading.
            return
        }
        do {
            let response: NearbyResponse = try await backend.get(
                .nearbyPresences(lat: coord.latitude, lng: coord.longitude)
            )
            // Replace wholesale on hydrate so a stale-row keeps for at most
            // one refresh cycle. Realtime events will overlay on top.
            var fresh: [UUID: PresentUser] = [:]
            for p in response.presences { fresh[p.id] = p }
            self.presences = fresh
            self.isHydrated = true
            self.lastError = nil
        } catch let error as BackendError {
            self.lastError = error
        } catch {
            self.lastError = .network(nil)
        }
    }

    // MARK: - Stream

    private func consumeStream() async {
        for await event in socket.events() {
            if Task.isCancelled { break }
            apply(event)
        }
    }

    private func apply(_ event: PresenceEvent) {
        switch event {
        case .joined(let payload):
            if let existing = presences[payload.id] {
                presences[payload.id] = PresentUser(
                    id: existing.id,
                    userId: existing.userId,
                    username: existing.username,
                    bio: existing.bio,
                    lat: payload.lat,
                    lng: payload.lng,
                    venueName: payload.venueName ?? existing.venueName,
                    expiresAt: payload.expiresAt
                )
            } else {
                presences[payload.id] = payload.toPresentUser()
            }

        case .left(let id):
            presences.removeValue(forKey: id)

        case .waveReceived, .waveMutual, .chatMessage:
            // Wave + chat events are handled by WavesViewModel / ChatViewModel.
            break
        }
    }

    // MARK: - Helpers

    private static func squaredDistance(
        from center: CLLocationCoordinate2D,
        to user: PresentUser
    ) -> Double {
        let dLat = user.lat - center.latitude
        let dLng = user.lng - center.longitude
        // Equirectangular approximation — fine for sub-50km comparisons,
        // and we only need the ordering, not the metric distance.
        return dLat * dLat + dLng * dLng
    }

    private struct NearbyResponse: Decodable, Sendable {
        let presences: [PresentUser]
    }
}
