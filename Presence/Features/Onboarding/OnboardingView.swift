//  PresenceApp
//  OnboardingView.swift
//  Created: 2026-04-24
//  Purpose: Root onboarding container. Shared backdrop + progress chip,
//           dispatches to the per-step view via the coordinator's state.

import SwiftUI

struct OnboardingView: View {
    @State private var coordinator: OnboardingCoordinator

    init(onComplete: @escaping (User) -> Void) {
        self._coordinator = State(initialValue: OnboardingCoordinator(onComplete: onComplete))
    }

    var body: some View {
        ZStack {
            PresenceBackground()

            VStack(spacing: 0) {
                progressHeader
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                Group {
                    switch coordinator.step {
                    case .welcome:   OnboardingWelcomeView(coordinator: coordinator)
                    case .phone:     OnboardingPhoneView(coordinator: coordinator)
                    case .otp:       OnboardingOTPView(coordinator: coordinator)
                    case .username:  OnboardingUsernameView(coordinator: coordinator)
                    case .bio:       OnboardingBioView(coordinator: coordinator)
                    case .privacy:   OnboardingPrivacyView(coordinator: coordinator)
                    case .ready:     OnboardingReadyView(coordinator: coordinator)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .foregroundStyle(PresenceColors.presenceWhite)
        }
    }

    // MARK: - Progress bar

    private var progressHeader: some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.self) { s in
                Capsule()
                    .fill(
                        s.rawValue <= coordinator.step.rawValue
                            ? PresenceColors.auroraBlue.opacity(0.9)
                            : PresenceColors.presenceWhite.opacity(0.18)
                    )
                    .frame(height: 3)
                    .animation(.easeOut(duration: 0.3), value: coordinator.step)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    OnboardingView { _ in }
        .preferredColorScheme(.dark)
}
