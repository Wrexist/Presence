//  PresenceApp
//  WavesViewModel.swift
//  Created: 2026-04-26
//  Purpose: Live state for the Waves tab. Hydrates incoming + outgoing
//           via GET /api/waves; merges wave_received and wave_mutual
//           socket events; calls POST /api/waves/:id/respond on accept
//           or decline. Emits a celebration trigger when a mutual lands.

import Foundation
import SwiftUI

@MainActor
@Observable
final class WavesViewModel {
    // MARK: - Public state

    private(set) var incoming: [Wave] = []
    private(set) var outgoing: [Wave] = []
    private(set) var isLoading: Bool = false
    private(set) var lastError: BackendError?

    /// Set when the receiver flips a wave to mutual or when a mutual event
    /// arrives over the socket. The view consumes + clears it to present
    /// the celebration / chat path.
    var pendingMutual: PresenceEvent.WaveMutualPayload?

    // MARK: - Dependencies

    private let backend: BackendClient
    private let socket: SocketService

    private var streamTask: Task<Void, Never>?

    init(backend: BackendClient, socket: SocketService) {
        self.backend = backend
        self.socket = socket
    }

    // MARK: - Lifecycle

    func start() async {
        if streamTask == nil {
            streamTask = Task { [weak self] in
                await self?.consumeStream()
            }
        }
        await refresh()
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
    }

    // MARK: - Refresh

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: WaveListResponse = try await backend.get(.myWaves())
            self.incoming = response.incoming
            self.outgoing = response.outgoing
            self.lastError = nil
        } catch let error as BackendError {
            self.lastError = error
        } catch {
            self.lastError = .network(nil)
        }
    }

    // MARK: - Respond

    /// Accepts the wave. Returns the chat-room handoff so the view can
    /// route into the celebration → ChatView flow.
    @discardableResult
    func accept(_ wave: Wave) async -> RespondWaveResponse? {
        await respond(waveId: wave.id, accepted: true)
    }

    func decline(_ wave: Wave) async {
        _ = await respond(waveId: wave.id, accepted: false)
    }

    private func respond(waveId: UUID, accepted: Bool) async -> RespondWaveResponse? {
        let body = RespondWaveRequest(accepted: accepted)
        do {
            let response: RespondWaveResponse = try await backend.send(
                .respondToWave(id: waveId),
                body: body
            )
            // Drop the wave locally — its row is now in waved_back terminal
            // state. The list will re-hydrate on next refresh.
            incoming.removeAll { $0.id == waveId }

            if response.mutual,
               let chatRoomId = response.chatRoomId,
               let endsAt = response.chatEndsAt {
                // Synthesize a payload mirroring the socket event so the
                // celebration trigger path stays single-shape.
                let wave = self.lastKnownWave(id: waveId)
                pendingMutual = PresenceEvent.WaveMutualPayload(
                    waveId: waveId,
                    senderId: wave?.senderId ?? UUID(),
                    receiverId: wave?.receiverId ?? UUID(),
                    respondedAt: Date(),
                    chatRoomId: chatRoomId,
                    chatStartedAt: nil,
                    chatEndsAt: endsAt,
                    connectionCount: nil
                )
            }
            return response
        } catch let error as BackendError {
            lastError = error
            return nil
        } catch {
            lastError = .network(nil)
            return nil
        }
    }

    // MARK: - Stream

    private func consumeStream() async {
        for await event in socket.events() {
            if Task.isCancelled { break }
            switch event {
            case .waveReceived:
                // The realtime payload lacks the receiverId hydrate shape we
                // use in the UI, so we just refresh the list — cheap and the
                // UI ergonomics stay consistent.
                await refresh()
            case .waveMutual(let payload):
                pendingMutual = payload
                // Drop the related wave from incoming; it's now in chat path.
                incoming.removeAll { $0.id == payload.waveId }
                outgoing.removeAll { $0.id == payload.waveId }
            default:
                break
            }
        }
    }

    private func lastKnownWave(id: UUID) -> Wave? {
        incoming.first(where: { $0.id == id }) ?? outgoing.first(where: { $0.id == id })
    }
}
