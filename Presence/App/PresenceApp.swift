//  PresenceApp
//  PresenceApp.swift
//  Created: 2026-04-24
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
        }
    }
}

private struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var bindable = coordinator

        ZStack {
            switch coordinator.route {
            case .onboarding:
                OnboardingView { user in
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
