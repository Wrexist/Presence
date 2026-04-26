//  PresenceApp
//  OnboardingPrivacyView.swift
//  Created: 2026-04-24
//  Purpose: Privacy explanation shown BEFORE the system location prompt.
//           Per LEARNINGS.md: explaining first yields ~40% better grant rate.
//           We do NOT call CLLocationManager here — that permission prompt
//           fires on first "Go Present" tap (matches the "location only
//           when Present" privacy model).

import SwiftUI

struct OnboardingPrivacyView: View {
    let coordinator: OnboardingCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(PresenceColors.auroraGreen.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 24)
                LumaView(state: .gentle, size: 100)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(PresenceColors.auroraGreen)
                    .offset(x: 42, y: 30)
            }

            VStack(spacing: 8) {
                Text("Your privacy, always")
                    .font(Typography.title)
                Text("A few things we always do.")
                    .font(Typography.callout)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
            }

            VStack(spacing: 12) {
                privacyRow(
                    icon: "location.slash",
                    title: "Location only when you're Present",
                    body: "We never track you in the background. Opt in per session."
                )
                privacyRow(
                    icon: "scope",
                    title: "Reduced precision",
                    body: "Your dot is fuzzed by about 50 metres so nobody can pinpoint you."
                )
                privacyRow(
                    icon: "clock.arrow.circlepath",
                    title: "Auto-expires in 3 hours",
                    body: "Your presence disappears automatically. No history stored."
                )
            }
            .padding(.horizontal, 20)

            Spacer()

            GlassPillButton(title: "I'm with it", systemImage: "arrow.right") {
                coordinator.advanceFromPrivacy()
            }
            .padding(.bottom, 36)
        }
    }

    private func privacyRow(icon: String, title: String, body: String) -> some View {
        GlassCard(cornerRadius: 20) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PresenceColors.auroraGreen.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PresenceColors.auroraGreen)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headline)
                    Text(body)
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        OnboardingPrivacyView(coordinator: OnboardingCoordinator(auth: ServiceContainer.preview().auth, onComplete: { _ in }))
            .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}
