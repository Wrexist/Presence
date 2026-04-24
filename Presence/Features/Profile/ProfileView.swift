//  PresenceApp
//  ProfileView.swift
//  Created: 2026-04-24
//  Purpose: Your own profile — username, bio, Luma avatar, connection
//           count, and links into settings/privacy/subscription.

import SwiftUI

struct ProfileView: View {
    private let username = "morningfern"
    private let bio = "loves coffee mornings"
    private let connections = 24
    private let memberSince = "April 2026"

    var body: some View {
        ZStack {
            PresenceBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    GlassCard(cornerRadius: 28) {
                        VStack(spacing: 14) {
                            LumaView(state: .idle, size: 140)
                                .padding(.top, 8)
                            Text("@\(username)")
                                .font(Typography.title)
                            Text(bio)
                                .font(Typography.callout)
                                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))

                            HStack(spacing: 24) {
                                stat(label: "Connections", value: "\(connections)")
                                Rectangle()
                                    .fill(PresenceColors.presenceWhite.opacity(0.15))
                                    .frame(width: 1, height: 32)
                                stat(label: "Member since", value: memberSince)
                            }
                            .padding(.top, 6)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    settingsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
                .foregroundStyle(PresenceColors.presenceWhite)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Profile")
                .font(Typography.display)
            Spacer()
            GlassIconButton(systemImage: "gearshape", accessibilityLabel: "Settings") {}
        }
        .padding(.top, 8)
    }

    private func stat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Typography.headline)
            Text(label)
                .font(Typography.footnote)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
        }
    }

    private var settingsList: some View {
        VStack(spacing: 10) {
            settingsRow(icon: "sparkles", title: "Presence+", subtitle: "Unlimited glowing", tint: PresenceColors.auroraAmber)
            settingsRow(icon: "lock.shield", title: "Privacy", subtitle: "Location, blocks, data export", tint: PresenceColors.auroraBlue)
            settingsRow(icon: "bell", title: "Notifications", subtitle: "Wave alerts, weekly summary", tint: PresenceColors.auroraPink)
            settingsRow(icon: "questionmark.circle", title: "Help & feedback", subtitle: "We read every message", tint: PresenceColors.auroraViolet)
        }
    }

    private func settingsRow(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        GlassCard(cornerRadius: 22) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.headline)
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
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
