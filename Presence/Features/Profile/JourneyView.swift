//  PresenceApp
//  JourneyView.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — driven by ProfileViewModel.journey + 7-day buckets
//                        from /api/users/me/journey.
//  Purpose: "Your journey" tab. Connections / waves / time-glowing stats,
//           a real 7-day activity bar chart, and a milestone hint.

import SwiftUI

struct JourneyView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    private var journey: Journey? { services.profileViewModel.journey }

    var body: some View {
        ZStack {
            PresenceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    statsGrid

                    activityCard

                    milestoneCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
                .foregroundStyle(PresenceColors.presenceWhite)
            }
            .refreshable {
                await services.profileViewModel.refreshJourney()
            }
        }
        .task {
            if journey == nil { await services.profileViewModel.refreshJourney() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your journey").font(Typography.display)
            Text("You showed up.")
                .font(Typography.callout)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
        }
        .padding(.top, 8)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(
                value: "\(journey?.connectionCount ?? 0)",
                label: "Connections",
                color: PresenceColors.auroraViolet
            )
            statCard(
                value: "\(journey?.wavesSentCount ?? 0)",
                label: "Waves",
                color: PresenceColors.auroraPink
            )
            statCard(
                value: glowingLabel,
                label: "Glowing",
                color: PresenceColors.auroraAmber
            )
        }
    }

    private var glowingLabel: String {
        let seconds = journey?.glowingSeconds ?? 0
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        if hours == 0 { return "\(mins)m" }
        let days = hours / 24
        if days == 0 { return "\(hours)h \(mins)m" }
        return "\(days)d \(hours % 24)h"
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Circle()
                    .fill(color.opacity(0.9))
                    .frame(width: 10, height: 10)
                    .shadow(color: color.opacity(0.7), radius: 6)
                Text(value)
                    .font(Typography.title)
                    .foregroundStyle(PresenceColors.presenceWhite)
                Text(label)
                    .font(Typography.footnote)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Activity

    private var activityCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Presence activity").font(Typography.headline)
                    Spacer()
                    GlassChip(text: "last 7 days")
                }

                let activity = journey?.activity ?? []
                let maxValue = max(1, activity.map(\.count).max() ?? 1)

                GeometryReader { proxy in
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(activity) { bucket in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                PresenceColors.auroraPink,
                                                PresenceColors.auroraViolet
                                            ],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                    .frame(
                                        width: barWidth(in: proxy.size.width, count: max(1, activity.count)),
                                        height: barHeight(
                                            for: bucket.count,
                                            max: maxValue,
                                            available: proxy.size.height - 22
                                        )
                                    )
                                Text(dayLabel(bucket.day))
                                    .font(Typography.footnote)
                                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                            }
                        }
                    }
                }
                .frame(height: 140)
            }
        }
    }

    private func barWidth(in available: CGFloat, count: Int) -> CGFloat {
        let spacing: CGFloat = 10 * CGFloat(max(0, count - 1))
        return max(8, (available - spacing) / CGFloat(count))
    }

    private func barHeight(for value: Int, max maxValue: Int, available: CGFloat) -> CGFloat {
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(8, available * ratio)
    }

    private func dayLabel(_ ymd: String) -> String {
        // YYYY-MM-DD → first letter of weekday
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: ymd) else { return "·" }
        let g = DateFormatter()
        g.dateFormat = "EEEEE"
        return g.string(from: date)
    }

    // MARK: - Milestone

    private var milestoneCard: some View {
        let count = journey?.connectionCount ?? 0
        let next = nextMilestone(after: count)

        return GlassCard(cornerRadius: 24) {
            HStack(spacing: 14) {
                LumaView(state: .celebrating, size: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next milestone")
                        .font(Typography.footnote)
                        .textCase(.uppercase)
                        .foregroundStyle(PresenceColors.auroraAmber)
                    Text("\(next) connections")
                        .font(Typography.headline)
                    Text(milestoneCopy(remaining: next - count))
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func nextMilestone(after count: Int) -> Int {
        for milestone in [1, 5, 10, 25, 50, 100, 250] where milestone > count {
            return milestone
        }
        return ((count / 100) + 1) * 100
    }

    private func milestoneCopy(remaining: Int) -> String {
        if remaining <= 0 {
            return "You hit it. Onto the next."
        } else if remaining == 1 {
            return "One more and Luma gets a little brighter."
        }
        return "\(remaining) to go."
    }
}

#Preview {
    JourneyView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
