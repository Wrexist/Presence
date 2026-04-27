//  PresenceApp
//  CelebrationView.swift
//  Created: 2026-04-26
//  Purpose: Fullscreen celebration shown when a wave becomes mutual.
//           Picks a milestone copy variant based on connectionCount
//           (1, 5, 10, 25). Tapping "Open chat" routes into ChatView;
//           "Done" dismisses back to the map.
//
//  Why fullscreen: this is the emotional payoff of the whole product.
//  The 256pt celebrating Luma + spectrum aurora are the brief from
//  CLAUDE.md § Luma's States and the original product spec.

import SwiftUI

struct CelebrationView: View {
    let otherUsername: String
    let connectionCount: Int?
    let chatRoomId: UUID?
    let chatEndsAt: Date?
    let onOpenChat: () -> Void

    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {
                Spacer()

                LumaView(state: .celebrating, size: 240)

                VStack(spacing: 8) {
                    Text(headline)
                        .font(Typography.display)
                        .multilineTextAlignment(.center)
                    Text(subhead)
                        .font(Typography.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                        .padding(.horizontal, 28)
                }

                if let milestoneCopy {
                    GlassChip(text: milestoneCopy, systemImage: "sparkles")
                        .padding(.top, 4)
                }

                Spacer()

                VStack(spacing: 12) {
                    if chatRoomId != nil {
                        GlassPillButton(title: "Open chat", systemImage: "bubble.left.and.bubble.right") {
                            onOpenChat()
                        }
                        .shadow(color: PresenceColors.auroraPink.opacity(0.5), radius: 22, y: 6)
                    }
                    Button("Done") {
                        coordinator.dismissModal()
                    }
                    .font(Typography.callout)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .padding(.top, 36)
            .foregroundStyle(PresenceColors.presenceWhite)
        }
    }

    // MARK: - Copy variants

    private var headline: String {
        if let count = connectionCount, count == 1 {
            return "First connection!"
        }
        return "You connected!"
    }

    private var subhead: String {
        "You and \(otherUsername) both waved. Time to say hi in person."
    }

    private var milestoneCopy: String? {
        guard let count = connectionCount else { return nil }
        switch count {
        case 1:  return "Your very first."
        case 5:  return "Five connections strong."
        case 10: return "Ten and counting."
        case 25: return "Twenty-five — Luma is proud."
        default: return nil
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    PresenceColors.auroraViolet.opacity(0.6),
                    PresenceColors.auroraPink.opacity(0.4),
                    PresenceColors.deepNight
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft radial glow behind Luma
            Circle()
                .fill(PresenceColors.auroraAmber.opacity(0.35))
                .frame(width: 420, height: 420)
                .blur(radius: 100)
                .offset(y: -120)
        }
    }
}

#Preview {
    CelebrationView(
        otherUsername: "Maya",
        connectionCount: 1,
        chatRoomId: UUID(),
        chatEndsAt: Date().addingTimeInterval(600),
        onOpenChat: {}
    )
    .environment(AppCoordinator())
    .preferredColorScheme(.dark)
}
