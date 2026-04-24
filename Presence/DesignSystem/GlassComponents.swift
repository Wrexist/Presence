//  PresenceApp
//  GlassComponents.swift
//  Created: 2026-04-24
//  Purpose: Reusable Liquid Glass surfaces. iOS 26 uses .glassEffect();
//           older OS falls back to Material so previews render in any toolchain.

import SwiftUI

// MARK: - GlassCard

struct GlassCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let content: Content

    init(cornerRadius: CGFloat = GlassTokens.Radius.card,
         @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(GlassTokens.Padding.card)
            .glassSurface(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - GlassPillButton

struct GlassPillButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(Typography.headline)
            }
            .padding(GlassTokens.Padding.pill)
            .frame(minWidth: 180)
            .glassSurface(in: Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - GlassIconButton

struct GlassIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .padding(GlassTokens.Padding.iconButton)
                .glassSurface(in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - GlassBottomSheet

struct GlassBottomSheet<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.white.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .accessibilityHidden(true)

            content
                .padding(GlassTokens.Padding.sheet)
        }
        .frame(maxWidth: .infinity)
        .glassSurface(in: UnevenRoundedRectangle(
            topLeadingRadius: GlassTokens.Radius.sheet,
            topTrailingRadius: GlassTokens.Radius.sheet,
            style: .continuous
        ))
    }
}

// MARK: - GlassChip

struct GlassChip: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(text)
                .font(Typography.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassSurface(in: Capsule(style: .continuous), thin: true)
    }
}

// MARK: - Glass surface modifier
// Centralized so every component gates iOS 26 the same way and the fallback
// stays consistent. Reduce Transparency is handled by Material automatically.

private extension View {
    @ViewBuilder
    func glassSurface<S: Shape>(in shape: S, thin: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if thin {
                self.glassEffect(.thin, in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        } else {
            self.background(thin ? .thinMaterial : .regularMaterial, in: shape)
        }
    }
}

// MARK: - Previews

#Preview("Components — Dark") {
    ZStack {
        LinearGradient(
            colors: [PresenceColors.deepNight, PresenceColors.softMidnight],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 24) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bluestone Coffee")
                        .font(Typography.headline)
                    Text("3 people glowing here")
                        .font(Typography.caption)
                        .opacity(GlassTokens.Opacity.secondary)
                }
            }
            GlassPillButton(title: "Go Present", systemImage: "sparkles") {}
            HStack(spacing: 16) {
                GlassIconButton(systemImage: "location.fill",
                                accessibilityLabel: "Recenter map") {}
                GlassIconButton(systemImage: "person.fill",
                                accessibilityLabel: "Open profile") {}
            }
            GlassChip(text: "2h 41m left", systemImage: "clock")
        }
        .padding()
        .foregroundStyle(PresenceColors.presenceWhite)
    }
    .preferredColorScheme(.dark)
}

#Preview("Components — Light") {
    ZStack {
        Color(white: 0.93).ignoresSafeArea()
        VStack(spacing: 24) {
            GlassCard {
                Text("Light mode card")
                    .font(Typography.headline)
            }
            GlassPillButton(title: "Wave") {}
            GlassChip(text: "Live", systemImage: "dot.radiowaves.left.and.right")
        }
        .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Bottom Sheet") {
    ZStack(alignment: .bottom) {
        LinearGradient(
            colors: [PresenceColors.deepNight, PresenceColors.softMidnight],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()

        GlassBottomSheet {
            VStack(alignment: .leading, spacing: 12) {
                Text("@morningfern")
                    .font(Typography.headline)
                Text("loves coffee mornings")
                    .font(Typography.callout)
                    .opacity(GlassTokens.Opacity.secondary)
                Text("This place has the best oat milk for miles — have you tried their afternoon special yet?")
                    .font(Typography.body)
                    .padding(.top, 8)
                GlassPillButton(title: "Wave") {}
                    .padding(.top, 8)
            }
            .foregroundStyle(PresenceColors.presenceWhite)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Reduce Transparency") {
    ZStack {
        LinearGradient(
            colors: [PresenceColors.deepNight, PresenceColors.softMidnight],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()
        VStack(spacing: 20) {
            GlassCard { Text("Reduced transparency").font(Typography.headline) }
            GlassPillButton(title: "Go Present") {}
        }
        .padding()
        .foregroundStyle(PresenceColors.presenceWhite)
    }
    .environment(\.accessibilityReduceTransparency, true)
    .preferredColorScheme(.dark)
}
