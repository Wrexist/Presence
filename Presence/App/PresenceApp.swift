//  PresenceApp
//  PresenceApp.swift
//  Created: 2026-04-24
//  Purpose: App entry point. Wires ServiceContainer, AppCoordinator, and root scene.

import SwiftUI

@main
struct PresenceApp: App {
    @State private var coordinator = AppCoordinator()
    @State private var services = ServiceContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
                .environment(services)
                .preferredColorScheme(.dark)
                .tint(PresenceColors.auroraBlue)
        }
    }
}

private struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PresenceColors.deepNight, PresenceColors.softMidnight],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            switch coordinator.route {
            case .onboarding:
                placeholder("Onboarding — coming next sprint")
            case .map:
                placeholder("Map — coming next sprint")
            }
        }
        .foregroundStyle(PresenceColors.presenceWhite)
    }

    private func placeholder(_ text: String) -> some View {
        VStack(spacing: 16) {
            Text("Presence").font(Typography.display)
            Text(text).font(Typography.callout).opacity(GlassTokens.Opacity.secondary)
            GlassPillButton(title: "Go Present", systemImage: "sparkles") {}
                .padding(.top, 24)
        }
        .padding()
    }
}
