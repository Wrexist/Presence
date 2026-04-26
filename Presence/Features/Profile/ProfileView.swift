//  PresenceApp
//  ProfileView.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — driven by ProfileViewModel; gear opens Settings.
//  Purpose: Your own profile — username, bio, Luma avatar, connection
//           count, weekly Plus chip, and entry to Settings.

import SwiftUI

struct ProfileView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var editTarget: EditTarget?
    @State private var editValue: String = ""
    @State private var editError: String?

    private var profile: UserProfile? { services.profileViewModel.profile }

    enum EditTarget: Identifiable {
        case username, bio
        var id: String {
            switch self {
            case .username: return "username"
            case .bio: return "bio"
            }
        }
    }

    var body: some View {
        ZStack {
            PresenceBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    profileCard

                    if let profile, !profile.isPlus {
                        weeklyChip(profile: profile)
                    }

                    settingsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
                .foregroundStyle(PresenceColors.presenceWhite)
            }
            .refreshable {
                await services.profileViewModel.refreshAll()
            }
        }
        .task {
            if profile == nil { await services.profileViewModel.refreshAll() }
        }
        .alert(
            editTarget == .username ? "Edit username" : "Edit bio",
            isPresented: Binding(
                get: { editTarget != nil },
                set: { if !$0 { editTarget = nil; editError = nil } }
            )
        ) {
            TextField(editTarget == .username ? "username" : "3-word bio", text: $editValue)
                .textInputAutocapitalization(.never)
            Button("Save") { Task { await saveEdit() } }
            Button("Cancel", role: .cancel) { editTarget = nil }
        } message: {
            if let editError {
                Text(editError)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Profile").font(Typography.display)
            Spacer()
            GlassIconButton(systemImage: "gearshape", accessibilityLabel: "Settings") {
                coordinator.present(.settings)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Profile card

    private var profileCard: some View {
        GlassCard(cornerRadius: 28) {
            VStack(spacing: 14) {
                LumaView(state: .idle, size: 140)
                    .padding(.top, 8)

                Button {
                    editValue = profile?.username ?? ""
                    editTarget = .username
                } label: {
                    HStack(spacing: 6) {
                        Text("@\(profile?.username ?? "—")")
                            .font(Typography.title)
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                    }
                }
                .buttonStyle(.plain)

                Button {
                    editValue = profile?.bio ?? ""
                    editTarget = .bio
                } label: {
                    Text(profile?.bio ?? "tap to add a 3-word bio")
                        .font(Typography.callout)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                .buttonStyle(.plain)

                HStack(spacing: 24) {
                    stat(label: "Connections", value: "\(profile?.connectionCount ?? 0)")
                    Rectangle()
                        .fill(PresenceColors.presenceWhite.opacity(0.15))
                        .frame(width: 1, height: 32)
                    stat(label: "Member since", value: memberSince)
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var memberSince: String {
        guard let date = profile?.createdAt else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    private func stat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Typography.headline)
            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
        }
    }

    // MARK: - Weekly chip

    private func weeklyChip(profile: UserProfile) -> some View {
        let used = profile.weeklyPresenceCount
        let remaining = max(0, 3 - used)
        return GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(PresenceColors.auroraAmber.opacity(0.2)).frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PresenceColors.auroraAmber)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(remaining > 0
                        ? "\(remaining) free Presences left this week"
                        : "Free Presences used up this week")
                        .font(Typography.headline)
                    Text("Resets \(weeklyResetCopy(profile.weeklyResetsAt))")
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer()
                Button("Upgrade") {
                    coordinator.present(.paywall(.upsell))
                }
                .font(Typography.footnote)
                .foregroundStyle(PresenceColors.auroraAmber)
                .buttonStyle(.plain)
            }
        }
    }

    private func weeklyResetCopy(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - Settings list

    private var settingsList: some View {
        VStack(spacing: 10) {
            settingsRow(
                icon: profile?.isPlus == true ? "sparkles" : "lock",
                title: profile?.isPlus == true ? "Manage Presence+" : "Upgrade to Presence+",
                subtitle: profile?.isPlus == true ? "Unlimited glowing" : "$6.99/mo or $49.99/yr",
                tint: PresenceColors.auroraAmber
            ) {
                if profile?.isPlus == true {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } else {
                    coordinator.present(.paywall(.upsell))
                }
            }
            settingsRow(
                icon: "lock.shield",
                title: "Privacy",
                subtitle: "Location, blocks, data export",
                tint: PresenceColors.auroraBlue
            ) {
                coordinator.present(.privacy)
            }
            settingsRow(
                icon: "gearshape",
                title: "Settings",
                subtitle: "Account, sign out, delete",
                tint: PresenceColors.auroraViolet
            ) {
                coordinator.present(.settings)
            }
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
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
    }

    // MARK: - Edit actions

    private func saveEdit() async {
        guard let target = editTarget else { return }
        editError = nil
        let trimmed = editValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let result: String?
        switch target {
        case .username: result = await services.profileViewModel.updateUsername(trimmed)
        case .bio:      result = await services.profileViewModel.updateBio(trimmed)
        }
        if let message = result {
            editError = message
        } else {
            editTarget = nil
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
