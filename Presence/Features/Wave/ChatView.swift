//  PresenceApp
//  ChatView.swift
//  Created: 2026-04-26
//  Purpose: The 10-minute chat window — Presence's core forcing function
//           for IRL meetup (CLAUDE.md § Known Pitfalls #7). NO glass on
//           the scrolling message list per the design rules; glass lives
//           on the countdown chip, composer, and end card.

import SwiftUI

struct ChatView: View {
    let roomId: UUID
    let otherUsername: String

    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var viewModel: ChatViewModel?
    @State private var draft: String = ""

    var body: some View {
        ZStack {
            PresenceBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if let viewModel {
                    messages(viewModel: viewModel)
                    Divider().background(PresenceColors.presenceWhite.opacity(0.08))
                    composer(viewModel: viewModel)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 18)
                } else {
                    Spacer()
                    LumaView(state: .connecting, size: 80)
                    Spacer()
                }
            }
            .foregroundStyle(PresenceColors.presenceWhite)
        }
        .task {
            if viewModel == nil {
                viewModel = ChatViewModel(
                    roomId: roomId,
                    backend: services.backend,
                    socket: services.socket
                )
            }
            await viewModel?.start()
        }
        .onDisappear {
            viewModel?.stop()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            GlassIconButton(systemImage: "chevron.down", accessibilityLabel: "Close chat") {
                coordinator.dismissModal()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(otherUsername)
                    .font(Typography.headline)
                Text("This window closes for both of you")
                    .font(Typography.footnote)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            }
            Spacer()
            countdownChip
            GlassIconButton(systemImage: "flag", accessibilityLabel: "Block or report") {
                openSafety()
            }
        }
    }

    /// Resolves the other participant's id from the loaded room, then
    /// dismisses chat and opens the safety sheet.
    private func openSafety() {
        guard
            let me = coordinator.currentUser?.id,
            let room = viewModel?.room
        else { return }
        let otherId = room.otherParticipant(from: me)
        let username = otherUsername
        let roomId = self.roomId
        coordinator.dismissModal()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            coordinator.present(.safety(.init(
                userId: otherId,
                username: username,
                context: .chat,
                referenceId: roomId
            )))
        }
    }

    @ViewBuilder
    private var countdownChip: some View {
        if let room = viewModel?.room {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = max(0, room.endsAt.timeIntervalSince(context.date))
                let urgent = remaining <= 60 && remaining > 0
                GlassChip(
                    text: format(remaining),
                    systemImage: remaining > 0 ? "timer" : "lock"
                )
                .foregroundStyle(urgent ? PresenceColors.auroraPink : PresenceColors.presenceWhite)
                .onChange(of: remaining) { _, newValue in
                    if newValue <= 0 { viewModel?.tickClosedFlag() }
                }
            }
        }
    }

    // MARK: - Messages

    private func messages(viewModel: ChatViewModel) -> some View {
        let me = coordinator.currentUser?.id

        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.messages) { message in
                        bubble(for: message, isMe: message.senderId == me)
                            .id(message.id)
                    }

                    if viewModel.isClosed {
                        endCard
                            .padding(.top, 24)
                            .id("end-card")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isClosed) { _, closed in
                if closed {
                    withAnimation { proxy.scrollTo("end-card", anchor: .bottom) }
                }
            }
        }
    }

    private func bubble(for message: ChatMessage, isMe: Bool) -> some View {
        HStack {
            if isMe { Spacer(minLength: 40) }
            Text(message.body)
                .font(Typography.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            isMe
                                ? PresenceColors.auroraBlue.opacity(0.85)
                                : PresenceColors.presenceWhite.opacity(0.10)
                        )
                )
                .foregroundStyle(
                    isMe ? PresenceColors.deepNight : PresenceColors.presenceWhite
                )
            if !isMe { Spacer(minLength: 40) }
        }
    }

    private var endCard: some View {
        VStack(spacing: 12) {
            LumaView(state: .celebrating, size: 96)
            Text("Time's up!")
                .font(Typography.headline)
            Text("Head over and say hi in person — that's the whole point.")
                .font(Typography.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                .padding(.horizontal, 24)

            GlassPillButton(title: "Done", systemImage: "checkmark") {
                coordinator.dismissModal()
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Composer

    private func composer(viewModel: ChatViewModel) -> some View {
        HStack(spacing: 10) {
            GlassTextField(
                placeholder: viewModel.isClosed ? "Window closed" : "Say hi...",
                text: $draft,
                systemImage: "bubble.left"
            )
            .disabled(viewModel.isClosed)

            GlassIconButton(
                systemImage: "arrow.up",
                accessibilityLabel: "Send",
                action: { Task { await sendDraft(viewModel) } }
            )
            .disabled(
                viewModel.isClosed
                    || viewModel.isSending
                    || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }

    private func sendDraft(_ viewModel: ChatViewModel) async {
        let body = draft
        draft = ""
        await viewModel.send(body)
    }

    // MARK: - Helpers

    private func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
