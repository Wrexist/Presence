//  PresenceApp
//  OnboardingOTPView.swift
//  Created: 2026-04-24
//  Purpose: OTP verification. Single field, 6 digits, auto-submits.

import SwiftUI

struct OnboardingOTPView: View {
    @Bindable var coordinator: OnboardingCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            LumaView(state: .connecting, size: 96)

            VStack(spacing: 8) {
                Text("Check your texts")
                    .font(Typography.title)
                Text("Enter the 6-digit code we sent to \(coordinator.e164Phone).")
                    .font(Typography.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    .padding(.horizontal, 32)
            }

            GlassTextField(
                placeholder: "000000",
                text: $coordinator.otpCode,
                systemImage: "number",
                keyboardType: .numberPad,
                textContentType: .oneTimeCode,
                maxLength: 6
            )
            .padding(.horizontal, 40)
            .onChange(of: coordinator.otpCode) { _, newValue in
                // Auto-submit the moment 6 digits are entered.
                if newValue.count == 6, newValue.allSatisfy(\.isNumber),
                   !coordinator.isSubmitting {
                    Task { await coordinator.submitOTP() }
                }
            }

            if let err = coordinator.errorMessage {
                Text(err)
                    .font(Typography.caption)
                    .foregroundStyle(PresenceColors.auroraPink)
            }

            Button("Change number") {
                coordinator.restartPhoneEntry()
            }
            .font(Typography.callout)
            .foregroundStyle(PresenceColors.auroraBlue.opacity(coordinator.isSubmitting ? 0.4 : 0.9))
            .buttonStyle(.plain)
            .disabled(coordinator.isSubmitting)

            Spacer()

            GlassPillButton(
                title: coordinator.isSubmitting ? "Verifying..." : "Verify",
                systemImage: coordinator.isSubmitting ? nil : "checkmark"
            ) {
                Task { await coordinator.submitOTP() }
            }
            .padding(.bottom, 36)
            .disabled(coordinator.isSubmitting || coordinator.otpCode.count < 6)
            .opacity(coordinator.otpCode.count < 6 ? 0.5 : 1)
        }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        OnboardingOTPView(coordinator: OnboardingCoordinator(onComplete: { _ in }))
            .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}
