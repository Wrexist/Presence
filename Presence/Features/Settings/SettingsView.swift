//  PresenceApp
//  SettingsView.swift
//  Created: 2026-04-26
//  Purpose: Account / subscription / privacy / about / sign out / delete.
//           Pulls live profile state from the shared ProfileViewModel.

import SwiftUI

struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var isWorking = false

    private var profile: UserProfile? { services.profileViewModel.profile }

    var body: some View {
        ZStack {
            PresenceBackground()

            ScrollView {
                VStack(spacing: 18) {
                    topBar
                    accountCard
                    subscriptionCard
                    section("Privacy") {
                        row(icon: "lock.shield",
                            tint: PresenceColors.auroraBlue,
                            title: "Privacy & data",
                            subtitle: "Location, blocks, data export") {
                            coordinator.present(.privacy)
                        }
                    }
                    section("About") {
                        row(icon: "doc.text",
                            tint: PresenceColors.auroraViolet,
                            title: "Terms of Service",
                            subtitle: "What we promise each other") {
                            openURL("https://app.presence.ios/terms")
                        }
                        row(icon: "hand.raised",
                            tint: PresenceColors.auroraPink,
                            title: "Privacy Policy",
                            subtitle: "What we collect and why") {
                            openURL("https://app.presence.ios/privacy")
                        }
                    }
                    section("Account") {
                        row(icon: "rectangle.portrait.and.arrow.right",
                            tint: PresenceColors.auroraAmber,
                            title: "Sign out",
                            subtitle: "Stop glowing on this device") {
                            showSignOutConfirm = true
                        }
                        row(icon: "trash",
                            tint: PresenceColors.auroraPink,
                            title: "Delete account",
                            subtitle: "Permanently — can't be undone") {
                            showDeleteConfirm = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 64)
                .foregroundStyle(PresenceColors.presenceWhite)
            }
        }
        .task {
            if profile == nil { await services.profileViewModel.refreshProfile() }
        }
        .confirmationDialog(
            "Sign out of Presence?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) { Task { await signOut() } }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Delete account?",
            isPresented: $showDeleteConfirm
        ) {
            Button("Delete forever", role: .destructive) { Task { await deleteAccount() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your profile, presences, waves, and chat history will be permanently removed.")
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack {
            Text("Settings").font(Typography.display)
            Spacer()
            GlassIconButton(systemImage: "xmark", accessibilityLabel: "Close") {
                coordinator.dismissModal()
            }
        }
        .padding(.top, 8)
    }

    private var accountCard: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 14) {
                LumaView(state: .idle, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(profile?.username ?? "—")").font(Typography.headline)
                    Text(profile?.bio ?? "no bio yet")
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var subscriptionCard: some View {
        let isPlus = profile?.isPlus ?? services.subscription.state.isPlus
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(PresenceColors.auroraAmber.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: isPlus ? "sparkles" : "lock")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PresenceColors.auroraAmber)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPlus ? "Presence+" : "Upgrade to Presence+").font(Typography.headline)
                    Text(isPlus ? subscriptionLine : "Unlimited Presences and richer icebreakers")
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isPlus {
                    openURL("itms-apps://apps.apple.com/account/subscriptions")
                } else {
                    coordinator.dismissModal()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        coordinator.present(.paywall(.upsell))
                    }
                }
            }
        }
    }

    private var subscriptionLine: String {
        let expiry = services.subscription.state.expiresAt ?? profile?.plusExpiresAt
        if let expiry {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Renews \(formatter.string(from: expiry))"
        }
        return "Active"
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Typography.footnote)
                .textCase(.uppercase)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                .padding(.leading, 6)
            content()
        }
    }

    private func row(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            GlassCard(cornerRadius: 22) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(tint.opacity(0.2)).frame(width: 40, height: 40)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(tint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(Typography.headline)
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }

    // MARK: - Actions

    private func signOut() async {
        isWorking = true
        defer { isWorking = false }
        await services.subscription.signOut()
        await services.auth.signOut()
        coordinator.dismissModal()
        coordinator.resetToOnboarding()
    }

    private func deleteAccount() async {
        isWorking = true
        defer { isWorking = false }
        let success = await services.profileViewModel.deleteAccount()
        if success {
            await services.subscription.signOut()
            await services.auth.signOut()
            coordinator.dismissModal()
            coordinator.resetToOnboarding()
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}
