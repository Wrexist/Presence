//  PresenceApp
//  PresenceApp.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — UIApplicationDelegateAdaptor for push device-token
//                        + notification-tap deep-linking.
//  Purpose: App entry point. Wires ServiceContainer, AppCoordinator,
//           AppDelegate, and the root tab shell with modal presentation.

import SwiftUI

@main
struct PresenceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

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
                    appDelegate.notifications = services.notifications
                    appDelegate.coordinator = coordinator
                    services.subscription.configureIfNeeded()
                    await services.notifications.refreshAuth()
                    await coordinator.boot(auth: services.auth)
                }
                .onChange(of: coordinator.route) { _, newRoute in
                    Task { @MainActor in
                        switch newRoute {
                        case .main:
                            await services.socket.connect()
                            await services.wavesViewModel.start()
                            if let userId = coordinator.currentUser?.id {
                                await services.subscription.identify(userId: userId)
                            }
                        case .onboarding:
                            await services.subscription.signOut()
                            services.wavesViewModel.stop()
                            services.socket.disconnect()
                        case .launching:
                            break
                        }
                    }
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
        case .waveReceived(let wave):
            WaveReceivedView(wave: wave, viewModel: services.wavesViewModel)
                .presentationDetents([.large])
                .presentationBackground(.clear)
        case .waveCompose(let target):
            WaveComposeView(target: target)
                .presentationDetents([.large])
                .presentationBackground(.clear)
        case .celebration(let context):
            CelebrationView(
                otherUsername: context.otherUsername,
                connectionCount: context.connectionCount,
                chatRoomId: context.chatRoomId,
                chatEndsAt: context.chatEndsAt,
                onOpenChat: {
                    guard let roomId = context.chatRoomId else { return }
                    let other = context.otherUsername
                    // Dismiss celebration, then re-present as chat after a
                    // brief beat so SwiftUI animates a clean swap rather
                    // than stacking two sheet transitions.
                    coordinator.dismissModal()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        coordinator.present(.chat(roomId: roomId, otherUsername: other))
                    }
                }
            )
            .presentationDetents([.large])
            .presentationBackground(.clear)
        case .chat(let roomId, let otherUsername):
            ChatView(roomId: roomId, otherUsername: otherUsername)
                .presentationDetents([.large])
                .presentationBackground(.clear)
        case .paywall:
            PaywallView()
                .presentationDetents([.large])
                .presentationBackground(.clear)
        case .safety(let ctx):
            SafetySheet(
                target: SafetySheet.Target(
                    userId: ctx.userId,
                    username: ctx.username,
                    referenceId: ctx.referenceId
                ),
                context: ctx.context,
                onComplete: { _ in }
            )
            .presentationDetents([.medium])
            .presentationBackground(.clear)
        case .settings:
            SettingsView()
                .presentationDetents([.large])
                .presentationBackground(.clear)
        case .privacy:
            PrivacyView()
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
    @Environment(ServiceContainer.self) private var services

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
        .onChange(of: coordinator.deepLink) { _, link in
            // Push-tap deep-links route here. We jump to the Waves tab so
            // the user lands somewhere the wave is visible — the WavesView
            // hydration surfaces the specific wave.
            guard let link else { return }
            switch link {
            case .waveReceived, .waveMutual:
                coordinator.tab = .waves
            }
            coordinator.consumeDeepLink()
        }
        // Celebration triggers globally — mutual events happen regardless
        // of which tab is on screen, so we listen at the shell level.
        .onChange(of: services.wavesViewModel.pendingMutual) { _, payload in
            guard let payload else { return }
            let me = coordinator.currentUser?.id
            let otherId = (payload.senderId == me) ? payload.receiverId : payload.senderId
            let knownWave = services.wavesViewModel.incoming.first(where: { $0.id == payload.waveId })
                ?? services.wavesViewModel.outgoing.first(where: { $0.id == payload.waveId })
            let username = knownWave?.other?.username
                ?? (knownWave?.other?.id == otherId ? knownWave?.other?.username : nil)
                ?? "Someone"

            coordinator.present(.celebration(.init(
                waveId: payload.waveId,
                otherUsername: username,
                connectionCount: payload.connectionCount,
                chatRoomId: payload.chatRoomId,
                chatEndsAt: payload.chatEndsAt
            )))
            services.wavesViewModel.pendingMutual = nil
        }
    }
}
