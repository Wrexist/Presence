//  PresenceApp
//  OnboardingCoordinator.swift
//  Created: 2026-04-24
//  Purpose: Drives the onboarding flow. Holds form state across steps,
//           dispatches auth calls to the AuthService stub, surfaces
//           in-flight and error state to the views.

import SwiftUI

@MainActor
@Observable
final class OnboardingCoordinator {
    // MARK: - Step

    private(set) var step: OnboardingStep = .welcome

    // MARK: - Form state

    var phoneCountryCode: String = "+1"
    var phoneNumber: String = ""
    var otpCode: String = ""
    var username: String = ""
    var bio: String = ""

    // MARK: - Async state

    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    // MARK: - Services + completion callback

    private let auth: AuthService
    private let onComplete: (User) -> Void
    private var savedUser: User?

    init(auth: AuthService, onComplete: @escaping (User) -> Void) {
        self.auth = auth
        self.onComplete = onComplete
    }

    // MARK: - Derived values

    var e164Phone: String {
        let digits = phoneNumber.filter(\.isNumber)
        return phoneCountryCode + digits
    }

    var bioWordCount: Int {
        bio.split { $0.isWhitespace }.count
    }

    // MARK: - Navigation

    func advanceFromWelcome() {
        go(.phone)
    }

    func restartPhoneEntry() {
        otpCode = ""
        go(.phone)
    }

    // MARK: - Actions

    func submitPhone() async {
        await perform {
            try await self.auth.sendOTP(to: self.e164Phone)
            self.go(.otp)
        }
    }

    func submitOTP() async {
        await perform {
            try await self.auth.verifyOTP(self.otpCode, for: self.e164Phone)
            // Guard against a late completion landing after the user tapped
            // "Change number" — don't force the flow forward in that case.
            guard self.step == .otp else { return }
            self.go(.username)
        }
    }

    func submitUsername() async {
        await perform {
            // Local-only validation at this step — we only persist the user
            // after the bio is collected, to avoid a half-filled profile.
            guard AuthService.isValidUsername(self.username) else {
                throw AuthError.invalidUsername
            }
            self.go(.bio)
        }
    }

    func submitBio() async {
        await perform {
            let trimmed = self.bio.trimmingCharacters(in: .whitespacesAndNewlines)
            let savedBio = trimmed.isEmpty ? nil : trimmed
            self.savedUser = try await self.auth.claimUsername(self.username, bio: savedBio)
            self.go(.privacy)
        }
    }

    func advanceFromPrivacy() {
        go(.ready)
    }

    func finish() {
        // savedUser comes from AuthService.claimUsername in submitBio. If it's
        // nil we're in a weird test/preview path — fall through to the form
        // state so the app still gets something sensible.
        onComplete(
            savedUser ?? User(
                id: UUID(),
                username: username.isEmpty ? User.placeholder.username : username,
                bio: bio.isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarURL: nil,
                createdAt: Date()
            )
        )
    }

    // MARK: - Helpers

    private func go(_ next: OnboardingStep) {
        // Clear any previous error — step transitions should start clean,
        // otherwise an OTP error leaks onto the phone-entry screen etc.
        errorMessage = nil
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            step = next
        }
    }

    private func perform(_ action: @escaping () async throws -> Void) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await action()
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Try again?"
        }
    }
}
