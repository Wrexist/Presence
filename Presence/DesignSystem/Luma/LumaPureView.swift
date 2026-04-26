//  PresenceApp
//  LumaPureView.swift
//  Created: 2026-04-26 — extracted from the original LumaView.
//  Purpose: Pure-SwiftUI Luma renderer. Used as the fallback when no Lottie
//           asset is bundled for a given state. Same public sizing as
//           LumaView so the two render paths are visually interchangeable.

import SwiftUI

struct LumaPureView: View {
    let state: LumaState
    var size: CGFloat = 120
    var isAnimating: Bool = true

    @State private var float: CGFloat = 0
    @State private var breathe: CGFloat = 1.0
    @State private var haloPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            halo
            blob(color: state.bodyColor)
            face
        }
        .frame(width: size * 1.6, height: size * 1.6)
        .offset(y: float)
        .scaleEffect(breathe)
        .onAppear { if isAnimating { startAnimating() } }
        .accessibilityHidden(true)
    }

    // MARK: - Halo

    private var halo: some View {
        ZStack {
            Circle()
                .fill(state.glowColor.opacity(0.45))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size * 0.35)
                .scaleEffect(haloPulse)
            Circle()
                .fill(state.glowColor.opacity(0.25))
                .frame(width: size * 1.15, height: size * 1.15)
                .blur(radius: size * 0.22)
        }
    }

    // MARK: - Body blob

    private func blob(color: Color) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        PresenceColors.Luma.pearl,
                        color,
                        color.opacity(0.85)
                    ],
                    center: .init(x: 0.35, y: 0.3),
                    startRadius: size * 0.05,
                    endRadius: size * 0.65
                )
            )
            .frame(width: size * 1.05, height: size)
            .overlay(
                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.clear],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: size * 1.05, height: size)
            )
            .overlay(highlight)
    }

    private var highlight: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.6), Color.white.opacity(0)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: size * 0.35, height: size * 0.22)
            .offset(x: -size * 0.22, y: -size * 0.28)
            .blur(radius: 2)
    }

    // MARK: - Face

    private var face: some View {
        VStack(spacing: size * 0.07) {
            HStack(spacing: size * 0.22) {
                eye
                eye
            }
            mouth
        }
        .offset(y: size * 0.02)
    }

    private var eye: some View {
        ZStack {
            if state.eyesClosed {
                Capsule()
                    .fill(Color(hex: "#2A2040"))
                    .frame(width: size * 0.14, height: size * 0.025)
            } else {
                Circle()
                    .fill(Color(hex: "#2A2040"))
                    .frame(width: size * 0.14, height: size * 0.14)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.05, height: size * 0.05)
                    .offset(x: -size * 0.025, y: -size * 0.025)
            }
        }
    }

    private var mouth: some View {
        Path { path in
            let w = size * 0.18
            let h = size * 0.05
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: w / 2, y: h),
                control: CGPoint(x: w / 4, y: h * 1.8)
            )
            path.addQuadCurve(
                to: CGPoint(x: w, y: 0),
                control: CGPoint(x: w * 3 / 4, y: h * 1.8)
            )
        }
        .stroke(Color(hex: "#2A2040"), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        .frame(width: size * 0.18, height: size * 0.05)
    }

    // MARK: - Animation

    private func startAnimating() {
        withAnimation(.easeInOut(duration: state.floatDuration).repeatForever(autoreverses: true)) {
            float = -size * 0.04
        }
        withAnimation(.easeInOut(duration: state.floatDuration * 0.9).repeatForever(autoreverses: true)) {
            breathe = 1.04
        }
        withAnimation(.easeInOut(duration: state.floatDuration * 1.2).repeatForever(autoreverses: true)) {
            haloPulse = 1.12
        }
    }
}

#Preview("Pure fallback — all states") {
    ZStack {
        LinearGradient(
            colors: [PresenceColors.deepNight, PresenceColors.softMidnight],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()

        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 32) {
                ForEach(LumaState.allCases, id: \.self) { state in
                    VStack(spacing: 8) {
                        LumaPureView(state: state, size: 80)
                        Text(state.rawValue)
                            .font(Typography.caption)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(0.7))
                    }
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
