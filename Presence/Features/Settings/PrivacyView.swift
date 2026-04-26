//  PresenceApp
//  PrivacyView.swift
//  Created: 2026-04-26
//  Purpose: Privacy explainer + blocked-users list + GDPR/CCPA data
//           export. Surfaced from Settings.

import SwiftUI
import UniformTypeIdentifiers

struct PrivacyView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var blocks: [BlockedUser] = []
    @State private var isLoadingBlocks: Bool = false
    @State private var exportShareItem: ShareItem?
    @State private var isExporting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            PresenceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topBar

                    explainerCard

                    blockedSection

                    dataExportSection

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Typography.footnote)
                            .foregroundStyle(PresenceColors.auroraPink)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 64)
                .foregroundStyle(PresenceColors.presenceWhite)
            }
        }
        .task {
            await loadBlocks()
        }
        .sheet(item: $exportShareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack {
            Text("Privacy & data").font(Typography.title)
            Spacer()
            GlassIconButton(systemImage: "xmark", accessibilityLabel: "Close") {
                coordinator.dismissModal()
            }
        }
        .padding(.top, 8)
    }

    private var explainerCard: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Location", systemImage: "location")
                    .font(Typography.headline)
                    .foregroundStyle(PresenceColors.auroraBlue)
                Text("Your location is collected only when you're glowing — never in the background. Coordinates are reduced by ~50m before they leave your device, and active presences expire automatically after 3 hours.")
                    .font(Typography.caption)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))

                Divider().background(PresenceColors.presenceWhite.opacity(0.08))

                Label("Identity", systemImage: "person")
                    .font(Typography.headline)
                    .foregroundStyle(PresenceColors.auroraViolet)
                Text("Nearby users see your username and bio — never your phone number or real name. Bios are anonymized before they leave the device for icebreaker generation.")
                    .font(Typography.caption)
                    .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
            }
        }
    }

    private var blockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Blocked users")
                .font(Typography.footnote)
                .textCase(.uppercase)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                .padding(.leading, 6)

            if isLoadingBlocks && blocks.isEmpty {
                GlassCard(cornerRadius: 22) {
                    HStack { LumaView(state: .gentle, size: 36); Spacer() }
                }
            } else if blocks.isEmpty {
                GlassCard(cornerRadius: 22) {
                    HStack(spacing: 12) {
                        LumaView(state: .gentle, size: 36)
                        Text("You haven't blocked anyone.")
                            .font(Typography.callout)
                            .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                        Spacer()
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(blocks) { block in
                        blockedRow(block)
                    }
                }
            }
        }
    }

    private func blockedRow(_ block: BlockedUser) -> some View {
        GlassCard(cornerRadius: 18) {
            HStack(spacing: 12) {
                Circle()
                    .fill(PresenceColors.Luma.lavender.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(block.username.prefix(1).uppercased())
                            .font(Typography.footnote)
                            .foregroundStyle(PresenceColors.deepNight.opacity(0.8))
                    )
                Text("@\(block.username)").font(Typography.callout)
                Spacer()
                Button("Unblock") {
                    Task { await unblock(block) }
                }
                .font(Typography.footnote)
                .foregroundStyle(PresenceColors.auroraBlue)
                .buttonStyle(.plain)
            }
        }
    }

    private var dataExportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your data")
                .font(Typography.footnote)
                .textCase(.uppercase)
                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.hint))
                .padding(.leading, 6)

            Button {
                Task { await exportData() }
            } label: {
                GlassCard(cornerRadius: 22) {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(PresenceColors.auroraGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isExporting ? "Preparing..." : "Export my data").font(Typography.headline)
                            Text("JSON dump of everything we have on you")
                                .font(Typography.caption)
                                .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                        }
                        Spacer()
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isExporting)
        }
    }

    // MARK: - Actions

    private func loadBlocks() async {
        isLoadingBlocks = true
        defer { isLoadingBlocks = false }
        do {
            let response: BlockListResponse = try await services.backend.get(.listBlocks())
            self.blocks = response.blocks
        } catch {
            errorMessage = "Couldn't load blocks."
        }
    }

    private func unblock(_ block: BlockedUser) async {
        do {
            _ = try await services.backend.sendVoid(.unblock(userId: block.blockedId))
            blocks.removeAll { $0.blockedId == block.blockedId }
        } catch {
            errorMessage = "Couldn't unblock. Try again?"
        }
    }

    private func exportData() async {
        isExporting = true
        defer { isExporting = false }
        guard let data = await services.profileViewModel.exportData() else {
            errorMessage = "Export failed. Try again?"
            return
        }
        // Write to a temp file so the share sheet can hand it off as a
        // native JSON document (vs. a raw blob in pasteboard).
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("presence-export-\(Int(Date().timeIntervalSince1970)).json")
        do {
            try data.write(to: url, options: .atomic)
            exportShareItem = ShareItem(url: url)
        } catch {
            errorMessage = "Couldn't write export file."
        }
    }
}

// MARK: - Share-sheet wrapper

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
