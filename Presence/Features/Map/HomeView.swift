//  PresenceApp
//  HomeView.swift
//  Created: 2026-04-24
//  Purpose: The "who's nearby" tab. Real SwiftUI MapKit map underneath,
//           glowing presence dots + floating Lumas as annotations, and the
//           Go Present CTA anchored at the bottom. Camera defaults to San
//           Francisco when no location fix is available; shows the user's
//           own dot when CoreLocation has a current fix.

import MapKit
import SwiftUI

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ServiceContainer.self) private var services

    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)

    // Preview data — stays static until Sprint 1 wires the backend.
    private let venueName = "San Francisco"
    private let nearbyCount = 8
    private let previewDots: [PreviewDot] = [
        .init(lat: 37.7755, lng: -122.4220, color: PresenceColors.auroraPink),
        .init(lat: 37.7788, lng: -122.4200, color: PresenceColors.auroraViolet),
        .init(lat: 37.7730, lng: -122.4150, color: PresenceColors.auroraBlue),
        .init(lat: 37.7770, lng: -122.4165, color: PresenceColors.auroraAmber),
        .init(lat: 37.7760, lng: -122.4245, color: PresenceColors.auroraViolet),
        .init(lat: 37.7712, lng: -122.4210, color: PresenceColors.auroraPink),
        .init(lat: 37.7742, lng: -122.4125, color: PresenceColors.auroraBlue)
    ]
    private let lumaAnnotations: [LumaAnnotation] = [
        .init(lat: 37.7773, lng: -122.4185, state: .idle, size: 44),
        .init(lat: 37.7742, lng: -122.4188, state: .excited, size: 40)
    ]

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

            // Nearby presences.
            ForEach(previewDots) { dot in
                Annotation("", coordinate: dot.coordinate) {
                    PresenceDotView(color: dot.color)
                }
                .annotationTitles(.hidden)
            }

            // Floating Lumas scattered on the map (Design_2 aesthetic).
            ForEach(lumaAnnotations) { luma in
                Annotation("", coordinate: luma.coordinate) {
                    LumaView(state: luma.state, size: luma.size)
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.visible)
        .mapControls {
            MapCompass()
            MapUserLocationButton()
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
                    Text(venueName)
                        .font(Typography.headline)
                        .foregroundStyle(PresenceColors.presenceWhite)
                    Text("\(nearbyCount) people glowing nearby")
                        .font(Typography.caption)
                        .foregroundStyle(PresenceColors.presenceWhite.opacity(GlassTokens.Opacity.secondary))
                }
                Spacer()
                GlassChip(text: "Live", systemImage: "dot.radiowaves.left.and.right")
            }
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

// MARK: - Supporting annotation types

private struct PreviewDot: Identifiable {
    let id = UUID()
    let lat: Double
    let lng: Double
    let color: Color

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: lat, longitude: lng)
    }
}

private struct LumaAnnotation: Identifiable {
    let id = UUID()
    let lat: Double
    let lng: Double
    let state: LumaState
    let size: CGFloat

    var coordinate: CLLocationCoordinate2D {
        .init(latitude: lat, longitude: lng)
    }
}

#Preview {
    HomeView()
        .environment(AppCoordinator())
        .environment(ServiceContainer.preview())
        .preferredColorScheme(.dark)
}
