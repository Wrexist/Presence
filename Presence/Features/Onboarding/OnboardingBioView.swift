//  PresenceApp
//  OnboardingBioView.swift
//  Created: 2026-04-24
//  Purpose: 3-word bio. Intentional constraint — low effort, memorable.

import SwiftUI

struct OnboardingBioView: View {
    @Bindable var coordinator: OnboardingCoordinator

    private var wordCount: Int { coordinator.bioWordCount }
    private var isValid: Bool {
        wordCount >= 1 && wordCount <= 3 &&
            coordinator.bio.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            LumaView(state: .excited, size: 96)

            VStack(spacing: 8) {
                Text("Three words about you")
                    .font(Typography.title)
                Text("What you're into, in three words or less. Think: \"morning coffee runs\", \"late-night drawing\".")
                    .font(Typography.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    .padding(.horizontal, 28)
            }

            GlassTextField(
                placeholder: "morning coffee runs",
                text: $coordinator.bio,
                autocapitalization: .never,
                maxLength: 60
            )
            .padding(.horizontal, 24)

            HStack(spacing: 6) {
                Circle()
                    .fill(isValid ? PresenceColors.auroraGreen : PresenceColors.presenceWhite.opacity(0.3))
                    .frame(width: 6, height: 6)
                Text("\(wordCount) of 3 words")
                    .font(Typography.footnote)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            }

            if let err = coordinator.errorMessage {
                Text(err)
                    .font(Typography.caption)
                    .foregroundStyle(PresenceColors.auroraPink)
                    .padding(.horizontal, 24)
            }

            Spacer()

            GlassPillButton(
                title: coordinator.isSubmitting ? "Saving..." : "That's me",
                systemImage: coordinator.isSubmitting ? nil : "checkmark"
            ) {
                Task { await coordinator.submitBio() }
            }
            .padding(.bottom, 36)
            .disabled(!isValid || coordinator.isSubmitting)
            .opacity(isValid ? 1 : 0.5)
        }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        OnboardingBioView(coordinator: OnboardingCoordinator(auth: ServiceContainer.preview().auth, onComplete: { _ in }))
            .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}
