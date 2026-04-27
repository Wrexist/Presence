//  PresenceApp
//  AuthService.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — replaced stub with real Supabase Auth.
//  Purpose: Phone-OTP auth backed by Supabase Auth (phone provider) and a
//           Keychain-stored session. Public surface kept stable so the
//           onboarding flow doesn't need to change shape.

import Auth
import Foundation
import PostgREST
import Supabase

enum AuthError: Error, LocalizedError, Equatable {
    case invalidPhone
    case invalidOTP
    case invalidUsername
    case usernameTaken
    case sessionMissing
    case network
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidPhone:    return "Please enter a valid phone number."
        case .invalidOTP:      return "That code isn't right. Try again?"
        case .invalidUsername: return "Username must be 3–24 characters, letters/numbers/underscore."
        case .usernameTaken:   return "That username is taken."
        case .sessionMissing:  return "Your session expired. Sign in again."
        case .network:         return "Network hiccup. Check your connection and try again?"
        case .server(let m):   return m
        }
    }
}

actor AuthService: BackendAuthProvider {
    private let client: SupabaseClient

    /// Mirrors `users.id` from the public schema. Populated after a
    /// successful `claimUsername` or session restore.
    private(set) var currentUser: User?

    init(client: SupabaseClient) {
        self.client = client
    }

    // MARK: - Session lifecycle

    /// Loads any persisted session and the matching `users` row. Call once
    /// at app launch before deciding whether to route to onboarding or main.
    func restoreSession() async -> User? {
        do {
            // `client.auth.session` throws if no session is persisted; we
            // treat that as a clean "logged out" state, not an error.
            let session = try await client.auth.session
            let user = try await fetchProfile(authUserID: session.user.id)
            self.currentUser = user
            return user
        } catch {
            return nil
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        currentUser = nil
    }

    /// Current Supabase access token, or nil if no session is persisted.
    /// Used by BackendClient to attach `Authorization: Bearer ...` headers.
    func currentAccessToken() async -> String? {
        do {
            let session = try await client.auth.session
            return session.accessToken
        } catch {
            return nil
        }
    }

    // MARK: - Phone + OTP

    func sendOTP(to phoneE164: String) async throws {
        guard Self.isValidE164(phoneE164) else { throw AuthError.invalidPhone }
        do {
            try await client.auth.signInWithOTP(phone: phoneE164)
        } catch {
            throw mapAuthError(error)
        }
    }

    func verifyOTP(_ code: String, for phoneE164: String) async throws {
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            throw AuthError.invalidOTP
        }
        do {
            try await client.auth.verifyOTP(phone: phoneE164, token: code, type: .sms)
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: - Profile

    /// Inserts (or fetches, if the row already exists) the public `users`
    /// row for the currently-authenticated session. The public users.id is
    /// kept in lockstep with the Supabase auth user id so RLS policies can
    /// match `auth.uid()` against `users.id`.
    func claimUsername(_ username: String, bio: String?) async throws -> User {
        guard Self.isValidUsername(username) else { throw AuthError.invalidUsername }
        let session: Session
        do {
            session = try await client.auth.session
        } catch {
            throw AuthError.sessionMissing
        }
        let trimmedBio = bio?.trimmingCharacters(in: .whitespacesAndNewlines)
        let row = NewUserRow(
            id: session.user.id,
            username: username.lowercased(),
            bio: (trimmedBio?.isEmpty ?? true) ? nil : trimmedBio
        )

        do {
            let inserted: User = try await client
                .from("users")
                .insert(row)
                .select()
                .single()
                .execute()
                .value
            self.currentUser = inserted
            return inserted
        } catch let error as PostgrestError {
            // Postgres unique-violation on username
            if error.code == "23505" {
                throw AuthError.usernameTaken
            }
            throw AuthError.server(error.message)
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: - Helpers

    private func fetchProfile(authUserID: UUID) async throws -> User {
        try await client
            .from("users")
            .select()
            .eq("id", value: authUserID)
            .single()
            .execute()
            .value
    }

    private func mapAuthError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .network
        }
        return .server(error.localizedDescription)
    }

    // MARK: - Validators (kept as statics for UI pre-checks)

    static func isValidE164(_ s: String) -> Bool {
        let pattern = #"^\+[1-9]\d{7,14}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidUsername(_ s: String) -> Bool {
        let lowered = s.lowercased()
        let pattern = #"^[a-z0-9_]{3,24}$"#
        return lowered.range(of: pattern, options: .regularExpression) != nil
    }

    /// Internal Codable shape for the insert. The DB defaults `created_at`
    /// and `avatar_url`; we only send the fields the user controls.
    private struct NewUserRow: Encodable {
        let id: UUID
        let username: String
        let bio: String?
    }
}
