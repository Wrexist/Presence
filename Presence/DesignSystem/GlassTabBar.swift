//  PresenceApp
//  GlassTabBar.swift
//  Created: 2026-04-24
//  Purpose: Floating glass tab bar. Four tabs plus a prominent "Go Present"
//           button that visually anchors the center — matches the tab-bar
//           aesthetic in Design_2.

import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case map, waves, journey, profile

    var systemImage: String {
        switch self {
        case .map:     return "map"
        case .waves:   return "hand.wave"
        case .journey: return "chart.bar"
        case .profile: return "person"
        }
    }

    var label: String {
        switch self {
        case .map:     return "Nearby"
        case .waves:   return "Waves"
        case .journey: return "Journey"
        case .profile: return "You"
        }
    }
}

struct GlassTabBar: View {
    @Binding var selection: AppTab
    let onGoPresent: () -> Void

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                tabItem(.map)
                tabItem(.waves)
                Color.clear.frame(width: 72)
                tabItem(.journey)
                tabItem(.profile)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.001))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .glassBar()

            goPresentButton
        }
        .padding(.horizontal, 16)
    }

    private func tabItem(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(tab.label)
                    .font(Typography.footnote)
            }
            .foregroundStyle(
                selection == tab
                    ? AnyShapeStyle(PresenceColors.presenceWhite)
                    : AnyShapeStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }

    private var goPresentButton: some View {
        Button(action: onGoPresent) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [PresenceColors.auroraAmber, PresenceColors.auroraPink],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: PresenceColors.auroraAmber.opacity(0.6), radius: 20, y: 6)

                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(PresenceColors.deepNight)
            }
            .offset(y: -14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Go Present")
    }
}

private extension View {
    @ViewBuilder
    func glassBar() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: Capsule(style: .continuous))
        } else {
            self.background(.regularMaterial, in: Capsule(style: .continuous))
        }
    }
}

#Preview {
    ZStack {
        PresenceBackground()
        VStack {
            Spacer()
            GlassTabBar(selection: .constant(.map), onGoPresent: {})
                .padding(.bottom, 16)
        }
    }
    .preferredColorScheme(.dark)
}
