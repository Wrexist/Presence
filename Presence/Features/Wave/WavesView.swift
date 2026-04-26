//  PresenceApp
//  WavesView.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — driven by WavesViewModel (REST hydrate + socket
//                        merge), routes accept → celebration → chat.
//  Purpose: The Waves tab. Two sections: incoming (people who waved at
//           you) and outgoing (waves awaiting response). Tap an incoming
//           row → WaveReceivedView. A mutual wave triggers the
//           celebration modal automatically via `viewModel.pendingMutual`.

import SwiftUI

struct WavesView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    private var viewModel: WavesViewModel { services.wavesViewModel }

    var body: some View {
        ZStack {
            PresenceBackground()
            content(viewModel: viewModel)
        }
        .task {
            await viewModel.start()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(viewModel: WavesViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(viewModel: viewModel)

                section(title: "Waves for you", count: viewModel.incoming.count) {
                    if viewModel.incoming.isEmpty {
                        emptyCard(
                            text: "No waves yet",
                            sub: "Be the first to glow nearby.",
                            state: .sleepy
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.incoming) { wave in
                                Button {
                                    coordinator.present(.waveReceived(wave))
                                } label: {
                                    waveRow(wave)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Wave from \(wave.other?.username ?? "someone")")
                            }
                        }
                    }
                }

                section(title: "You waved at", count: viewModel.outgoing.count) {
                    if viewModel.outgoing.isEmpty {
                        emptyCard(
                            text: "No outgoing waves yet",
                            sub: "Tap a glowing dot on the map to start a wave.",
                            state: .gentle
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.outgoing) { wave in
                                waveRow(wave)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
            .foregroundStyle(PresenceColors.presenceWhite)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Components

    private func header(viewModel: WavesViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Waves")
                .font(Typography.display)
            Text(headerSubtitle(viewModel: viewModel))
                .font(Typography.callout)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
        }
        .padding(.top, 8)
    }

    private func headerSubtitle(viewModel: WavesViewModel) -> String {
        if viewModel.isLoading && viewModel.incoming.isEmpty && viewModel.outgoing.isEmpty {
            return "Loading..."
        }
        let total = viewModel.incoming.count + viewModel.outgoing.count
        return total == 0 ? "Moments waiting for you." : "Pull to refresh."
    }

    private func section<Content: View>(
        title: String,
        count: Int,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(Typography.headline)
                Spacer()
                if count > 0 { GlassChip(text: "\(count)") }
            }
            content()
        }
    }

    private func waveRow(_ wave: Wave) -> some View {
        let other = wave.other?.username ?? "Someone"
        return GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PresenceColors.Luma.lavender.opacity(0.5))
                        .frame(width: 56, height: 56)
                    Text(other.prefix(1))
                        .font(Typography.headline)
                        .foregroundStyle(PresenceColors.deepNight.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(other)
                        .font(Typography.headline)
                    Text(wave.icebreaker)
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                        .lineLimit(2)
                    statusChip(wave: wave)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            }
        }
    }

    @ViewBuilder
    private func statusChip(wave: Wave) -> some View {
        let remaining = max(0, wave.expiresAt.timeIntervalSinceNow)
        let mins = Int(remaining / 60)
        let label: String
        switch wave.status {
        case .sent:        label = remaining > 0 ? "expires in \(mins)m" : "expired"
        case .wavedBack:   label = "mutual"
        case .expired:     label = "expired"
        case .blocked:     label = "blocked"
        }
        Text(label)
            .font(Typography.footnote)
            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
    }

    private func emptyCard(text: String, sub: String, state: LumaState) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                LumaView(state: state, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(text).font(Typography.headline)
                    Text(sub)
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer()
            }
        }
    }

}

#Preview {
    WavesView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
