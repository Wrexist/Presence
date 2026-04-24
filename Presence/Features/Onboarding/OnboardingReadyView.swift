//  PresenceApp
//  OnboardingReadyView.swift
//  Created: 2026-04-24
//  Purpose: Final step. Hands off to the map. Luma celebrates.

import SwiftUI

struct OnboardingReadyView: View {
    let coordinator: OnboardingCoordinator

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            LumaView(state: .celebrating, size: 200)

            VStack(spacing: 12) {
                Text("You're all set")
                    .font(Typography.display)
                Text("When you're ready to glow, tap the button.")
                    .font(Typography.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    .padding(.horizontal, 32)
            }

            Spacer()

            GlassPillButton(title: "Open the map", systemImage: "sparkles") {
                coordinator.finish()
            }
            .shadow(color: PresenceColors.auroraAmber.opacity(0.55), radius: 22, y: 6)
            .padding(.bottom, 36)
        }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        OnboardingReadyView(coordinator: OnboardingCoordinator(onComplete: { _ in }))
            .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}
