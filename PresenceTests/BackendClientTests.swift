//  PresenceApp
//  BackendClientTests.swift
//  Created: 2026-04-26
//  Purpose: Verify status-code mapping, retry policy, and auth-header
//           injection in BackendClient using a URLProtocol stub.

import Foundation
import Testing
@testable import Presence

@Suite("BackendClient")
struct BackendClientTests {
    @Test("Decodes a 200 JSON response")
    func decodesSuccessResponse() async throws {
        let json = #"{"name":"Bluestone","type":"cafe"}"#.data(using: .utf8)!
        let session = StubURLProtocol.makeSession(responder: { _ in
            (HTTPURLResponse.ok, json)
        })
        let client = BackendClient(
            baseURL: URL(string: "https://api.test")!,
            authProvider: StaticTokenProvider(token: "abc"),
            session: session,
            maxRetries: 0
        )
        let venue: Venue = try await client.get(.health)
        #expect(venue.name == "Bluestone")
        #expect(venue.type == "cafe")
    }

    @Test("Maps 401 to .unauthorized")
    func unauthorizedMapping() async {
        let session = StubURLProtocol.makeSession(responder: { _ in
            (HTTPURLResponse.status(401), Data())
        })
        let client = BackendClient(
            baseURL: URL(string: "https://api.test")!,
            authProvider: StaticTokenProvider(token: "t"),
            session: session,
            maxRetries: 0
        )
        var captured: BackendError?
        do {
            let _: Venue = try await client.get(.health)
        } catch let error as BackendError {
            captured = error
        } catch {}
        #expect(captured == .unauthorized)
    }

    @Test("Maps 402 with free_limit payload")
    func freeLimitMapping() async throws {
        let payload = #"{"weeklyUsed":3,"resetsAt":"2026-05-01T00:00:00Z"}"#.data(using: .utf8)!
        let session = StubURLProtocol.makeSession(responder: { _ in
            (HTTPURLResponse.status(402), payload)
        })
        let client = BackendClient(
            baseURL: URL(string: "https://api.test")!,
            authProvider: StaticTokenProvider(token: "t"),
            session: session,
            maxRetries: 0
        )
        var captured: BackendError?
        do {
            let _: Venue = try await client.get(.health)
        } catch let error as BackendError {
            captured = error
        } catch {}
        guard case let .freeLimitReached(used, resetsAt) = captured else {
            Issue.record("Expected freeLimitReached, got \(String(describing: captured))")
            return
        }
        #expect(used == 3)
        #expect(resetsAt != nil)
    }

    @Test("Maps 429 to .rateLimited and reads Retry-After")
    func rateLimitMapping() async {
        let session = StubURLProtocol.makeSession(responder: { _ in
            (HTTPURLResponse.status(429, headers: ["Retry-After": "12"]), Data())
        })
        let client = BackendClient(
            baseURL: URL(string: "https://api.test")!,
            authProvider: StaticTokenProvider(token: "t"),
            session: session,
            maxRetries: 0
        )
        var captured: BackendError?
        do {
            let _: Venue = try await client.get(.health)
        } catch let error as BackendError {
            captured = error
        } catch {}
        guard case let .rateLimited(retryAfter) = captured else {
            Issue.record("Expected rateLimited, got \(String(describing: captured))")
            return
        }
        #expect(retryAfter == 12)
    }

    @Test("Retries on 500 then succeeds")
    func retriesOn500() async throws {
        let attempts = AttemptCounter()
        let json = #"{"name":"Park","type":"park"}"#.data(using: .utf8)!
        let session = StubURLProtocol.makeSession(responder: { _ in
            let n = attempts.bump()
            if n < 3 {
                return (HTTPURLResponse.status(500), Data())
            }
            return (HTTPURLResponse.ok, json)
        })
        let client = BackendClient(
            baseURL: URL(string: "https://api.test")!,
            authProvider: StaticTokenProvider(token: "t"),
            session: session,
            maxRetries: 3
        )
        let venue: Venue = try await client.get(.health)
        #expect(venue.name == "Park")
        #expect(attempts.value == 3)
    }

    @Test("Attaches Bearer token when auth provider supplies one")
    func attachesAuthHeader() async throws {
        let observed = HeaderObserver()
        let json = #"{"name":"x","type":"cafe"}"#.data(using: .utf8)!
        let session = StubURLProtocol.makeSession(responder: { request in
            observed.set(request.value(forHTTPHeaderField: "Authorization"))
            return (HTTPURLResponse.ok, json)
        })
        let client = BackendClient(
            baseURL: URL(string: "https://api.test")!,
            authProvider: StaticTokenProvider(token: "tok-123"),
            session: session,
            maxRetries: 0
        )
        let _: Venue = try await client.get(.icebreaker())
        #expect(observed.value == "Bearer tok-123")
    }

    @Test("Throws unauthorized when an auth-required endpoint has no token")
    func failsWithoutToken() async {
        let session = StubURLProtocol.makeSession(responder: { _ in
            (HTTPURLResponse.ok, Data())
        })
        let client = BackendClient(
            baseURL: URL(string: "https://api.test")!,
            authProvider: StaticTokenProvider(token: nil),
            session: session,
            maxRetries: 0
        )
        var captured: BackendError?
        do {
            let _: Venue = try await client.get(.icebreaker())
        } catch let error as BackendError {
            captured = error
        } catch {}
        #expect(captured == .unauthorized)
    }

    // MARK: - Fixtures

    /// Minimal Codable response used by the tests above.
    struct Venue: Codable, Equatable {
        let name: String
        let type: String
    }
}

// MARK: - URLProtocol stub

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Responder = @Sendable (URLRequest) -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var responder: Responder?

    static func makeSession(responder: @escaping Responder) -> URLSession {
        lock.lock()
        Self.responder = responder
        lock.unlock()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        let responder = Self.responder
        Self.lock.unlock()
        guard let responder else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (response, data) = responder(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Test helpers

private struct StaticTokenProvider: BackendAuthProvider {
    let token: String?
    func currentAccessToken() async -> String? { token }
}

/// Thread-safe counter for tracking retry attempts.
private final class AttemptCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return _value }
    func bump() -> Int {
        lock.lock(); defer { lock.unlock() }
        _value += 1
        return _value
    }
}

private final class HeaderObserver: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String?
    var value: String? { lock.lock(); defer { lock.unlock() }; return _value }
    func set(_ v: String?) { lock.lock(); _value = v; lock.unlock() }
}

private extension HTTPURLResponse {
    static let url = URL(string: "https://api.test/health")!

    static var ok: HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
    }

    static func status(_ code: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: code, httpVersion: "HTTP/1.1", headerFields: headers)!
    }
}
