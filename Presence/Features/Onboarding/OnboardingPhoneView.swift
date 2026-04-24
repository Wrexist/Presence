//  PresenceApp
//  OnboardingPhoneView.swift
//  Created: 2026-04-24
//  Purpose: Phone number entry. Country code + number. Sends OTP.

import SwiftUI

struct OnboardingPhoneView: View {
    @Bindable var coordinator: OnboardingCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            LumaView(state: .gentle, size: 96)

            VStack(spacing: 8) {
                Text("What's your number?")
                    .font(Typography.title)
                Text("We'll text a 6-digit code. No email, no passwords.")
                    .font(Typography.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    .padding(.horizontal, 32)
            }

            HStack(spacing: 12) {
                GlassTextField(
                    placeholder: "+1",
                    text: $coordinator.phoneCountryCode,
                    maxLength: 4
                )
                .frame(width: 96)

                GlassTextField(
                    placeholder: "(415) 555-0199",
                    text: $coordinator.phoneNumber,
                    systemImage: "phone.fill",
                    keyboardType: .phonePad,
                    textContentType: .telephoneNumber,
                    maxLength: 20
                )
            }
            .padding(.horizontal, 20)

            if let err = coordinator.errorMessage {
                Text(err)
                    .font(Typography.caption)
                    .foregroundStyle(PresenceColors.auroraPink)
                    .padding(.horizontal, 24)
            }

            Spacer()

            GlassPillButton(
                title: coordinator.isSubmitting ? "Sending..." : "Send code",
                systemImage: coordinator.isSubmitting ? nil : "arrow.right"
            ) {
                Task { await coordinator.submitPhone() }
            }
            .padding(.bottom, 36)
            .disabled(coordinator.isSubmitting || coordinator.phoneNumber.filter(\.isNumber).count < 7)
            .opacity(coordinator.phoneNumber.filter(\.isNumber).count < 7 ? 0.5 : 1)
        }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        OnboardingPhoneView(coordinator: OnboardingCoordinator(onComplete: { _ in }))
            .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}
