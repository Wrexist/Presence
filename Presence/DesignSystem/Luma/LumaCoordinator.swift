//  PresenceApp
//  LumaCoordinator.swift
//  Created: 2026-04-26
//  Purpose: Central "mood" state machine for the ambient Luma. Watches
//           PresenceService + WavesViewModel and computes a current
//           LumaState from app conditions. Wave-flow specific states
//           (.waving / .connecting / .celebrating) are still driven
//           inline by their owning views — those are short, view-bound
//           moments. LumaCoordinator handles the long-running ambient
//           mood: idle / excited / sleepy.

import Foundation
import SwiftUI

@MainActor
@Observable
final class LumaCoordinator {
    /// State truth table:
    ///   ┌──────────────────────┬────────────────────┬─────────────┐
    ///   │ Glowing?             │ Nearby > 0?        │ State       │
    ///   ├──────────────────────┼────────────────────┼─────────────┤
    ///   │ no                   │ —                  │ .idle       │
    ///   │ yes                  │ yes                │ .excited    │
    ///   │ yes (just activated) │ no                 │ .idle       │
    ///   │ yes ≥ 5 min          │ no                 │ .sleepy     │
    ///   │ has unanswered waves │ —                  │ .excited    │
    ///   └──────────────────────┴────────────────────┴─────────────┘
    private(set) var ambient: LumaState = .idle

    private let presence: PresenceService
    private let waves: WavesViewModel
    private let map: MapViewModel?

    /// Threshold past which a glowing-but-alone user transitions to .sleepy.
    private let aloneThreshold: TimeInterval = 5 * 60

    private var aloneSince: Date?
    private var refreshTask: Task<Void, Never>?

    init(presence: PresenceService, waves: WavesViewModel, map: MapViewModel? = nil) {
        self.presence = presence
        self.waves = waves
        self.map = map
    }

    /// Start the periodic recompute. Idempotent.
    func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.recompute()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30s
            }
        }
        recomputeNow()
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Force a recompute right now — call from view `.onChange` when an
    /// observed signal changes (e.g. nearby count, isActive).
    func recomputeNow() {
        Task { @MainActor [weak self] in
            await self?.recompute()
        }
    }

    private func recompute() async {
        let isGlowing = presence.isActive
        let nearbyCount = map?.presences.count ?? presence.nearby.count
        let hasIncoming = !waves.incoming.isEmpty
        let now = Date()

        // Track when the user became "alone while glowing" so we can
        // promote to .sleepy only after the 5-minute threshold.
        if isGlowing && nearbyCount == 0 {
            if aloneSince == nil { aloneSince = now }
        } else {
            aloneSince = nil
        }

        let next: LumaState
        if hasIncoming {
            next = .excited
        } else if isGlowing && nearbyCount > 0 {
            next = .excited
        } else if isGlowing,
                  let since = aloneSince,
                  now.timeIntervalSince(since) >= aloneThreshold {
            next = .sleepy
        } else if isGlowing {
            next = .idle
        } else {
            next = .idle
        }

        if next != ambient {
            withAnimation(.easeInOut(duration: 0.4)) {
                ambient = next
            }
        }
    }
}
