//  PresenceApp
//  OnboardingWelcomeView.swift
//  Created: 2026-04-24
//  Purpose: First screen — Luma floats in, then the line fades in.
//           "You're not alone in feeling alone."

import SwiftUI

struct OnboardingWelcomeView: View {
    let coordinator: OnboardingCoordinator
    @State private var textOpacity: Double = 0
    @State private var ctaOpacity: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            LumaView(state: .idle, size: 220)

            VStack(spacing: 14) {
                Text("You're not alone in feeling alone.")
                    .font(Typography.title)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text("Presence shows you who nearby is open to connecting — right now, in real life.")
                    .font(Typography.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    .padding(.horizontal, 32)
            }
            .opacity(textOpacity)

            Spacer()

            GlassPillButton(title: "Let's begin", systemImage: "sparkles") {
                coordinator.advanceFromWelcome()
            }
            .shadow(color: PresenceColors.auroraBlue.opacity(0.45), radius: 22, y: 6)
            .opacity(ctaOpacity)
            .padding(.bottom, 36)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.8)) { textOpacity = 1 }
            withAnimation(.easeOut(duration: 0.8).delay(1.6)) { ctaOpacity = 1 }
        }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        OnboardingWelcomeView(coordinator: OnboardingCoordinator(auth: ServiceContainer.preview().auth, onComplete: { _ in }))
            .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}
