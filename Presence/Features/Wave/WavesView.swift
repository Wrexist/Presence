//  PresenceApp
//  WavesView.swift
//  Created: 2026-04-24
//  Purpose: The Waves tab. Two sections: incoming waves (people who
//           waved at you) and sent waves awaiting response. Tap a row to
//           open WaveReceivedView.

import SwiftUI

struct WavesView: View {
    @Environment(AppCoordinator.self) private var coordinator

    private let incoming: [IncomingWave] = [
        .sample,
        .init(
            id: UUID(),
            username: "Theo",
            age: 31,
            bio: "runs at golden hour",
            venueName: "Riverside Park · 9 min walk",
            icebreaker: "Prime golden-hour park light right now — do you run this route often?"
        )
    ]

    var body: some View {
        ZStack {
            PresenceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    section(title: "Waves for you", count: incoming.count) {
                        VStack(spacing: 12) {
                            ForEach(incoming) { wave in
                                Button {
                                    coordinator.present(.wave(wave))
                                } label: {
                                    waveRow(wave)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    section(title: "You waved at", count: 0) {
                        GlassCard(cornerRadius: 22) {
                            HStack(spacing: 14) {
                                LumaView(state: .gentle, size: 52)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("No outgoing waves yet")
                                        .font(Typography.headline)
                                    Text("Tap a glowing dot on the map to start a wave.")
                                        .font(Typography.caption)
                                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
                .foregroundStyle(PresenceColors.presenceWhite)
            }
        }
    }

    // MARK: - Components

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Waves")
                .font(Typography.display)
            Text("Moments waiting for you.")
                .font(Typography.callout)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
        }
        .padding(.top, 8)
    }

    private func section<Content: View>(
        title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(Typography.headline)
                Spacer()
                if count > 0 {
                    GlassChip(text: "\(count)")
                }
            }
            content()
        }
    }

    private func waveRow(_ wave: IncomingWave) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PresenceColors.Luma.lavender.opacity(0.5))
                        .frame(width: 56, height: 56)
                    Text(wave.username.prefix(1))
                        .font(Typography.headline)
                        .foregroundStyle(PresenceColors.deepNight.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(wave.username), \(wave.age)")
                        .font(Typography.headline)
                    Text(wave.icebreaker)
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                        .lineLimit(2)
                    Text(wave.venueName)
                        .font(Typography.footnote)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            }
        }
    }
}

#Preview {
    WavesView()
        .environment(AppCoordinator())
        .preferredColorScheme(.dark)
}
