//  PresenceApp
//  GoPresentView.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — wired to PresenceService (activate / deactivate +
//                        3h countdown chip).
//  Purpose: "Ready to be present?" hero screen. Requests whenInUse location
//           permission on tap (first time only — subsequent taps use the
//           existing grant). Activation persists via the backend, schedules
//           a 3-hour expiry, and surfaces a live countdown.

import CoreLocation
import SwiftUI

struct GoPresentView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services
    @State private var showDeniedAlert = false
    @State private var isRequesting = false
    @State private var errorMessage: String?

    private var isActivating: Bool { services.presence.isActive }

    var body: some View {
        ZStack {
            PresenceBackground()

            VStack(spacing: 28) {
                dismissHandle

                Spacer()

                LumaView(state: isActivating ? .celebrating : .excited, size: 180)

                VStack(spacing: 10) {
                    Text(isActivating ? "You're glowing" : "Ready to be present?")
                        .font(Typography.title)
                        .multilineTextAlignment(.center)
                    Text(
                        isActivating
                            ? "Nearby glowers can see your dot. Presence auto-expires in 3 hours."
                            : "Let others know you're open to a moment — for up to 3 hours."
                    )
                    .font(Typography.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    .padding(.horizontal, 24)

                    if let expiresAt = services.presence.expiresAt, isActivating {
                        ExpiryCountdownChip(expiresAt: expiresAt)
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .scale))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Typography.footnote)
                            .foregroundStyle(PresenceColors.auroraPink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 4)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    GlassPillButton(
                        title: buttonTitle,
                        systemImage: isActivating ? "moon.stars" : "sparkles"
                    ) {
                        Task { await handleGoPresent() }
                    }
                    .shadow(color: PresenceColors.auroraAmber.opacity(0.6), radius: 24, y: 8)
                    .disabled(isRequesting)
                    .opacity(isRequesting ? 0.6 : 1)

                    Button {
                        coordinator.dismissModal()
                    } label: {
                        Text(isActivating ? "Keep glowing, close" : "Not right now")
                            .font(Typography.callout)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .foregroundStyle(PresenceColors.presenceWhite)
        }
        .alert("Location permission needed", isPresented: $showDeniedAlert) {
            Button("Open Settings") { openAppSettings() }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Presence needs your location while you're glowing so nearby people can see your dot. It's never tracked in the background.")
        }
    }

    // MARK: - Actions

    private var buttonTitle: String {
        if isRequesting { return "Asking..." }
        return isActivating ? "Stop glowing" : "Go Present"
    }

    private func handleGoPresent() async {
        guard !isRequesting else { return }

        if isActivating {
            isRequesting = true
            services.location.stopUpdating()
            await services.presence.deactivate()
            isRequesting = false
            return
        }

        isRequesting = true
        defer { isRequesting = false }
        errorMessage = nil

        let status = await services.location.requestWhenInUseAuthorization()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            services.location.startUpdating()
            // Wait briefly for a first fix — the privacy-reduced helper
            // returns nil until the manager has at least one location.
            await waitForFirstFix()
            do {
                try await services.presence.activate()
            } catch let error as BackendError {
                if case let .freeLimitReached(weeklyUsed, resetsAt) = error {
                    // Hand off to the paywall instead of inlining an error.
                    coordinator.dismissModal()
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    coordinator.present(.paywall(.freeLimit(
                        weeklyUsed: weeklyUsed,
                        resetsAt: resetsAt
                    )))
                    return
                }
                errorMessage = userFacing(error)
            } catch {
                errorMessage = "Couldn't start glowing. Try again?"
            }
        case .denied, .restricted:
            showDeniedAlert = true
        case .notDetermined:
            // Dialog dismissed without choice — just no-op.
            break
        @unknown default:
            break
        }
    }

    private func waitForFirstFix() async {
        // Up to 3s for the first GPS fix; after that the user gets an
        // error message and can retry. Avoids a silent hang on startup.
        for _ in 0..<30 {
            if services.location.currentLocation != nil { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private func userFacing(_ error: BackendError) -> String {
        switch error {
        case .unauthorized: return "Sign in again to go present."
        case .freeLimitReached: return "You've hit this week's free limit. Upgrade for unlimited."
        case .invalidRequest: return "Couldn't read your location yet — try again in a moment."
        case .network: return "Network hiccup. Try again?"
        default: return "Couldn't start glowing. Try again?"
        }
    }

    private func openAppSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    // MARK: - Components

    private var dismissHandle: some View {
        HStack {
            GlassIconButton(
                systemImage: "xmark",
                accessibilityLabel: "Close"
            ) {
                coordinator.dismissModal()
            }
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Countdown chip

private struct ExpiryCountdownChip: View {
    let expiresAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, expiresAt.timeIntervalSince(context.date))
            GlassChip(text: "Glowing for " + format(remaining))
        }
    }

    private func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    GoPresentView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
