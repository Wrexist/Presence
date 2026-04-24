//  PresenceApp
//  WaveReceivedView.swift
//  Created: 2026-04-24
//  Purpose: "Someone waved at you" — profile, bio, AI icebreaker, and the
//           mutual-wave CTA. Matches the third panel of Design_2.

import SwiftUI

struct WaveReceivedView: View {
    let wave: IncomingWave
    @Environment(AppCoordinator.self) private var coordinator
    @State private var sentBack = false

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
                    Text("\(wave.username), \(wave.age)")
                        .font(Typography.title)
                    Text(wave.venueName)
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
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
            GlassIconButton(systemImage: "flag", accessibilityLabel: "Report or block") {}
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

                // Stylized initial since we don't ship photos in MVP.
                Text(wave.username.prefix(1).uppercased())
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(PresenceColors.deepNight.opacity(0.75))
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )

            // Tiny Luma floating at the edge of the avatar halo.
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

                Text("— \(wave.bio)")
                    .font(Typography.caption)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            }
        }
    }

    private var ctaStack: some View {
        VStack(spacing: 10) {
            GlassPillButton(
                title: sentBack ? "Wave sent — opening chat" : "Send a wave back",
                systemImage: sentBack ? "checkmark" : "hand.wave.fill"
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    sentBack = true
                }
            }
            .shadow(color: PresenceColors.auroraPink.opacity(0.5), radius: 22, y: 6)

            Button("Not right now") {
                coordinator.dismissModal()
            }
            .font(Typography.callout)
            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview-grade model

struct IncomingWave: Identifiable, Hashable {
    let id: UUID
    let username: String
    let age: Int
    let bio: String
    let venueName: String
    let icebreaker: String

    static let sample = IncomingWave(
        id: UUID(),
        username: "Maya",
        age: 24,
        bio: "morning coffee runs",
        venueName: "Bluestone Coffee · 4 min walk",
        icebreaker: "We've both been chasing the same oat-milk flat white all week — is their afternoon special any good?"
    )
}

#Preview {
    WaveReceivedView(wave: .sample)
        .environment(AppCoordinator())
        .preferredColorScheme(.dark)
}
