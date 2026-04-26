//  PresenceApp
//  HomeView.swift
//  Created: 2026-04-24
//  Updated: 2026-04-26 — wired to MapViewModel (live REST hydrate + socket merge).
//  Purpose: The "who's nearby" tab. Real SwiftUI MapKit map underneath,
//           glowing presence dots from the live nearby query, the user's
//           own dot when CoreLocation has a fix, and the Go Present CTA
//           anchored at the bottom.

import MapKit
import SwiftUI

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)
    @State private var viewModel: MapViewModel?

    var body: some View {
        ZStack {
            map
                .ignoresSafeArea()

            VStack {
                header
                Spacer()
                goPresentCTA
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .task {
            if viewModel == nil {
                viewModel = MapViewModel(
                    backend: services.backend,
                    socket: services.socket,
                    location: services.location
                )
            }
            await viewModel?.start()
        }
        .onDisappear {
            // Tab switch shouldn't tear down the socket — only an explicit
            // sign-out should. Keep the connection live.
        }
        .onChange(of: services.location.currentLocation) { _, newValue in
            // First fix arrives after the user grants permission and starts
            // glowing — re-hydrate so the dots populate without waiting for
            // a socket event.
            guard newValue != nil else { return }
            Task { await viewModel?.hydrate() }
        }
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $cameraPosition) {
            // User's own dot — only when CoreLocation has a fix.
            if let userCoord = services.location.currentLocation?.coordinate {
                Annotation("You", coordinate: userCoord) {
                    PresenceDotView(color: PresenceColors.selfGlow, size: 26, isSelf: true)
                }
                .annotationTitles(.hidden)
            }

            if let viewModel {
                ForEach(viewModel.visible) { user in
                    Annotation("", coordinate: user.coordinate2D) {
                        PresenceDotView(color: PresenceColors.dotColor(for: user.id.uuidString))
                    }
                    .annotationTitles(.hidden)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.visible)
        .mapControls {
            // No MapUserLocationButton here — tapping it would fire the
            // system location prompt, bypassing the "ask only on Go Present"
            // flow that the onboarding privacy screen sets up. Permission
            // is requested exclusively from GoPresentView.
            MapCompass()
        }
        .tint(PresenceColors.auroraBlue)
    }

    // MARK: - Header

    private var header: some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PresenceColors.auroraBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerTitle)
                        .font(Typography.headline)
                        .foregroundStyle(PresenceColors.presenceWhite)
                    Text(headerSubtitle)
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer()
                liveChip
            }
        }
    }

    private var headerTitle: String {
        services.location.currentLocation == nil ? "Looking around" : "Nearby"
    }

    private var headerSubtitle: String {
        guard let viewModel else { return "Setting up..." }
        let count = viewModel.presences.count
        if count == 0 {
            return "No one glowing here right now"
        }
        let suffix = viewModel.overflowCount > 0 ? " (showing closest \(MapViewModel.visibleCap))" : ""
        return "\(count) \(count == 1 ? "person" : "people") glowing nearby\(suffix)"
    }

    @ViewBuilder
    private var liveChip: some View {
        switch services.socket.state {
        case .connected:
            GlassChip(text: "Live", systemImage: "dot.radiowaves.left.and.right")
        case .connecting, .reconnecting:
            GlassChip(text: "...", systemImage: "ellipsis")
        case .disconnected:
            GlassChip(text: "Offline", systemImage: "wifi.slash")
        }
    }

    // MARK: - CTA

    private var goPresentCTA: some View {
        VStack(spacing: 12) {
            GlassChip(text: "Open to connecting · right now", systemImage: "sparkles")
            GlassPillButton(title: "Go Present", systemImage: "sparkles") {
                coordinator.present(.goPresent)
            }
            .shadow(color: PresenceColors.auroraBlue.opacity(0.5), radius: 22, y: 6)
        }
    }

    // MARK: - Constants

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
}

private extension PresentUser {
    var coordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
