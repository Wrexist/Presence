//  PresenceApp
//  SafetySheet.swift
//  Created: 2026-04-26
//  Purpose: Block + report flow accessible from any user-to-user surface
//           (wave compose, wave received, chat). One-tap block; report
//           auto-blocks per backend rule. Per CLAUDE.md § Privacy
//           non-negotiables, this must be ≤2 taps from any user-to-user
//           screen.

import SwiftUI

struct SafetySheet: View {
    let target: Target
    let context: ReportRequest.Context
    let onComplete: (Outcome) -> Void

    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .menu
    @State private var pickedCategory: ReportRequest.Category?
    @State private var detail: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    /// Identifies the user this sheet acts on. We always need the user's
    /// id; username is for display copy.
    struct Target: Equatable {
        let userId: UUID
        let username: String
        let referenceId: UUID?  // wave id / chat room id when known
    }

    enum Outcome: Equatable {
        case blocked
        case reported
        case dismissed
    }

    private enum Mode: Equatable {
        case menu
        case report
    }

    var body: some View {
        ZStack {
            PresenceBackground()
            switch mode {
            case .menu:   menuView
            case .report: reportView
            }
        }
        .foregroundStyle(PresenceColors.presenceWhite)
    }

    // MARK: - Menu

    private var menuView: some View {
        VStack(spacing: 16) {
            handle

            Text("\(target.username)")
                .font(Typography.title)
                .padding(.top, 8)
            Text("What would you like to do?")
                .font(Typography.callout)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))

            Spacer(minLength: 8)

            actionRow(
                icon: "hand.raised.fill",
                tint: PresenceColors.auroraBlue,
                title: "Block",
                subtitle: "You won't see each other any more"
            ) {
                Task { await submitBlock() }
            }

            actionRow(
                icon: "flag.fill",
                tint: PresenceColors.auroraPink,
                title: "Report",
                subtitle: "Tell us what's wrong — we auto-block too"
            ) {
                mode = .report
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(Typography.footnote)
                    .foregroundStyle(PresenceColors.auroraPink)
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button("Cancel") {
                onComplete(.dismissed)
                dismiss()
            }
            .font(Typography.callout)
            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
            .buttonStyle(.plain)
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Report

    private var reportView: some View {
        VStack(spacing: 18) {
            handle

            HStack {
                Button {
                    mode = .menu
                    pickedCategory = nil
                    detail = ""
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
                Spacer()
            }

            Text("Report \(target.username)")
                .font(Typography.title)
            Text("Pick the closest match. We review every report.")
                .font(Typography.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                .padding(.horizontal, 24)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    ForEach(ReportRequest.Category.allCases, id: \.self) { category in
                        categoryChip(category)
                    }
                }
                .padding(.horizontal, 4)

                if pickedCategory == .other {
                    GlassTextField(
                        placeholder: "Tell us more (optional)",
                        text: $detail,
                        maxLength: 1000
                    )
                    .padding(.top, 10)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(Typography.footnote)
                    .foregroundStyle(PresenceColors.auroraPink)
            }

            GlassPillButton(
                title: isSubmitting ? "Sending..." : "Submit report",
                systemImage: "paperplane.fill"
            ) {
                Task { await submitReport() }
            }
            .disabled(pickedCategory == nil || isSubmitting)
            .opacity(pickedCategory == nil ? 0.55 : 1)
            .padding(.bottom, 28)
        }
        .padding(.horizontal, 20)
    }

    private func categoryChip(_ category: ReportRequest.Category) -> some View {
        let selected = pickedCategory == category
        return Button {
            pickedCategory = category
        } label: {
            Text(category.label)
                .font(Typography.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            selected
                                ? PresenceColors.auroraPink.opacity(0.25)
                                : PresenceColors.presenceWhite.opacity(0.06)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    selected
                                        ? PresenceColors.auroraPink
                                        : PresenceColors.presenceWhite.opacity(0.1),
                                    lineWidth: 1.5
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Components

    private var handle: some View {
        Capsule()
            .fill(PresenceColors.presenceWhite.opacity(0.25))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
    }

    private func actionRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            GlassCard(cornerRadius: 22) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(tint.opacity(0.2)).frame(width: 44, height: 44)
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
        .disabled(isSubmitting)
    }

    // MARK: - Actions

    private func submitBlock() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            struct R: Decodable, Sendable { let ok: Bool? }
            let _: R = try await services.backend.send(
                .block(),
                body: BlockRequest(blockedId: target.userId)
            )
            onComplete(.blocked)
            dismiss()
        } catch {
            errorMessage = "Couldn't block. Try again?"
        }
    }

    private func submitReport() async {
        guard let category = pickedCategory, !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = ReportRequest(
            reportedId: target.userId,
            category: category,
            context: context,
            referenceId: target.referenceId,
            detail: trimmed.isEmpty ? nil : trimmed
        )
        do {
            struct R: Decodable, Sendable {
                let ok: Bool
                let autoBlocked: Bool
            }
            let _: R = try await services.backend.send(.report(), body: body)
            onComplete(.reported)
            dismiss()
        } catch {
            errorMessage = "Couldn't send report. Try again?"
        }
    }
}
