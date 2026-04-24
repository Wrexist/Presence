//  PresenceApp
//  GoPresentView.swift
//  Created: 2026-04-24
//  Purpose: "Ready to be present?" hero screen. Requests whenInUse location
//           permission on tap (first time only — subsequent taps use the
//           existing grant). If the user has denied, surfaces an alert
//           pointing to Settings.

import CoreLocation
import SwiftUI

struct GoPresentView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services
    @State private var isActivating = false
    @State private var showDeniedAlert = false

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
                }

                Spacer()

                VStack(spacing: 12) {
                    GlassPillButton(
                        title: isActivating ? "Stop glowing" : "Go Present",
                        systemImage: isActivating ? "moon.stars" : "sparkles"
                    ) {
                        Task { await handleGoPresent() }
                    }
                    .shadow(color: PresenceColors.auroraAmber.opacity(0.6), radius: 24, y: 8)

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

    private func handleGoPresent() async {
        if isActivating {
            services.location.stopUpdating()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                isActivating = false
            }
            return
        }

        let status = await services.location.requestWhenInUseAuthorization()
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            services.location.startUpdating()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                isActivating = true
            }
            // TODO(sprint-1): call PresenceService.activate() — persists via
            // backend, schedules 3h expiry, broadcasts over WebSocket.
        case .denied, .restricted:
            showDeniedAlert = true
        case .notDetermined:
            // Dialog dismissed without choice — just no-op.
            break
        @unknown default:
            break
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

#Preview {
    GoPresentView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
