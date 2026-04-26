//  PresenceApp
//  BackendClient.swift
//  Created: 2026-04-26
//  Purpose: URLSession actor wrapping the Node backend. Handles auth header
//           injection, ISO8601 JSON encode/decode, and exponential-backoff
//           retries on 5xx + transient network failures.

import Foundation

/// Anything that can supply a current Supabase access token. AuthService
/// conforms; tests inject a stub.
protocol BackendAuthProvider: Sendable {
    func currentAccessToken() async -> String?
}

actor BackendClient {
    private let baseURL: URL
    private let session: URLSession
    private let authProvider: BackendAuthProvider
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let maxRetries: Int

    init(
        baseURL: URL,
        authProvider: BackendAuthProvider,
        session: URLSession = .shared,
        maxRetries: Int = 3
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authProvider = authProvider
        self.maxRetries = maxRetries

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Public API

    /// Convenience for endpoints that have no body and return a decoded value.
    func get<Response: Decodable & Sendable>(
        _ endpoint: BackendEndpoint,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let data = try await sendRaw(endpoint, body: Optional<EmptyBody>.none)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw BackendError.decode
        }
    }

    /// POST/PATCH/DELETE with an Encodable body. The body is omitted on DELETE.
    func send<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ endpoint: BackendEndpoint,
        body: Body?,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let data = try await sendRaw(endpoint, body: body)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw BackendError.decode
        }
    }

    /// Discardable, no-body variant when only the status code matters.
    @discardableResult
    func sendVoid(_ endpoint: BackendEndpoint) async throws -> Data {
        try await sendRaw(endpoint, body: Optional<EmptyBody>.none)
    }

    /// Discardable variant with a body — used for fire-and-forget POSTs.
    @discardableResult
    func sendVoid<Body: Encodable & Sendable>(
        _ endpoint: BackendEndpoint,
        body: Body
    ) async throws -> Data {
        try await sendRaw(endpoint, body: body)
    }

    // MARK: - Core request loop

    private func sendRaw<Body: Encodable & Sendable>(
        _ endpoint: BackendEndpoint,
        body: Body?
    ) async throws -> Data {
        let request = try await buildRequest(endpoint, body: body)
        var attempt = 0
        var lastError: BackendError?

        while attempt <= maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw BackendError.network(nil)
                }
                if http.statusCode < 300 {
                    return data
                }
                let mapped = mapStatus(http, body: data)
                if mapped.isRetryable, attempt < maxRetries {
                    let delay = retryDelay(for: attempt, retryAfter: retryAfter(from: http))
                    try await Task.sleep(nanoseconds: delay)
                    attempt += 1
                    lastError = mapped
                    continue
                }
                throw mapped
            } catch let error as BackendError {
                throw error
            } catch let urlError as URLError {
                let mapped = BackendError.network(urlError.code)
                if attempt < maxRetries, mapped.isRetryable {
                    let delay = retryDelay(for: attempt, retryAfter: nil)
                    try await Task.sleep(nanoseconds: delay)
                    attempt += 1
                    lastError = mapped
                    continue
                }
                throw mapped
            } catch {
                throw BackendError.network(nil)
            }
        }
        throw lastError ?? BackendError.network(nil)
    }

    private func buildRequest<Body: Encodable & Sendable>(
        _ endpoint: BackendEndpoint,
        body: Body?
    ) async throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        )
        if !endpoint.query.isEmpty {
            components?.queryItems = endpoint.query
        }
        guard let url = components?.url else {
            throw BackendError.invalidRequest("malformed url")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.method != .get && endpoint.method != .delete, let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }
        if endpoint.requiresAuth, let token = await authProvider.currentAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if endpoint.requiresAuth {
            throw BackendError.unauthorized
        }
        return request
    }

    // MARK: - Status mapping

    private func mapStatus(_ http: HTTPURLResponse, body: Data) -> BackendError {
        switch http.statusCode {
        case 401: return .unauthorized
        case 402:
            // 402 is reserved for the freemium gate; backend returns
            // {error: "free_limit", weeklyUsed: 3, resetsAt: ISO8601}.
            if let payload = try? decoder.decode(FreeLimitPayload.self, from: body) {
                return .freeLimitReached(weeklyUsed: payload.weeklyUsed, resetsAt: payload.resetsAt)
            }
            return .freeLimitReached(weeklyUsed: 0, resetsAt: nil)
        case 403: return .forbidden
        case 404: return .notFound
        case 429:
            return .rateLimited(retryAfter: retryAfter(from: http))
        case 500...599:
            let message = String(data: body, encoding: .utf8)
            return .server(status: http.statusCode, message: message)
        default:
            let message = String(data: body, encoding: .utf8)
            return .server(status: http.statusCode, message: message)
        }
    }

    private func retryAfter(from http: HTTPURLResponse) -> TimeInterval? {
        guard let header = http.value(forHTTPHeaderField: "Retry-After"),
              let seconds = TimeInterval(header) else { return nil }
        return seconds
    }

    /// 0.5s, 1s, 2s baseline; honor server's Retry-After if provided.
    private func retryDelay(for attempt: Int, retryAfter: TimeInterval?) -> UInt64 {
        if let retryAfter {
            return UInt64(retryAfter * 1_000_000_000)
        }
        let seconds = 0.5 * pow(2.0, Double(attempt))
        return UInt64(seconds * 1_000_000_000)
    }

    // MARK: - Helpers

    /// Body type for endpoints that take no body.
    struct EmptyBody: Encodable, Sendable {}

    private struct FreeLimitPayload: Decodable {
        let weeklyUsed: Int
        let resetsAt: Date?
    }
}
