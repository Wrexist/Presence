//  PresenceApp
//  OnboardingUsernameView.swift
//  Created: 2026-04-24
//  Purpose: Username picker. Not real name — this is what nearby users see.

import SwiftUI

struct OnboardingUsernameView: View {
    @Bindable var coordinator: OnboardingCoordinator

    private var isValid: Bool {
        AuthService.isValidUsername(coordinator.username)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            LumaView(state: .idle, size: 96)

            VStack(spacing: 8) {
                Text("Pick a username")
                    .font(Typography.title)
                Text("Not your real name — this is what nearby glowers see.")
                    .font(Typography.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    .padding(.horizontal, 32)
            }

            GlassTextField(
                placeholder: "morningfern",
                text: $coordinator.username,
                prefix: "@",
                textContentType: .username,
                maxLength: 24
            )
            .padding(.horizontal, 28)
            .onChange(of: coordinator.username) { _, newValue in
                coordinator.username = newValue.lowercased()
            }

            Text("3–24 characters · letters, numbers, underscore")
                .font(Typography.footnote)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))

            if let err = coordinator.errorMessage {
                Text(err)
                    .font(Typography.caption)
                    .foregroundStyle(PresenceColors.auroraPink)
                    .padding(.horizontal, 24)
            }

            Spacer()

            GlassPillButton(title: "Continue", systemImage: "arrow.right") {
                Task { await coordinator.submitUsername() }
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
        OnboardingUsernameView(coordinator: OnboardingCoordinator(auth: ServiceContainer.preview().auth, onComplete: { _ in }))
            .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}
