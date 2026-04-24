//  PresenceApp
//  HomeView.swift
//  Created: 2026-04-24
//  Purpose: The main "who's nearby" screen. Stylized map canvas with
//           glowing presence dots and floating Luma overlays, a venue
//           header at the top, and the primary "Go Present" CTA anchored
//           to the bottom. A real MapKit Map{} replaces the canvas in
//           Sprint 1 once LocationService lands.

import SwiftUI

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    // Stub data for UI bring-up. Replace with MapViewModel in Sprint 1.
    private let venueName = "San Francisco"
    private let nearbyCount = 8
    private let previewDots: [PreviewDot] = [
        .init(x: 0.22, y: 0.20, color: PresenceColors.auroraPink),
        .init(x: 0.70, y: 0.18, color: PresenceColors.auroraViolet),
        .init(x: 0.85, y: 0.38, color: PresenceColors.auroraBlue),
        .init(x: 0.30, y: 0.45, color: PresenceColors.auroraAmber),
        .init(x: 0.58, y: 0.55, color: PresenceColors.auroraViolet),
        .init(x: 0.18, y: 0.68, color: PresenceColors.auroraPink),
        .init(x: 0.80, y: 0.72, color: PresenceColors.auroraBlue)
    ]

    var body: some View {
        ZStack {
            MapCanvas()
                .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    ForEach(previewDots) { dot in
                        PresenceDotView(color: dot.color)
                            .position(
                                x: proxy.size.width * dot.x,
                                y: proxy.size.height * dot.y
                            )
                    }

                    // A couple of floating Lumas scattered on the map, per the mockups.
                    LumaView(state: .idle, size: 44)
                        .position(
                            x: proxy.size.width * 0.42,
                            y: proxy.size.height * 0.32
                        )
                    LumaView(state: .excited, size: 40)
                        .position(
                            x: proxy.size.width * 0.66,
                            y: proxy.size.height * 0.62
                        )

                    // Self dot at center.
                    PresenceDotView(color: PresenceColors.selfGlow, size: 26, isSelf: true)
                        .position(
                            x: proxy.size.width * 0.5,
                            y: proxy.size.height * 0.5
                        )
                }
            }

            VStack {
                header
                Spacer()
                goPresentCTA
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Header

    private var header: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PresenceColors.auroraBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(venueName)
                        .font(Typography.headline)
                        .foregroundStyle(PresenceColors.presenceWhite)
                    Text("\(nearbyCount) people glowing nearby")
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer()
                GlassChip(text: "Live", systemImage: "dot.radiowaves.left.and.right")
            }
        }
    }

    // MARK: - CTA

    private var goPresentCTA: some View {
        VStack(spacing: 12) {
            GlassChip(text: "Open to connecting · right now", systemImage: "sparkles")
            GlassPillButton(title: "Go Present", systemImage: "sparkles") {
                coordinator.present(.goPresent)
            }
            .shadow(color: PresenceColors.auroraBlue.opacity(0.5), radius: 22, y: 6)
        }
    }
}

// MARK: - Supporting types

private struct PreviewDot: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
}

/// Placeholder map canvas until MapKit is wired in Sprint 1.
/// Intentionally muted so dots and Lumas pop above it.
private struct MapCanvas: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    PresenceColors.deepNight,
                    PresenceColors.softMidnight
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Faint grid suggesting streets.
            GeometryReader { proxy in
                Path { path in
                    let step: CGFloat = 48
                    var x: CGFloat = 0
                    while x < proxy.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                        x += step
                    }
                    var y: CGFloat = 0
                    while y < proxy.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                        y += step
                    }
                }
                .stroke(PresenceColors.presenceWhite.opacity(0.05), lineWidth: 0.5)
            }

            // A soft purple wash to mimic the lavender map tint in Design_2.
            RadialGradient(
                colors: [
                    PresenceColors.auroraViolet.opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 360
            )
        }
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
