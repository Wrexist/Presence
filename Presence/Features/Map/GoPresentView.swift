//  PresenceApp
//  GoPresentView.swift
//  Created: 2026-04-24
//  Purpose: "Ready to be present?" hero screen. Centered Luma in excited
//           state, short value prop, and the Go Present primary CTA.
//           Matches the second panel of Design_2.

import SwiftUI

struct GoPresentView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var isActivating = false

    var body: some View {
        ZStack {
            PresenceBackground()

            VStack(spacing: 28) {
                dismissHandle

                Spacer()

                LumaView(state: isActivating ? .celebrating : .excited, size: 180)

                VStack(spacing: 10) {
                    Text("Ready to be present?")
                        .font(Typography.title)
                        .multilineTextAlignment(.center)
                    Text("Let others know you're open to a moment — for up to 3 hours.")
                        .font(Typography.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    GlassPillButton(
                        title: isActivating ? "You're glowing" : "Go Present",
                        systemImage: isActivating ? "checkmark" : "sparkles"
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            isActivating = true
                        }
                    }
                    .shadow(color: PresenceColors.auroraAmber.opacity(0.6), radius: 24, y: 8)

                    Button {
                        coordinator.dismissModal()
                    } label: {
                        Text("Not right now")
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
    }

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
        .preferredColorScheme(.dark)
}
