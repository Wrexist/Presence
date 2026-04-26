//  PresenceApp
//  LumaView.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — now Lottie-first, with the pure-SwiftUI render
//                        kept as a graceful fallback.
//  Purpose: The mascot, rendered however we can. If a Lottie animation
//           matching `state.animationName` is bundled, we render it;
//           otherwise we fall back to LumaPureView. State changes
//           crossfade in 400ms (instant when Reduce Motion is on).
//
//  Why a fallback at all: the Lottie .json/.lottie files are produced by
//  the designer (see Resources/Luma/README.md) and may not be present in
//  every build of the app. Rather than break previews and TestFlight
//  builds, we render the pure-SwiftUI version when the asset is missing.

import Lottie
import SwiftUI

struct LumaView: View {
    let state: LumaState
    var size: CGFloat = 120
    var isAnimating: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        rendered
            .frame(width: size * 1.6, height: size * 1.6)
            .accessibilityHidden(true)
            // .id(state) ensures SwiftUI treats a state change as a view
            // replacement; the .transition + .animation pair then runs
            // a crossfade between the outgoing and incoming view.
            .id(state)
            .transition(.opacity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: state)
    }

    @ViewBuilder
    private var rendered: some View {
        if isAnimating, let animation = LottieAnimation.named(state.animationName) {
            LottieView(animation: animation)
                .playing(loopMode: .loop)
                .animationSpeed(state.lottieSpeed)
        } else {
            LumaPureView(state: state, size: size, isAnimating: isAnimating)
        }
    }
}

// MARK: - Previews

#Preview("States — dark") {
    ZStack {
        LinearGradient(
            colors: [PresenceColors.deepNight, PresenceColors.softMidnight],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()

        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 32) {
                ForEach(LumaState.allCases, id: \.self) { state in
                    VStack(spacing: 8) {
                        LumaView(state: state, size: 80)
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

#Preview("Hero idle") {
    ZStack {
        LinearGradient(
            colors: [PresenceColors.dawnTop, PresenceColors.dawnBottom],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()
        LumaView(state: .idle, size: 200)
    }
    .preferredColorScheme(.light)
}
