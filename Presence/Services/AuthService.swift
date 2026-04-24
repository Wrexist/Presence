//  PresenceApp
//  AuthService.swift
//  Created: 2026-04-24
//  Purpose: Phone-OTP auth. STUB. Accepts any phone, any 6-digit OTP, any
//           username, and returns a local User. Sprint 1 swaps this for a
//           real implementation backed by Supabase Auth (phone provider).

import Foundation

enum AuthError: Error, LocalizedError {
    case invalidPhone
    case invalidOTP
    case invalidUsername
    case usernameTaken

    var errorDescription: String? {
        switch self {
        case .invalidPhone:    return "Please enter a valid phone number."
        case .invalidOTP:      return "That code isn't right. Try again?"
        case .invalidUsername: return "Username must be 3–24 characters, letters/numbers/underscore."
        case .usernameTaken:   return "That username is taken."
        }
    }
}

actor AuthService {
    // MARK: - Phone + OTP

    func sendOTP(to phoneE164: String) async throws {
        guard Self.isValidE164(phoneE164) else { throw AuthError.invalidPhone }
        // Network latency placeholder so the UI gets a realistic feel.
        try await Task.sleep(nanoseconds: 600_000_000)
        // TODO(sprint-1): call Supabase.auth.signInWithOtp(phone:)
    }

    func verifyOTP(_ code: String, for phoneE164: String) async throws {
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw AuthError.invalidOTP
        }
        try await Task.sleep(nanoseconds: 500_000_000)
        // TODO(sprint-1): call Supabase.auth.verifyOTP(...)
    }

    // MARK: - Profile

    func claimUsername(_ username: String, bio: String?) async throws -> User {
        guard Self.isValidUsername(username) else { throw AuthError.invalidUsername }
        try await Task.sleep(nanoseconds: 400_000_000)
        // TODO(sprint-1): INSERT INTO users (...) RETURNING *
        return User(
            id: UUID(),
            username: username,
            bio: bio?.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarURL: nil,
            createdAt: Date()
        )
    }

    // MARK: - Validators

    static func isValidE164(_ s: String) -> Bool {
        // Permissive: + followed by 8–15 digits.
        let pattern = #"^\+[1-9]\d{7,14}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidUsername(_ s: String) -> Bool {
        let lowered = s.lowercased()
        let pattern = #"^[a-z0-9_]{3,24}$"#
        return lowered.range(of: pattern, options: .regularExpression) != nil
    }
}
