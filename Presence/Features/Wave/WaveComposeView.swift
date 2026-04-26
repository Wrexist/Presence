//  PresenceApp
//  WaveComposeView.swift
//  Created: 2026-04-26
//  Purpose: Sender-side bottom sheet shown when the user taps a glowing
//           dot on the map. Loads an icebreaker via /api/icebreaker
//           (Luma in .connecting while waiting), then sends the wave via
//           POST /api/waves. Permission for push notifications is
//           requested HERE (lazy) — first wave triggers the system prompt
//           so the receiver-side flow can deliver waves later.

import SwiftUI

struct WaveComposeView: View {
    let target: PresentUser

    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var icebreaker: String?
    @State private var icebreakerSource: IcebreakerResponse.Source?
    @State private var isSending = false
    @State private var didSend = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            PresenceBackground()

            VStack(spacing: 22) {
                topBar
                Spacer(minLength: 4)

                Text("Wave at \(target.username)")
                    .font(Typography.callout)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))

                avatar

                VStack(spacing: 4) {
                    Text(target.username)
                        .font(Typography.title)
                    if let bio = target.bio, !bio.isEmpty {
                        Text(bio)
                            .font(Typography.caption)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    }
                    if let venue = target.venueName {
                        Text(venue)
                            .font(Typography.footnote)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                    }
                }

                icebreakerCard

                if let errorMessage {
                    Text(errorMessage)
                        .font(Typography.footnote)
                        .foregroundStyle(PresenceColors.auroraPink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                ctaStack
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .foregroundStyle(PresenceColors.presenceWhite)
        }
        .task {
            await loadIcebreaker()
            // Best-effort — we ask for push permission while the user is
            // already focused on a wave-related action, not at onboarding.
            await services.notifications.requestAuthorization()
        }
    }

    // MARK: - Components

    private var topBar: some View {
        HStack {
            GlassIconButton(systemImage: "chevron.down", accessibilityLabel: "Dismiss") {
                coordinator.dismissModal()
            }
            Spacer()
            GlassIconButton(systemImage: "flag", accessibilityLabel: "Block or report") {
                coordinator.dismissModal()
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    coordinator.present(.safety(.init(
                        userId: target.userId,
                        username: target.username,
                        context: .presence
                    )))
                }
            }
        }
        .padding(.top, 8)
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            PresenceColors.dotColor(for: target.id.uuidString).opacity(0.75),
                            PresenceColors.auroraViolet.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 8)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            PresenceColors.Luma.lavender,
                            PresenceColors.Luma.peach
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
                .overlay(
                    Text(target.username.prefix(1).uppercased())
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .foregroundStyle(PresenceColors.deepNight.opacity(0.75))
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
        }
        .frame(height: 200)
    }

    private var icebreakerCard: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                    Text("icebreaker")
                        .font(Typography.footnote)
                        .textCase(.uppercase)
                    Spacer()
                    if icebreakerSource == .fallback {
                        GlassChip(text: "local")
                    }
                }
                .foregroundStyle(PresenceColors.auroraAmber)

                if let icebreaker {
                    Text(icebreaker)
                        .font(Typography.body)
                        .foregroundStyle(PresenceColors.presenceWhite)
                        .transition(.opacity)
                } else {
                    HStack(spacing: 12) {
                        LumaView(state: .connecting, size: 36)
                        Text("Reading the room...")
                            .font(Typography.callout)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var ctaStack: some View {
        VStack(spacing: 10) {
            GlassPillButton(
                title: ctaTitle,
                systemImage: didSend ? "checkmark" : "hand.wave.fill"
            ) {
                Task { await sendWave() }
            }
            .shadow(color: PresenceColors.auroraPink.opacity(0.5), radius: 22, y: 6)
            .disabled(icebreaker == nil || isSending || didSend)
            .opacity(icebreaker == nil ? 0.55 : 1)

            Button("Not right now") {
                coordinator.dismissModal()
            }
            .font(Typography.callout)
            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            .buttonStyle(.plain)
        }
    }

    private var ctaTitle: String {
        if didSend { return "Wave sent" }
        if isSending { return "Sending..." }
        return "Wave 👋"
    }

    // MARK: - Actions

    private func loadIcebreaker() async {
        guard icebreaker == nil else { return }
        let request = buildIcebreakerRequest()
        do {
            let response: IcebreakerResponse = try await services.backend.send(
                .icebreaker(),
                body: request
            )
            withAnimation(.easeInOut(duration: 0.3)) {
                self.icebreaker = response.icebreaker
                self.icebreakerSource = response.source
            }
        } catch {
            // The fallback library is server-side — if even that fails (auth
            // expired, db down), surface a generic line so the user can
            // still wave. Better connection than no connection.
            withAnimation(.easeInOut(duration: 0.3)) {
                self.icebreaker = "Hey — we're glowing in the same spot. Worth saying hi?"
                self.icebreakerSource = .fallback
            }
        }
    }

    private func sendWave() async {
        guard let icebreaker, !isSending, !didSend else { return }
        isSending = true
        defer { isSending = false }
        errorMessage = nil

        let body = SendWaveRequest(receiverId: target.userId, icebreaker: icebreaker)
        do {
            let _: SendWaveResponse = try await services.backend.send(.sendWave(), body: body)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                didSend = true
            }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            coordinator.dismissModal()
        } catch let error as BackendError {
            errorMessage = userFacing(error)
        } catch {
            errorMessage = "Couldn't send. Try again?"
        }
    }

    private func userFacing(_ error: BackendError) -> String {
        switch error {
        case .forbidden:    return "You can't wave at this person."
        case .unauthorized: return "Sign in again to wave."
        case .network:      return "Network hiccup. Try again?"
        default:            return "Couldn't send. Try again?"
        }
    }

    private func buildIcebreakerRequest() -> IcebreakerRequest {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekdayIndex = calendar.component(.weekday, from: now)
        let days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let day = days[(weekdayIndex - 1 + 7) % 7]
        let isWeekend = weekdayIndex == 1 || weekdayIndex == 7

        return IcebreakerRequest(
            venue: .init(
                name: target.venueName ?? "this spot",
                type: "other",
                vibe: "social"
            ),
            timeContext: .init(hour: hour, dayOfWeek: day, isWeekend: isWeekend),
            userA: .init(
                bio: coordinator.currentUser?.bio ?? "open to meeting",
                connectionCount: 0
            ),
            userB: .init(
                bio: target.bio ?? "open to meeting",
                connectionCount: 0
            )
        )
    }
}

#Preview {
    WaveComposeView(target: PresentUser(
        id: UUID(),
        userId: UUID(),
        username: "Maya",
        bio: "morning coffee runs",
        lat: 37.77,
        lng: -122.42,
        venueName: "Bluestone Coffee · 4 min walk",
        expiresAt: Date().addingTimeInterval(3600)
    ))
    .environment(AppCoordinator())
    .environment(ServiceContainer.preview())
    .preferredColorScheme(.dark)
}
