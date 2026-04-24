//  PresenceApp
//  JourneyView.swift
//  Created: 2026-04-24
//  Purpose: "Your journey" tab. Stats grid (connections, waves, time
//           glowing), a seven-day activity bar chart, and milestone
//           celebration hook. Matches the fourth panel of Design_2.

import SwiftUI

struct JourneyView: View {
    // Preview data. Replace with a real JourneyViewModel in Sprint 2.
    private let connections = 24
    private let waves = 37
    private let timeGlowing = "4d 45m"
    private let activity: [Int] = [2, 5, 3, 7, 4, 6, 8]
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

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
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your journey")
                .font(Typography.display)
            Text("You showed up.")
                .font(Typography.callout)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
        }
        .padding(.top, 8)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(value: "\(connections)", label: "Connections", color: PresenceColors.auroraViolet)
            statCard(value: "\(waves)", label: "Waves", color: PresenceColors.auroraPink)
            statCard(value: timeGlowing, label: "Glowing", color: PresenceColors.auroraAmber)
        }
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
                    Text("Presence activity")
                        .font(Typography.headline)
                    Spacer()
                    GlassChip(text: "last 7 days")
                }

                GeometryReader { proxy in
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(Array(activity.enumerated()), id: \.offset) { index, value in
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
                                        width: (proxy.size.width - 10 * 6) / 7,
                                        height: barHeight(for: value, available: proxy.size.height - 22)
                                    )
                                Text(dayLabels[index])
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

    private func barHeight(for value: Int, available: CGFloat) -> CGFloat {
        let maxValue = max(1, activity.max() ?? 1)
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(8, available * ratio)
    }

    // MARK: - Milestone

    private var milestoneCard: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 14) {
                LumaView(state: .celebrating, size: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next milestone")
                        .font(Typography.footnote)
                        .textCase(.uppercase)
                        .foregroundStyle(PresenceColors.auroraAmber)
                    Text("25 connections")
                        .font(Typography.headline)
                    Text("One more and Luma gets a little brighter.")
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    JourneyView()
        .preferredColorScheme(.dark)
}
