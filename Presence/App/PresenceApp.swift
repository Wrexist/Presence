//  PresenceApp
//  PresenceApp.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — boot calls AuthService.restoreSession before routing.
//  Purpose: App entry point. Wires ServiceContainer, AppCoordinator, and
//           the root tab shell with modal presentation.

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
                .task {
                    await coordinator.boot(auth: services.auth)
                }
        }
    }
}

private struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    var body: some View {
        @Bindable var bindable = coordinator

        ZStack {
            switch coordinator.route {
            case .launching:
                LaunchView()
            case .onboarding:
                OnboardingView(auth: services.auth) { user in
                    coordinator.completeOnboarding(with: user)
                }
            case .main:
                MainTabShell()
            }
        }
        .sheet(item: $bindable.modal) { modal in
            modalView(for: modal)
        }
    }

    @ViewBuilder
    private func modalView(for modal: AppCoordinator.Modal) -> some View {
        switch modal {
        case .goPresent:
            GoPresentView()
                .presentationDetents([.large])
                .presentationBackground(.clear)
        case .wave(let wave):
            WaveReceivedView(wave: wave)
                .presentationDetents([.large])
                .presentationBackground(.clear)
        }
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            PresenceBackground()
            LumaView(state: .idle, size: 96)
        }
    }
}

private struct MainTabShell: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var bindable = coordinator

        ZStack(alignment: .bottom) {
            Group {
                switch coordinator.tab {
                case .map:     HomeView()
                case .waves:   WavesView()
                case .journey: JourneyView()
                case .profile: ProfileView()
                }
            }
            .transition(.opacity)

            GlassTabBar(
                selection: $bindable.tab,
                onGoPresent: { coordinator.present(.goPresent) }
            )
            .padding(.bottom, 12)
        }
    }
}
