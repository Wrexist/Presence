//  PresenceApp
//  ChatViewModel.swift
//  Created: 2026-04-26
//  Purpose: Loads a chat room's history, posts new messages, and merges
//           incoming chat_message events from the socket. Server enforces
//           the 10-minute window — ChatView just disables the composer at
//           the cutoff so the user can't even attempt a closed-window send.

import Foundation
import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    private(set) var room: ChatRoom?
    private(set) var messages: [ChatMessage] = []
    private(set) var isLoading: Bool = false
    private(set) var isSending: Bool = false
    private(set) var lastError: BackendError?
    private(set) var isClosed: Bool = false

    private let backend: BackendClient
    private let socket: SocketService
    private let roomId: UUID

    private var streamTask: Task<Void, Never>?

    init(roomId: UUID, backend: BackendClient, socket: SocketService) {
        self.roomId = roomId
        self.backend = backend
        self.socket = socket
    }

    // MARK: - Lifecycle

    func start() async {
        socket.subscribeChat(roomId: roomId)
        if streamTask == nil {
            streamTask = Task { [weak self] in
                await self?.consumeStream()
            }
        }
        await load()
    }

    func stop() {
        socket.unsubscribeChat(roomId: roomId)
        streamTask?.cancel()
        streamTask = nil
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: ChatLoadResponse = try await backend.get(.loadChat(roomId: roomId))
            self.room = response.room
            self.messages = response.messages
            self.isClosed = response.room.endsAt.timeIntervalSinceNow <= 0
            self.lastError = nil
        } catch let error as BackendError {
            self.lastError = error
        } catch {
            self.lastError = .network(nil)
        }
    }

    // MARK: - Send

    func send(_ body: String) async {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending, !isClosed else { return }
        guard let room, room.endsAt.timeIntervalSinceNow > 0 else {
            isClosed = true
            return
        }

        isSending = true
        defer { isSending = false }
        let request = PostChatMessageRequest(body: trimmed)
        do {
            let message: ChatMessage = try await backend.send(
                .sendChatMessage(roomId: roomId),
                body: request
            )
            // Append optimistically — the server's broadcast may also land
            // here via the socket, but our id de-dupe keeps the list clean.
            appendIfNew(message)
        } catch let error as BackendError {
            lastError = error
            // 410 Gone surfaces as .server(410) — bridge to the local close
            // flag so the composer locks immediately.
            if case .server(let status, _) = error, status == 410 {
                isClosed = true
            }
        } catch {
            lastError = .network(nil)
        }
    }

    // MARK: - Stream

    private func consumeStream() async {
        for await event in socket.events() {
            if Task.isCancelled { break }
            if case .chatMessage(let message) = event, message.roomId == roomId {
                appendIfNew(message)
            }
        }
    }

    private func appendIfNew(_ message: ChatMessage) {
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        messages.append(message)
        messages.sort { $0.createdAt < $1.createdAt }
    }

    /// Convenience: lock the composer when the timer hits zero. Called
    /// from ChatView's TimelineView observer.
    func tickClosedFlag() {
        if let room, room.endsAt.timeIntervalSinceNow <= 0 {
            isClosed = true
        }
    }
}
