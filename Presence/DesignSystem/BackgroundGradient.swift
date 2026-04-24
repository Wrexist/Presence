//  PresenceApp
//  BackgroundGradient.swift
//  Created: 2026-04-24
//  Purpose: The one-and-only app backdrop. Deep-night with subtle aurora
//           color wisps. Used by every top-level screen so screens morph
//           rather than cut between backgrounds.

import SwiftUI

struct PresenceBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    PresenceColors.deepNight,
                    PresenceColors.softMidnight,
                    PresenceColors.twilight
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Aurora wisps — soft blurred color blobs.
            Circle()
                .fill(PresenceColors.auroraViolet.opacity(0.35))
                .frame(width: 360, height: 360)
                .blur(radius: 120)
                .offset(x: -140, y: -280)
            Circle()
                .fill(PresenceColors.auroraPink.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 130)
                .offset(x: 160, y: 240)
            Circle()
                .fill(PresenceColors.auroraBlue.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 110)
                .offset(x: 140, y: -120)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PresenceBackground()
        .preferredColorScheme(.dark)
}
