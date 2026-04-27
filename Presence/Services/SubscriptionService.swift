//  PresenceApp
//  SubscriptionService.swift
//  Created: 2026-04-26
//  Purpose: Wraps RevenueCat. Owns the Plus entitlement state, identifies
//           the user with their Supabase id post-auth, surfaces current
//           offerings to the paywall, and mirrors entitlement changes
//           back to the backend so server-side gates (e.g. /api/presence
//           402 free-limit) can honor the same source of truth.
//
//  Source-of-truth reality: RevenueCat is authoritative for what the user
//  *paid for*. The backend mirror exists so server routes can enforce
//  limits without trusting the client. A future RevenueCat webhook (E6)
//  will write that mirror directly; until then we sync from this service
//  on every entitlement change.

import Foundation
@preconcurrency import RevenueCat

@MainActor
@Observable
final class SubscriptionService {
    enum SubscriptionState: Sendable, Equatable {
        case unknown
        case free
        case plus(expiresAt: Date?)

        var isPlus: Bool {
            if case .plus = self { return true }
            return false
        }

        var expiresAt: Date? {
            if case .plus(let date) = self { return date }
            return nil
        }
    }

    /// The RevenueCat entitlement key. Mirrors the dashboard config in
    /// docs/backend-hosting.md / RevenueCat setup.
    static let entitlement = "presence_plus"

    private(set) var state: SubscriptionState = .unknown
    private(set) var offerings: Offerings?
    private(set) var lastError: String?
    private(set) var isPurchasing: Bool = false

    private let backend: BackendClient
    private var infoTask: Task<Void, Never>?
    private var hasConfigured = false

    init(backend: BackendClient) {
        self.backend = backend
    }

    // MARK: - Configure / identify

    /// Idempotent first-launch wiring. The API key may be empty in dev —
    /// in that case the service stays in `.unknown` and all paths no-op.
    func configureIfNeeded() {
        guard !hasConfigured else { return }
        let key = Config.revenueCatAPIKey
        guard !key.isEmpty else { return }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: key)
        hasConfigured = true
        startObserving()
    }

    /// Identify the RevenueCat user as our Supabase id. Call after auth
    /// completes. Safe to call on every launch — RevenueCat handles the
    /// "already identified" case.
    func identify(userId: UUID) async {
        configureIfNeeded()
        guard hasConfigured else { return }
        do {
            let (info, _) = try await Purchases.shared.logIn(userId.uuidString)
            await applyCustomerInfo(info)
            await refreshOfferings()
        } catch {
            lastError = (error as NSError).localizedDescription
        }
    }

    /// Sign-out hook — called from AppCoordinator.resetToOnboarding.
    func signOut() async {
        guard hasConfigured else { return }
        // logOut returns a CustomerInfo we deliberately discard — sign-out
        // doesn't care about the post-logout entitlement state.
        _ = try? await Purchases.shared.logOut()
        state = .unknown
    }

    // MARK: - Offerings

    func refreshOfferings() async {
        guard hasConfigured else { return }
        do {
            let result = try await Purchases.shared.offerings()
            offerings = result
        } catch {
            // Non-fatal — paywall surfaces "Couldn't load plans" if nil.
            lastError = (error as NSError).localizedDescription
        }
    }

    var monthlyPackage: Package? { offerings?.current?.monthly }
    var annualPackage: Package? { offerings?.current?.annual }

    // MARK: - Purchase

    func purchase(_ package: Package) async -> Bool {
        guard hasConfigured else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            await applyCustomerInfo(result.customerInfo)
            return state.isPlus
        } catch {
            lastError = (error as NSError).localizedDescription
            return false
        }
    }

    func restore() async -> Bool {
        guard hasConfigured else { return false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            await applyCustomerInfo(info)
            return state.isPlus
        } catch {
            lastError = (error as NSError).localizedDescription
            return false
        }
    }

    // MARK: - Observe customer info

    private func startObserving() {
        infoTask?.cancel()
        // Hop to a detached Task explicitly so the main actor stays free,
        // then bounce each customerInfo back onto MainActor for state
        // updates. The detach matters under Swift 6 strict concurrency:
        // CustomerInfo isn't Sendable, but @preconcurrency import RevenueCat
        // downgrades the warning, and applyCustomerInfo runs on MainActor.
        infoTask = Task.detached { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                if Task.isCancelled { break }
                await self?.applyCustomerInfo(info)
            }
        }
    }

    private func applyCustomerInfo(_ info: CustomerInfo) async {
        let entitlement = info.entitlements[Self.entitlement]
        let isActive = entitlement?.isActive == true
        let newState: SubscriptionState = isActive
            ? .plus(expiresAt: entitlement?.expirationDate)
            : .free

        let stateChanged = newState != state
        state = newState

        // Mirror to the backend on change so server gates honor this as
        // soon as the purchase clears.
        if stateChanged {
            await syncToBackend()
        }
    }

    private func syncToBackend() async {
        struct Body: Encodable, Sendable {
            let isPlus: Bool
            let expiresAt: Date?
        }
        let body = Body(isPlus: state.isPlus, expiresAt: state.expiresAt)
        do {
            try await backend.sendVoid(.syncSubscription(), body: body)
        } catch {
            // Non-fatal — next launch will retry via applyCustomerInfo.
        }
    }
}
