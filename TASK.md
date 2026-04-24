# TASK.md — Current Work State
> Update this at the end of every session. Read at the start of every session.

---

## 🎯 CURRENT SPRINT: Sprint 0 — Foundation
**Goal:** Working skeleton: auth, map, presence toggle, Luma idle state  
**Sprint end:** 2 weeks from project start

---

## ✅ COMPLETED TASKS

### [TASK-002] Design System — Liquid Glass Foundation (code-only portion)
- [x] GlassTokens enum complete (`DesignSystem/GlassTokens.swift`)
- [x] GlassCard component
- [x] GlassPillButton component
- [x] GlassIconButton component
- [x] GlassBottomSheet component
- [x] GlassChip component (bonus — needed for countdowns/status)
- [x] Fallback Material components for iOS < 26 (centralized in `glassSurface(in:thin:)`)
- [x] Preview all components in light + dark mode + Reduce Transparency

### [TASK-001] Project Setup (partial — code-only portion)
- [x] GlassTokens.swift design system file
- [x] Color palette defined in PresenceColors.swift (aurora + base + dot palette helper)
- [x] Typography.swift (SF Pro Rounded scale)

---

## 🔨 IN PROGRESS

### [TASK-001] Project Setup (remaining — requires Xcode + dashboards)
- [ ] Xcode 26 project created with iOS 26 target
- [ ] Wire `DesignSystem/*.swift` into the Xcode target
- [ ] SwiftUI app shell with AppCoordinator
- [ ] Supabase project created and configured
- [ ] RevenueCat dashboard setup

### [TASK-003] Auth Flow
- [ ] Supabase phone auth integration
- [ ] OTP verification screen (glass design)
- [ ] Username + bio setup screen
- [ ] Luma onboarding animation trigger

---

## 📋 BACKLOG (Ordered by Priority)

### Sprint 1 — Core Loop
- [ ] TASK-004: MapView with MapKit + Liquid Glass overlays
- [ ] TASK-005: LocationService (CoreLocation wrapper)
- [ ] TASK-006: PresenceService (toggle on/off, 3h expiry)
- [ ] TASK-007: Supabase PostGIS integration (store/query presences)
- [ ] TASK-008: WebSocket service (real-time dot updates on map)
- [ ] TASK-009: PresenceDotView (glowing marker on map)
- [ ] TASK-010: "Go Present" button (main CTA, glass pill)
- [ ] TASK-011: Luma component + idle animation (Lottie)

### Sprint 2 — Wave System
- [ ] TASK-012: Tap-a-dot → wave preview sheet
- [ ] TASK-013: Claude API icebreaker generation (backend)
- [ ] TASK-014: WaveView — show icebreaker + wave button
- [ ] TASK-015: Wave notification (push, Luma inline)
- [ ] TASK-016: Wave response flow (accept/ignore)
- [ ] TASK-017: 10-minute chat window (ChatView with countdown)
- [ ] TASK-018: Connection recording + Luma celebration

### Sprint 3 — Monetization & Polish
- [ ] TASK-019: RevenueCat integration
- [ ] TASK-020: Paywall screen (Presence+)
- [ ] TASK-021: Free tier enforcement (3 presences/week)
- [ ] TASK-022: Profile screen + connection history
- [ ] TASK-023: Block/report flow
- [ ] TASK-024: Privacy screen + data export
- [ ] TASK-025: Settings screen
- [ ] TASK-026: Luma full state machine + all animations

### Sprint 4 — Beta
- [ ] TASK-027: App Store Connect setup
- [ ] TASK-028: TestFlight distribution
- [ ] TASK-029: Analytics (PostHog)
- [ ] TASK-030: Crash reporting (Sentry)
- [ ] TASK-031: ASO — screenshots, description, keywords
- [ ] TASK-032: Venue partner B2B backend

---

## 🐛 ACTIVE BUGS

*None yet*

---

## 🔖 SESSION NOTES

**Last session (2026-04-24):** Scaffolded the Liquid Glass design system in `DesignSystem/` — `GlassTokens.swift`, `PresenceColors.swift` (with `Color(hex:)` extension and deterministic per-user dot-color helper), `Typography.swift` (SF Pro Rounded scale), and `GlassComponents.swift` (GlassCard, GlassPillButton, GlassIconButton, GlassBottomSheet, GlassChip + iOS 26 gating with Material fallback). Four `#Preview`s cover dark / light / bottom sheet / Reduce Transparency. Files are pure Swift — drop them into the Xcode 26 target once it's created.

**Next session start with:** TASK-001 remainder — create the Xcode 26 project, add the `DesignSystem/` folder to the target, then build the app shell (`PresenceApp.swift`, `AppCoordinator.swift`, `ServiceContainer.swift`).

---

## 📊 METRICS TO TRACK (post-launch)
- DAU / MAU ratio (target: >40% — Duolingo benchmark)
- Presences per active user per week (target: 2+)
- Wave accept rate (target: >30%)
- Connection-to-friend rate (how many waves become real connections — survey)
- Week 1 retention (target: >50%)
- Week 4 retention (target: >25%)
- Free-to-paid conversion (target: >5%)
