//  PresenceApp
//  SocketService.swift
//  Created: 2026-04-26
//  Purpose: Socket.io client wrapper. Owns connect/subscribe/disconnect plus
//           an AsyncStream of presence events. Auth token rides on the
//           handshake `connectParams.token`; the server (B5) reads that as
//           `socket.handshake.query.token` and verifies via Supabase.
//
//  Concurrency: The SocketIO callbacks are dispatched onto SocketManager.handleQueue
//  which we explicitly pin to .main, so all callback bodies run on the main
//  actor. The class itself is @MainActor for safe access to the continuation.

import Foundation
@preconcurrency import SocketIO

@MainActor
@Observable
final class SocketService {
    // MARK: - Public state

    enum ConnectionState: Sendable, Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting(attempt: Int)
    }

    private(set) var state: ConnectionState = .disconnected

    // MARK: - Dependencies

    private let baseURL: URL
    private let auth: AuthService

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    /// One continuation per active consumer — events are fanned out to all
    /// of them. AsyncStream is single-consumer, so views that need to react
    /// to socket events (MapViewModel, WavesViewModel, ChatViewModel) each
    /// get their own stream via `events()`.
    private var continuations: [UUID: AsyncStream<PresenceEvent>.Continuation] = [:]

    private var pendingSubscribe: (lat: Double, lng: Double)?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(baseURL: URL, auth: AuthService) {
        self.baseURL = baseURL
        self.auth = auth
    }

    deinit {
        for c in continuations.values { c.finish() }
    }

    /// Returns a fresh AsyncStream that receives every subsequent event.
    /// The returned stream cleans up its continuation automatically when
    /// the consumer's iterating task is cancelled.
    func events() -> AsyncStream<PresenceEvent> {
        AsyncStream(bufferingPolicy: .unbounded) { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            let id = UUID()
            self.continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    private func yieldAll(_ event: PresenceEvent) {
        for c in continuations.values { c.yield(event) }
    }

    // MARK: - Lifecycle

    func connect() async {
        guard state == .disconnected else { return }
        guard let token = await auth.currentAccessToken() else {
            state = .disconnected
            return
        }

        state = .connecting
        let manager = SocketManager(
            socketURL: baseURL,
            config: [
                .log(false),
                .compress,
                .reconnects(true),
                .reconnectAttempts(-1),       // never give up
                .reconnectWait(1),
                .reconnectWaitMax(30),
                .randomizationFactor(0.5),
                .forceWebsockets(true),
                .connectParams(["token": token])
            ]
        )
        manager.handleQueue = DispatchQueue.main

        let socket = manager.defaultSocket
        attachHandlers(to: socket)
        self.manager = manager
        self.socket = socket
        socket.connect()
    }

    func disconnect() {
        socket?.disconnect()
        manager?.disconnect()
        socket = nil
        manager = nil
        pendingSubscribe = nil
        state = .disconnected
    }

    // MARK: - Subscribe

    /// Tells the server to join the geohash room for these coordinates plus
    /// its 8 neighbors. Safe to call before `connect()` returns — the call
    /// is queued and replayed on `.connect`.
    func subscribe(lat: Double, lng: Double) {
        if state == .connected {
            socket?.emit("subscribe", ["lat": lat, "lng": lng])
        } else {
            pendingSubscribe = (lat, lng)
        }
    }

    /// Joins the chat room. Server verifies the caller is a participant
    /// before honoring the join — non-participants are silently ignored.
    func subscribeChat(roomId: UUID) {
        socket?.emit("chat:subscribe", ["roomId": roomId.uuidString])
    }

    func unsubscribeChat(roomId: UUID) {
        socket?.emit("chat:unsubscribe", ["roomId": roomId.uuidString])
    }

    // MARK: - Handlers

    private func attachHandlers(to socket: SocketIOClient) {
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.state = .connected
                if let pending = self.pendingSubscribe {
                    self.socket?.emit("subscribe", ["lat": pending.lat, "lng": pending.lng])
                    self.pendingSubscribe = nil
                }
            }
        }

        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.state = .disconnected
            }
        }

        socket.on(clientEvent: .reconnectAttempt) { [weak self] data, _ in
            let attempt = (data.first as? Int) ?? 0
            Task { @MainActor [weak self] in
                self?.state = .reconnecting(attempt: attempt)
            }
        }

        socket.on(clientEvent: .error) { _, _ in
            // Errors on the SocketIOClient surface as Strings; we don't
            // surface them to the UI directly. State transitions are
            // driven by the connect/disconnect lifecycle events instead.
        }

        socket.on("presence_joined") { [weak self] data, _ in
            guard let self, let dict = data.first as? [String: Any] else { return }
            if let payload = self.decode(JoinedDTO.self, from: dict) {
                let event = PresenceEvent.joined(
                    PresenceEvent.JoinedPayload(
                        id: payload.id,
                        userId: payload.userId,
                        lat: payload.lat,
                        lng: payload.lng,
                        venueName: payload.venueName,
                        expiresAt: payload.expiresAt
                    )
                )
                self.yieldAll(event)
            }
        }

        socket.on("presence_left") { [weak self] data, _ in
            guard let self, let dict = data.first as? [String: Any] else { return }
            if let payload = self.decode(LeftDTO.self, from: dict) {
                self.yieldAll(.left(id: payload.id))
            }
        }

        socket.on("wave_received") { [weak self] data, _ in
            guard let self, let dict = data.first as? [String: Any] else { return }
            if let payload = self.decode(PresenceEvent.WaveReceivedPayload.self, from: dict) {
                self.yieldAll(.waveReceived(payload))
            }
        }

        socket.on("wave_mutual") { [weak self] data, _ in
            guard let self, let dict = data.first as? [String: Any] else { return }
            if let payload = self.decode(PresenceEvent.WaveMutualPayload.self, from: dict) {
                self.yieldAll(.waveMutual(payload))
            }
        }

        socket.on("chat_message") { [weak self] data, _ in
            guard let self, let dict = data.first as? [String: Any] else { return }
            if let message = self.decode(ChatMessage.self, from: dict) {
                self.yieldAll(.chatMessage(message))
            }
        }
    }

    // MARK: - Decoding

    private func decode<T: Decodable>(_ type: T.Type, from dict: [String: Any]) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            return nil
        }
        return try? decoder.decode(T.self, from: data)
    }

    // Wire-only DTOs. We keep these private so the public PresenceEvent
    // surface can evolve without breaking callers.
    private struct JoinedDTO: Decodable {
        let id: UUID
        let userId: UUID
        let lat: Double
        let lng: Double
        let venueName: String?
        let expiresAt: Date
    }

    private struct LeftDTO: Decodable {
        let id: UUID
    }
}
