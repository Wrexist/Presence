//  PresenceApp
//  OnboardingStep.swift
//  Created: 2026-04-24
//  Purpose: Linear state machine for the onboarding flow.

enum OnboardingStep: Int, CaseIterable, Sendable {
    case welcome        // "You're not alone in feeling alone."
    case phone          // Phone number entry
    case otp            // 6-digit OTP verification
    case username       // Pick username
    case bio            // 3-word bio
    case privacy        // Privacy explanation (shield + Luma)
    case ready          // "When you're ready to glow, tap the button."

    var progress: Double {
        Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
}
