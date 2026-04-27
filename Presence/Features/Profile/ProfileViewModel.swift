//  PresenceApp
//  ProfileViewModel.swift
//  Created: 2026-04-26
//  Purpose: Live state for ProfileView + JourneyView. Both screens read
//           the same `profile` so the connection count and weekly chip
//           stay in sync. Edit-username and edit-bio mutations PATCH
//           /api/users/me and update the cached value on success.

import Foundation
import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile?
    private(set) var journey: Journey?
    private(set) var isLoading: Bool = false
    private(set) var lastError: BackendError?

    private let backend: BackendClient

    init(backend: BackendClient) {
        self.backend = backend
    }

    // MARK: - Refresh

    func refreshProfile() async {
        do {
            let response: UserProfile = try await backend.get(.meProfile())
            self.profile = response
            self.lastError = nil
        } catch let error as BackendError {
            self.lastError = error
        } catch {
            self.lastError = .network(nil)
        }
    }

    func refreshJourney() async {
        do {
            let response: Journey = try await backend.get(.journey())
            self.journey = response
        } catch let error as BackendError {
            self.lastError = error
        } catch {
            self.lastError = .network(nil)
        }
    }

    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }
        // async let runs both refreshes in parallel without the
        // sending-closure friction TaskGroup.addTask hits when capturing
        // main-actor-isolated `self` under Swift 6 strict concurrency.
        async let profile: Void = refreshProfile()
        async let journey: Void = refreshJourney()
        _ = await (profile, journey)
    }

    // MARK: - Edit

    /// Returns nil on success, or a user-facing error message on failure.
    @discardableResult
    func updateBio(_ bio: String?) async -> String? {
        let trimmed = bio?.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = UpdateProfileRequest(username: nil, bio: trimmed)
        return await patch(body, applying: { profile in
            profile.bio = (trimmed?.isEmpty ?? true) ? nil : trimmed
        })
    }

    @discardableResult
    func updateUsername(_ username: String) async -> String? {
        let lowered = username.lowercased()
        guard AuthService.isValidUsername(lowered) else {
            return "Username must be 3–24 chars, lowercase, digits, or _."
        }
        let body = UpdateProfileRequest(username: lowered, bio: nil)
        return await patch(body, applying: { profile in
            profile.username = lowered
        })
    }

    private func patch(
        _ body: UpdateProfileRequest,
        applying transform: (inout UserProfile) -> Void
    ) async -> String? {
        struct PatchResponse: Decodable, Sendable {
            let id: UUID
            let username: String
            let bio: String?
        }
        do {
            let _: PatchResponse = try await backend.send(.updateProfile(), body: body)
            if var current = profile {
                transform(&current)
                self.profile = current
            }
            return nil
        } catch let error as BackendError {
            switch error {
            case .server(let status, _) where status == 409:
                return "That username is taken."
            case .invalidRequest:
                return "Invalid format. Try a different value."
            default:
                return "Couldn't save. Try again?"
            }
        } catch {
            return "Couldn't save. Try again?"
        }
    }

    // MARK: - Delete account

    /// Returns true on success. Caller is responsible for tearing down
    /// the session and routing to onboarding afterward.
    func deleteAccount() async -> Bool {
        do {
            _ = try await backend.sendVoid(.deleteAccount())
            return true
        } catch {
            return false
        }
    }

    // MARK: - Data export

    /// Returns the raw exported JSON Data, or nil on failure.
    func exportData() async -> Data? {
        struct ExportEnvelope: Decodable, Sendable {
            let exportedAt: Date
        }
        // Use sendRaw under the hood — we want the bytes, not a decoded
        // model. There's no need to validate envelope shape here.
        do {
            // Backend returns a JSON object; we round-trip it through the
            // client's send pipeline to inherit auth + retries, but ask
            // for `Data` by decoding into a transparent wrapper.
            struct AnyJSON: Decodable, Sendable {
                let raw: Data
                init(from decoder: Decoder) throws {
                    let container = try decoder.singleValueContainer()
                    // Re-serialize whatever shape lands.
                    let value = try container.decode(JSONValue.self)
                    self.raw = (try? JSONEncoder().encode(value)) ?? Data()
                }
            }
            let wrapper: AnyJSON = try await backend.get(.dataExport())
            return wrapper.raw
        } catch {
            return nil
        }
    }
}

// Tiny JSONValue type used by the export round-trip. Decodes any JSON
// shape and re-encodes it byte-faithful enough for save-to-Files.
private indirect enum JSONValue: Codable, Sendable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let v = try? c.decode(Bool.self) { self = .bool(v); return }
        if let v = try? c.decode(Double.self) { self = .number(v); return }
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode([JSONValue].self) { self = .array(v); return }
        if let v = try? c.decode([String: JSONValue].self) { self = .object(v); return }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
}
