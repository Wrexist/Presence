# PRESENCE — Full Development Roadmap
**Version:** 1.0 | **Start Date:** Week of Project Kickoff

---

## PHASE OVERVIEW

```
Phase 0: Foundation         [Weeks 1–2]   → Working skeleton
Phase 1: Core Loop          [Weeks 3–5]   → Map + Presence + Waves
Phase 2: AI + Luma          [Weeks 6–8]   → Icebreakers + Mascot
Phase 3: Monetization       [Weeks 9–10]  → RevenueCat + Paywall
Phase 4: Safety + Polish    [Weeks 11–12] → Safety + Accessibility
Phase 5: Beta               [Weeks 13–14] → TestFlight, 100 users
Phase 6: Launch             [Week 15]     → App Store submission
```

---

## PHASE 0: FOUNDATION (Weeks 1–2)

### Week 1

#### Day 1-2: Project Setup
- [ ] Create Xcode 26 project: `Presence`
- [ ] Configure iOS 26 deployment target
- [ ] Set up Git repository with main/develop branch structure
- [ ] Add all SPM dependencies:
  ```swift
  // Package.swift dependencies
  .package(url: "https://github.com/airbnb/lottie-ios", from: "4.5.0")
  .package(url: "https://github.com/RevenueCat/purchases-ios", from: "5.0.0")
  .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.0.0")
  .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0")
  ```
- [ ] Create Supabase project (free tier → upgrade at launch)
- [ ] Run all SQL migrations (schema from CLAUDE.md)
- [ ] Create `.env.development` with all keys
- [ ] Confirm all keys loaded via `Config.swift`

#### Day 3-4: Design System
- [ ] `GlassTokens.swift` — full enum with all constants
- [ ] `PresenceColors.swift` — brand palette:
  ```swift
  enum PresenceColors {
      // Aurora palette — core brand
      static let auroraBlue = Color(hex: "#4FC3F7")
      static let auroraViolet = Color(hex: "#7C4DFF")
      static let auroraGreen = Color(hex: "#1DE9B6")
      static let auroraAmber = Color(hex: "#FFB84D")
      static let auroraPink = Color(hex: "#F48FB1")
      // Base
      static let presenceWhite = Color(hex: "#F8F8FF")
      static let deepNight = Color(hex: "#0A0A1A")
      static let softMidnight = Color(hex: "#141428")
  }
  ```
- [ ] `Typography.swift` — type scale (SF Pro Rounded for all text — warm, friendly)
- [ ] `GlassComponents.swift`:
  - `GlassCard<Content: View>` — standard glass card
  - `GlassPillButton` — primary CTA
  - `GlassIconButton` — circular icon CTA
  - `GlassBottomSheet<Content: View>` — sheet overlay
  - `GlassChip` — small status indicator
- [ ] Preview all components: light + dark + Reduce Transparency

#### Day 5: Architecture Shell
- [ ] `AppCoordinator.swift` — navigation routing
- [ ] `ServiceContainer.swift` — DI container
- [ ] Basic tab structure: Map | Profile | Settings
- [ ] Placeholder views for each tab

### Week 2

#### Day 6-7: Authentication
- [ ] `AuthService.swift` — Supabase phone auth wrapper
- [ ] Phone entry view (glass design)
- [ ] OTP verification view (glass design)
- [ ] Onboarding flow: username → bio → privacy → location permission
- [ ] Luma placeholder (static image) during onboarding
- [ ] `UserRepository.swift` — create/fetch user

#### Day 8-9: Backend Setup
- [ ] Node.js 22 + TypeScript project init
- [ ] Express server with Socket.io
- [ ] Routes: `/health`, `/api/presence`, `/api/waves`, `/api/icebreaker`
- [ ] Supabase client (server-side)
- [ ] Deploy to Railway or Render (cheap, instant)
- [ ] Environment variables configured in deployment

#### Day 10: Integration Test
- [ ] Auth flow: phone → OTP → username → map (end-to-end)
- [ ] Backend reachable from iOS client
- [ ] Supabase tables verified working via dashboard

**Phase 0 Exit Criteria:** User can sign up, set a username, and land on an empty map screen.

---

## PHASE 1: CORE LOOP (Weeks 3–5)

### Week 3: Map + Location

#### Day 11-13: Map View
- [ ] `MapView.swift` — full-screen MapKit
- [ ] Apply Liquid Glass to map controls:
  ```swift
  Map(position: $position) { ... }
    .mapControls {
      MapCompass().glassEffect()
      MapUserLocationButton().glassEffect()
    }
  ```
- [ ] `PresenceDotView.swift` — glowing annotation:
  ```swift
  // Custom map annotation — NOT using glass, using glow
  struct PresenceDotView: View {
      let color: Color
      @State private var pulse = false
      var body: some View {
          ZStack {
              Circle().fill(color.opacity(0.3))
                  .frame(width: 44, height: 44)
                  .scaleEffect(pulse ? 1.4 : 1.0)
                  .animation(.easeInOut(duration: 1.5).repeatForever(), value: pulse)
              Circle().fill(color)
                  .frame(width: 22, height: 22)
          }
          .onAppear { pulse = true }
      }
  }
  ```
- [ ] Map camera: follows user location on first open, then free
- [ ] MapViewModel: load nearby presences, update on WebSocket event

#### Day 14-15: Location Service
- [ ] `LocationService.swift` (actor):
  ```swift
  actor LocationService: NSObject, CLLocationManagerDelegate {
      private let manager = CLLocationManager()
      private(set) var currentLocation: CLLocation?
      
      func requestPermission() async -> CLAuthorizationStatus { ... }
      func startUpdating() { manager.startUpdatingLocation() }
      func stopUpdating() { manager.stopUpdatingLocation() }
      // Privacy: reduce precision before sharing
      func privacyReducedLocation() -> CLLocationCoordinate2D? {
          guard let loc = currentLocation else { return nil }
          // Add ±50m random offset
          let latOffset = Double.random(in: -0.0005...0.0005)
          let lonOffset = Double.random(in: -0.0005...0.0005)
          return CLLocationCoordinate2D(
              latitude: loc.coordinate.latitude + latOffset,
              longitude: loc.coordinate.longitude + lonOffset
          )
      }
  }
  ```

### Week 4: Presence Toggle + WebSocket

#### Day 16-18: Presence Service
- [ ] `PresenceService.swift`:
  - `activate()` — POST to backend, start location updates, schedule 3h expiry
  - `deactivate()` — DELETE presence, stop location updates
  - `updateLocation()` — PATCH with new (privacy-reduced) coordinates every 60s
  - `expiryTimer` — auto-deactivate after 3 hours
- [ ] "Go Present" glass pill button on MapView
- [ ] Active/inactive visual states (button changes label + glow)
- [ ] 3-hour countdown chip below button when active
- [ ] User's own dot appears on map when present

#### Day 19-20: WebSocket (Real-time)
- [ ] `SocketService.swift` (actor):
  - Events: `presence_joined`, `presence_left`, `presence_updated`
  - Reconnection with exponential backoff
  - `@Published` presences array updates MapView reactively
- [ ] Backend: Socket.io room per geohash zone (efficient, no over-broadcast)
- [ ] Test: Two simulators, both go Present, both see each other's dot

### Week 5: Wave System (Core)

#### Day 21-23: Wave UI
- [ ] Tap-on-dot handler → bottom sheet presentation
- [ ] `WaveSheetView.swift`:
  - Other user username + 3-word bio
  - Icebreaker card (placeholder text for now)
  - "Wave 👋" primary glass pill button
  - "Not now" secondary text button
- [ ] Wave API call: POST `/api/waves` with sender/receiver
- [ ] Sent state: button changes to "Wave sent!" with checkmark

#### Day 24-25: Wave Notifications + Response
- [ ] `NotificationService.swift` — push token registration
- [ ] Backend: send push on wave received (Expo Push or APNs direct)
- [ ] Wave received notification: tap → open app → WaveResponseView
- [ ] `WaveResponseView.swift` — same icebreaker, "Wave back 👋" / "Not right now"
- [ ] On mutual wave: trigger ChatView

**Phase 1 Exit Criteria:** Two real users on real devices can see each other on map, send and receive waves.

---

## PHASE 2: AI + LUMA (Weeks 6–8)

### Week 6: Claude API Icebreaker Integration

#### Day 26-28: Backend AI Service
- [ ] `matchingService.ts`:
  ```typescript
  async function generateIcebreaker(req: IcebreakerRequest): Promise<string> {
    const response = await anthropic.messages.create({
      model: 'claude-opus-4-7',
      max_tokens: 200,
      system: ICEBREAKER_SYSTEM_PROMPT, // from CLAUDE.md
      messages: [{
        role: 'user',
        content: buildIcebreakerPrompt(req)
      }]
    });
    const text = response.content[0].text;
    // Validate: length check, no PII leakage, not empty
    if (text.length > 200 || text.length < 20) {
      return generateFallbackIcebreaker(req); // static fallback
    }
    return text;
  }
  ```
- [ ] Venue classification service (MapKit PlaceInfo → venue type)
- [ ] Icebreaker endpoint: POST `/api/icebreaker` — auth required, rate limited (1/30s per user)
- [ ] Fallback library: 50 pre-written icebreakers by venue type (used if AI fails/slow)
- [ ] Caching: cache icebreaker per user-pair-venue combo for 30 minutes

#### Day 29-30: Wire into iOS
- [ ] WaveSheetView: show Luma connecting animation while loading
- [ ] On icebreaker received: fade-in text in glass card
- [ ] Error state: use cached fallback icebreaker silently
- [ ] Test latency: must feel instant (Luma animation masks any wait)

### Week 7: Luma Integration

#### Day 31-33: Luma Core Component
- [ ] `LumaView.swift`:
  ```swift
  struct LumaView: View {
      @State var state: LumaState = .idle
      let size: CGFloat
      
      var body: some View {
          LottieView(animation: .named(state.animationName))
              .looping(state.shouldLoop)
              .frame(width: size, height: size)
              .onChange(of: state) { newState in
                  // Crossfade transition
              }
              // Respect Reduce Motion
              .animation(
                  UIAccessibility.isReduceMotionEnabled ? .none : .easeInOut(duration: 0.4),
                  value: state
              )
      }
  }
  ```
- [ ] `LumaState.swift` + `LumaAnimations.swift` (map states to Lottie files)
- [ ] `LumaViewModel.swift` — centralized state machine, reacts to app events

#### Day 34-35: Luma Placement
- [ ] Onboarding: 256pt hero Luma, idle → excited at completion
- [ ] Map corner: 64pt Luma, reacts to nearby presences
- [ ] Wave sheet: 48pt waving Luma after wave sent
- [ ] Empty states: sleepy/gentle Luma with brand copy
- [ ] Notification icon: 32pt simplified Luma

### Week 8: Chat Window

#### Day 36-38: Timed Chat
- [ ] `ChatView.swift`:
  - Simple text input (glass design)
  - 10-minute countdown — `CountdownChip` glass component
  - Messages list (no glass on scroll content)
  - Auto-lock at 00:00 with end message
- [ ] Real-time chat via WebSocket room (unique per wave ID)
- [ ] Haptic feedback on message receive
- [ ] "Head over and say hi!" end state with Luma celebrating

#### Day 39-40: Connection Recording
- [ ] On mutual wave (pre-chat): record connection in DB
- [ ] Profile: connection count increments
- [ ] Milestone celebrations: 1st, 5th, 10th, 25th connections
- [ ] Luma celebrating animation triggers at milestones

**Phase 2 Exit Criteria:** Full loop working — Present → Wave → Icebreaker → Chat → Connection → Celebration.

---

## PHASE 3: MONETIZATION (Weeks 9–10)

#### Day 41-44: RevenueCat Setup
- [ ] RevenueCat dashboard: create products
  - `presence_plus_monthly` ($6.99/month)
  - `presence_plus_annual` ($49.99/year)
- [ ] App Store Connect: create subscription group
- [ ] `SubscriptionService.swift` — RevenueCat wrapper
- [ ] `Entitlement.presencePlus` check before unlimited presence
- [ ] Free tier enforcement: track weekly presence count (local + server)
- [ ] Paywall trigger: after 3rd weekly presence attempt

#### Day 45-47: Paywall UI
- [ ] `PaywallView.swift`:
  - Luma in excited state (hero)
  - Feature list with glass chips
  - Monthly / Annual toggle (glass segmented control)
  - "Start 7-day free trial" glass primary button
  - "Restore purchases" subtle link
- [ ] Post-purchase: immediate entitlement unlock, Luma celebration

#### Day 48-50: B2B Venue Partner (Basic)
- [ ] Admin endpoint: mark venue as Partner
- [ ] Partner venues: highlighted ring on map dot
- [ ] Analytics endpoint: connections-at-venue count (anonymized)

**Phase 3 Exit Criteria:** RevenueCat processes a real sandbox purchase, entitlement unlocked, paywall dismissed.

---

## PHASE 4: SAFETY + POLISH (Weeks 11–12)

#### Day 51-54: Safety
- [ ] Block: `BlockService.swift` + UI (one tap from wave sheet/chat)
- [ ] Report: `ReportView.swift` — 5 category options + optional text
- [ ] DB: blocked_users table, report queue table
- [ ] Filter: blocked users never appear in presence queries
- [ ] Admin review queue (basic web dashboard via Supabase Studio)

#### Day 55-57: Accessibility
- [ ] VoiceOver labels on all interactive elements
- [ ] Presence dots: VoiceOver reads "Glowing user, [username], [bio]"
- [ ] Luma: `.accessibilityHidden(true)` — decorative, not functional
- [ ] Dynamic Type: all text scales correctly
- [ ] Reduce Motion: all animations fall back to crossfades
- [ ] Reduce Transparency: glass elements fall back to Material

#### Day 58-60: Polish Pass
- [ ] Haptic feedback audit (every tap should have haptic response)
- [ ] Loading states consistent across all views
- [ ] Error states: network offline, location denied, server error
- [ ] Onboarding re-testable: force logout + re-onboard flow
- [ ] App icon: Luma face variant
- [ ] Launch screen: dark aurora gradient, Luma fades in

**Phase 4 Exit Criteria:** Full accessibility audit passes. Block/report tested end-to-end.

---

## PHASE 5: BETA (Weeks 13–14)

#### Day 61-65: TestFlight
- [ ] App Store Connect: complete app metadata
- [ ] Privacy policy URL (required)
- [ ] Terms of service URL (required)
- [ ] TestFlight build submitted
- [ ] Internal testing (15 people minimum, real city)
- [ ] Crash monitoring: Sentry.io integration
- [ ] Analytics: PostHog event tracking live

#### Day 66-70: Beta Feedback Loop
- [ ] Run beta in target city (coffee shop QR codes)
- [ ] Daily crash review
- [ ] Icebreaker quality review (manual sample of 50)
- [ ] Wave accept rate tracking
- [ ] Fix P0/P1 bugs from beta feedback
- [ ] Final RevenueCat integration test (real purchase)

**Phase 5 Exit Criteria:** 100 beta users, crash-free rate >99%, at least 5 real connections made.

---

## PHASE 6: LAUNCH (Week 15)

#### Day 71-74: App Store Submission
- [ ] App Store screenshots (6.9" + 6.1" + iPad if supported)
  - Screenshot 1: Map with glowing dots — "Find your people, right now"
  - Screenshot 2: Icebreaker card — "Break the ice without the awkward"
  - Screenshot 3: Luma guide — "Luma shows the way"
  - Screenshot 4: Connection celebration — "Real connections, real life"
  - Screenshot 5: Presence+ — "Glow without limits"
- [ ] App preview video (30 seconds, shows full flow)
- [ ] App Store description (ASO-optimized)
- [ ] Keywords: loneliness, make friends, meet people, social, nearby
- [ ] Age rating: 17+ (chat feature)
- [ ] Submit for review — expedite review request citing loneliness epidemic context

#### Day 75: Launch Day
- [ ] Monitor crash reports (Sentry)
- [ ] Monitor WebSocket server load
- [ ] Social media: "Luma is live" reveal post
- [ ] Press outreach: loneliness epidemic angle (Reuters, local city paper, tech blogs)
- [ ] Monitor App Store rating — respond to first reviews same day

---

## POST-LAUNCH ROADMAP

### Month 2
- [ ] City 2 + City 3 expansion
- [ ] Luma skin shop (seasonal)
- [ ] "Presence Hubs" venue partner program (paid B2B)
- [ ] Improved icebreaker quality (A/B test prompts with PostHog)

### Month 3-4
- [ ] Group Presence: up to 4 people can wave together (table of friends, open to strangers joining)
- [ ] Recurring events: "Morning run every Tuesday, Riverside Park" — community-created
- [ ] iOS widget: Luma idle animation, shows "X people glowing nearby"

### Month 6+
- [ ] Android (React Native port — leverage existing backend)
- [ ] Luma virtual companion mode (Presence+ exclusive)
- [ ] API for venue partners (real-time foot traffic for social connection)

---

## RISK REGISTER

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Cold start problem (no users = no dots) | High | High | City-specific stealth launch, venue seeding, early community |
| Safety incident (harassment via wave) | Medium | High | Block/report on every surface, 2h wave expiry, moderation queue |
| Location permission denial rate | Medium | High | Privacy-first explanation before request, clear value prop |
| Apple review rejection (safety concerns) | Medium | High | 18+ age rating, clear safety features documented in review notes |
| Claude API latency spikes | Low | Medium | Fallback icebreaker library, Luma connecting animation as buffer |
| WebSocket server overload at scale | Low | High | Geohash rooms limit broadcast scope, auto-scaling on Railway |
| Romantic use instead of friendship | Medium | Medium | No romantic language anywhere, report category includes "unwanted advances" |
