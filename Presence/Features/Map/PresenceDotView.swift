//  PresenceApp
//  PresenceDotView.swift
//  Created: 2026-04-24
//  Purpose: Glowing presence marker. Used on the Home/Map view for each
//           nearby Present user. Per CLAUDE.md this is NOT a glass surface —
//           it's a pure colored glow so it stays legible above the map.

import SwiftUI

struct PresenceDotView: View {
    let color: Color
    var size: CGFloat = GlassTokens.Radius.dot
    var isSelf: Bool = false

    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: size * 2.2, height: size * 2.2)
                .blur(radius: 8)
                .scaleEffect(pulse ? 1.25 : 1.0)

            Circle()
                .fill(color.opacity(0.45))
                .frame(width: size * 1.6, height: size * 1.6)
                .scaleEffect(pulse ? 1.2 : 1.0)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [PresenceColors.presenceWhite, color],
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: 1,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(isSelf ? 0.9 : 0.4), lineWidth: isSelf ? 2 : 1)
                )
        }
        .animation(
            .easeInOut(duration: GlassTokens.Motion.pulseDuration)
                .repeatForever(autoreverses: true),
            value: pulse
        )
        .onAppear { pulse = true }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        HStack(spacing: 28) {
            PresenceDotView(color: PresenceColors.auroraBlue)
            PresenceDotView(color: PresenceColors.auroraPink)
            PresenceDotView(color: PresenceColors.auroraAmber)
            PresenceDotView(color: PresenceColors.selfGlow, size: 28, isSelf: true)
        }
    }
    .preferredColorScheme(.dark)
}
