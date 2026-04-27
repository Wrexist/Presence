//  PresenceApp
//  PaywallView.swift
//  Created: 2026-04-26
//  Purpose: The Plus upgrade screen. Triggered from PresenceService when a
//           free user attempts a 4th weekly Presence (server returns 402
//           free_limit). Hero excited Luma, glass feature chips, and a
//           segmented monthly / annual toggle.

import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var selectedPlan: Plan = .annual
    @State private var didLoadOfferings: Bool = false
    @State private var errorMessage: String?

    enum Plan: String, CaseIterable, Identifiable {
        case monthly, annual
        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 24) {
                    topBar

                    LumaView(state: .excited, size: 160)
                        .padding(.top, 8)

                    VStack(spacing: 6) {
                        Text("Glow without limits")
                            .font(Typography.display)
                            .multilineTextAlignment(.center)
                        Text("Unlimited Presences and richer icebreakers, on you when it matters.")
                            .font(Typography.callout)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                            .padding(.horizontal, 24)
                    }

                    featureChips

                    planSelector

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Typography.footnote)
                            .foregroundStyle(PresenceColors.auroraPink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    primaryCTA

                    secondaryLinks
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .foregroundStyle(PresenceColors.presenceWhite)
        }
        .task {
            services.subscription.configureIfNeeded()
            await services.subscription.refreshOfferings()
            didLoadOfferings = true
        }
    }

    // MARK: - Components

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    PresenceColors.auroraViolet.opacity(0.55),
                    PresenceColors.deepNight,
                    PresenceColors.softMidnight
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(PresenceColors.auroraAmber.opacity(0.2))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: -120, y: -200)
        }
    }

    private var topBar: some View {
        HStack {
            GlassIconButton(systemImage: "xmark", accessibilityLabel: "Close") {
                coordinator.dismissModal()
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var featureChips: some View {
        VStack(spacing: 10) {
            featureRow(icon: "infinity", text: "Unlimited Presences")
            featureRow(icon: "sparkles", text: "Enhanced icebreakers from Claude")
            featureRow(icon: "person.3", text: "See nearby count before glowing")
            featureRow(icon: "moon.stars", text: "Quiet Hours auto-presence")
            featureRow(icon: "paintbrush", text: "Seasonal Luma skins")
        }
        .padding(.horizontal, 4)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PresenceColors.auroraAmber)
                .frame(width: 22)
            Text(text)
                .font(Typography.callout)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PresenceColors.presenceWhite.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(PresenceColors.presenceWhite.opacity(0.08), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var planSelector: some View {
        let monthly = services.subscription.monthlyPackage
        let annual = services.subscription.annualPackage

        HStack(spacing: 12) {
            planTile(
                plan: .monthly,
                title: "Monthly",
                price: monthly?.localizedPriceString ?? "—",
                badge: nil,
                disabled: monthly == nil
            )
            planTile(
                plan: .annual,
                title: "Annual",
                price: annual?.localizedPriceString ?? "—",
                badge: "Save 40%",
                disabled: annual == nil
            )
        }
    }

    private func planTile(
        plan: Plan,
        title: String,
        price: String,
        badge: String?,
        disabled: Bool
    ) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(Typography.footnote)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(PresenceColors.auroraAmber.opacity(0.85))
                        )
                        .foregroundStyle(PresenceColors.deepNight)
                }
                Text(title)
                    .font(Typography.headline)
                Text(price)
                    .font(Typography.body)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        isSelected
                            ? PresenceColors.auroraBlue.opacity(0.25)
                            : PresenceColors.presenceWhite.opacity(0.06)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                isSelected
                                    ? PresenceColors.auroraBlue
                                    : PresenceColors.presenceWhite.opacity(0.1),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    private var primaryCTA: some View {
        GlassPillButton(
            title: services.subscription.isPurchasing ? "Processing..." : ctaTitle,
            systemImage: "sparkles"
        ) {
            Task { await purchase() }
        }
        .shadow(color: PresenceColors.auroraAmber.opacity(0.55), radius: 22, y: 6)
        .disabled(selectedPackage == nil || services.subscription.isPurchasing)
        .opacity(selectedPackage == nil ? 0.55 : 1)
    }

    private var ctaTitle: String {
        let pkg = selectedPackage
        let intro = pkg?.storeProduct.introductoryDiscount
        if intro?.paymentMode == .freeTrial {
            return "Start 7-day free trial"
        }
        return "Continue"
    }

    private var secondaryLinks: some View {
        VStack(spacing: 12) {
            Button("Restore purchases") {
                Task { await restore() }
            }
            .font(Typography.callout)
            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
            .buttonStyle(.plain)

            HStack(spacing: 16) {
                if let termsURL = URL(string: "https://app.presence.ios/terms") {
                    Link("Terms", destination: termsURL)
                }
                if let privacyURL = URL(string: "https://app.presence.ios/privacy") {
                    Link("Privacy", destination: privacyURL)
                }
            }
            .font(Typography.footnote)
            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
        }
    }

    // MARK: - Actions

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .monthly: return services.subscription.monthlyPackage
        case .annual:  return services.subscription.annualPackage
        }
    }

    private func purchase() async {
        errorMessage = nil
        guard let pkg = selectedPackage else { return }
        let success = await services.subscription.purchase(pkg)
        if success {
            await services.analytics.capture(.paywallPurchased(plan: selectedPlan.rawValue))
            try? await Task.sleep(nanoseconds: 500_000_000)
            coordinator.dismissModal()
        } else if let last = services.subscription.lastError {
            errorMessage = last
        }
    }

    private func restore() async {
        errorMessage = nil
        let restored = await services.subscription.restore()
        if restored {
            await services.analytics.capture(.paywallRestored)
            coordinator.dismissModal()
        } else {
            errorMessage = "No previous purchases found on this Apple ID."
        }
    }
}

#Preview {
    PaywallView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
