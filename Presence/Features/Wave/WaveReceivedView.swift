//  PresenceApp
//  WaveReceivedView.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — driven by the live Wave model + WavesViewModel.
//  Purpose: "Someone waved at you" — profile, bio, AI icebreaker, and the
//           mutual-wave CTA. Accept calls POST /api/waves/:id/respond,
//           dismisses, and routes into the celebration → chat flow.

import SwiftUI

struct WaveReceivedView: View {
    let wave: Wave
    let viewModel: WavesViewModel

    @Environment(AppCoordinator.self) private var coordinator
    @State private var isResponding = false
    @State private var didAccept = false

    private var other: Wave.Other {
        wave.other ?? Wave.Other(id: wave.senderId, username: "Someone", bio: nil)
    }

    var body: some View {
        ZStack {
            PresenceBackground()

            VStack(spacing: 20) {
                topBar

                Spacer(minLength: 8)

                Text("Someone waved at you")
                    .font(Typography.callout)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))

                avatar

                VStack(spacing: 4) {
                    Text(other.username)
                        .font(Typography.title)
                    if let bio = other.bio, !bio.isEmpty {
                        Text(bio)
                            .font(Typography.caption)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                    }
                }

                icebreakerCard

                Spacer()

                ctaStack
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .foregroundStyle(PresenceColors.presenceWhite)
        }
    }

    // MARK: - Components

    private var topBar: some View {
        HStack {
            GlassIconButton(systemImage: "chevron.down", accessibilityLabel: "Dismiss") {
                coordinator.dismissModal()
            }
            Spacer()
            GlassIconButton(systemImage: "flag", accessibilityLabel: "Report or block") {
                // TODO(D6): block / report sheet.
            }
        }
        .padding(.top, 8)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            PresenceColors.Luma.lavender.opacity(0.8),
                            PresenceColors.auroraViolet.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 10)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                PresenceColors.Luma.peach,
                                PresenceColors.Luma.blush
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                Text(other.username.prefix(1).uppercased())
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(PresenceColors.deepNight.opacity(0.75))
            }
            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))

            LumaView(state: .waving, size: 44)
                .offset(x: 80, y: -70)
        }
        .frame(height: 220)
    }

    private var icebreakerCard: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                    Text("icebreaker")
                        .font(Typography.footnote)
                        .textCase(.uppercase)
                }
                .foregroundStyle(PresenceColors.auroraAmber)

                Text(wave.icebreaker)
                    .font(Typography.body)
                    .foregroundStyle(PresenceColors.presenceWhite)

                if let bio = other.bio, !bio.isEmpty {
                    Text("— \(bio)")
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                }
            }
        }
    }

    private var ctaStack: some View {
        VStack(spacing: 10) {
            GlassPillButton(
                title: ctaTitle,
                systemImage: didAccept ? "checkmark" : "hand.wave.fill"
            ) {
                Task { await accept() }
            }
            .shadow(color: PresenceColors.auroraPink.opacity(0.5), radius: 22, y: 6)
            .disabled(isResponding || didAccept)

            Button("Not right now") {
                Task {
                    await viewModel.decline(wave)
                    coordinator.dismissModal()
                }
            }
            .font(Typography.callout)
            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            .buttonStyle(.plain)
            .disabled(isResponding)
        }
    }

    private var ctaTitle: String {
        if didAccept { return "Wave sent — opening chat" }
        if isResponding { return "Sending..." }
        return "Send a wave back"
    }

    // MARK: - Actions

    private func accept() async {
        guard !isResponding, !didAccept else { return }
        isResponding = true
        defer { isResponding = false }

        let response = await viewModel.accept(wave)
        guard response?.mutual == true else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            didAccept = true
        }
        // Brief beat so the user sees the checkmark, then hand off to the
        // celebration. WavesViewModel.pendingMutual is set; the modal swap
        // happens in the parent view's onChange.
        try? await Task.sleep(nanoseconds: 700_000_000)
        coordinator.dismissModal()
    }
}
