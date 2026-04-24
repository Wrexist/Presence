# PRESENCE — Product Requirements Document
**Version:** 1.0  
**Status:** Active  
**Last Updated:** April 2026

---

## 1. PROBLEM STATEMENT

The United States Surgeon General declared loneliness a public health epidemic in 2023. Two-thirds of adults report feeling lonely. Yet no mobile app has successfully solved the core problem: the social friction of initiating a real-world connection with a nearby stranger.

Existing apps fail because they:
- **Meetup/Bumble BFF:** Match on interests, but the effort gap from "matched" to "actually met" is too large
- **Dating apps:** Wrong intent framing — users want friendship without romantic pressure
- **Nextdoor:** Neighborhood-level, not real-time, not about meeting
- **None of the above:** Reduce the activation energy of the first interaction to zero

**The core insight:** The problem isn't *finding* compatible people. It's the social cost of initiating. Presence eliminates that cost by:
1. Making both people's intent simultaneously visible (both opted in)
2. Replacing the awkward opener with an AI-generated icebreaker calibrated to the moment
3. Anchoring the interaction to a physical place, removing the ambiguity of when/where

---

## 2. TARGET USER

### Primary Persona: "The Displaced Adult" (25–40)
- Moved to a new city for work in the last 1–3 years
- Has work colleagues but few close friends in this city
- Goes to coffee shops, gyms, parks regularly — sees the same faces but never breaks through
- Tried Meetup but found group events overwhelming
- Tried making friends at work but the dynamic is complicated
- **Emotional state:** Not acutely lonely, but quietly aware something is missing

### Secondary Persona: "The Remote Worker" (28–45)
- Works from home or co-working spaces
- Misses the incidental social contact of office life
- Looking for low-commitment social moments, not organized events
- High disposable income, willing to pay for tools that genuinely help

### Tertiary Persona: "The Traveler / New Resident" (22–35)
- In a new city temporarily (studying, travelling, relocated)
- Needs low-friction connections that acknowledge the temporary nature
- Already comfortable with tech-mediated social discovery

### Non-target (explicitly out of scope)
- People seeking romantic connections (dating app dynamic, causes safety concerns)
- Users under 18 (strict 18+ enforcement at signup)
- People who want async/passive social media (wrong product)

---

## 3. CORE USER JOURNEY

```
[Discovery] → [Download] → [Onboarding] → [First Presence] → [First Wave] → [Connection] → [Retention]
```

### 3.1 Onboarding (target: <4 minutes)
1. Luma floats onto a soft aurora background — no text yet, just presence
2. "You're not alone in feeling alone." — first words the app ever says
3. Phone number entry (no email friction)
4. OTP verification
5. Choose username (not real name)
6. Bio: "Three words that describe what you're into." (e.g., "morning coffee runs")
   - Three-word constraint is intentional — low effort, memorable, shareable
7. Privacy explanation (Luma shows privacy shield, explains location is off by default)
8. Location permission request — only after explanation
9. "Welcome. When you're ready to glow, tap the button." → Map

### 3.2 Core Loop (First Presence)
1. User opens map — sees ambient map of their area
2. If no one nearby is Present: Luma shows `sleepy` state, "Be the first to glow here."
3. User taps the large glass "Go Present" pill button
4. Luma transitions `idle → excited` — subtle glow pulse
5. User's dot appears on the map
6. If nearby users are also Present: their dots glow into view

### 3.3 Wave Flow
1. User taps a nearby dot
2. Glass bottom sheet slides up — shows:
   - Other user's username + bio (3 words)
   - Luma in `connecting` state while icebreaker loads (~800ms)
   - Icebreaker appears in a glass card — e.g., "This is prime golden-hour park time — do you run this route often?"
3. User sees two options:
   - "Wave 👋" (glass primary button)
   - "Not now" (subtle text link)
4. On wave: notification sent to other user with same icebreaker
5. If other user waves back within 2 hours:
   - Glass chat window opens for exactly 10 minutes
   - Countdown timer visible (glass chip, top of chat)
   - Luma in `celebrating` state, then moves to corner
   - Chat ends — "Head over and say hi. You've got the intro."

### 3.4 Retention Loop
- Connection stored (no location, just username + venue name + date)
- "You've connected with X people through Presence." counter on profile
- Luma celebrates each connection milestone (1st, 5th, 10th, 25th)
- Weekly summary notification: "You glowed for X minutes this week." (positive framing)
- Luma seasonal skins (exclusive to Presence+ subscribers)

---

## 4. FEATURE SPECIFICATIONS

### 4.1 Map View
**Priority: P0**
- Full-screen MapKit map with Liquid Glass navigation overlays
- Present user dots: glowing circles, 22pt diameter, aurora color palette
- Dot color: random from palette per user (consistent per user, not random per view)
- Dot pulse animation: 3s breathing cycle while Present
- Maximum dots visible: 50 (cluster beyond that with a glass count chip)
- Venue names visible at zoom levels showing individual buildings
- User's own dot: slightly larger, different glow color (white/pearl)
- "Ghost mode" indicator: glass chip showing how many anonymous viewers saw user's dot

### 4.2 Presence Toggle
**Priority: P0**
- Large glass pill button, bottom-center of map: "Go Present" / "Stop Glowing"
- Tap: triggers CoreLocation request if not granted
- Active state: button glows, Luma transitions to `excited`
- Auto-expires after 3 hours (countdown visible on button: "2h 41m remaining")
- Emergency stop: always one tap — no confirmation dialog needed

### 4.3 Wave System
**Priority: P0**
- Wave sheet: glass bottom sheet, slides up from bottom
- Icebreaker card: glass card within sheet, text appears with subtle fade-in
- Wave send: haptic feedback + Luma waving animation
- Wave received: push notification with Luma icon, icebreaker text preview
- Wave expires: 2 hours after send — no "seen" receipts (intentionally)
- Max open waves: 3 at once (prevents gaming the system)

### 4.4 Chat Window
**Priority: P0**
- 10-minute countdown — cannot be paused or extended (intentional constraint)
- Glass countdown chip: updates every second in final 60 seconds (red tint)
- Messages: simple, no media, no reactions, no read receipts
- On timer end: "Time's up. Go say hi in real life! 🌟" — chat locked
- No chat history stored after session (privacy + forcing function)

### 4.5 Profile
**Priority: P1**
- Username + bio display
- Luma avatar (animated, user's color choice for Luma's idle glow)
- Connection count: "47 connections made"
- Member since date
- Edit bio
- Presence+ status indicator

### 4.6 Presence+ Paywall
**Priority: P1**
- Shown after 3rd weekly presence attempt
- Luma in `excited` state on paywall screen
- Clear value: "Glow as much as you want. See who's nearby before you commit."
- Monthly: $6.99 | Annual: $49.99 (saves $34/year, prominently shown)
- Free trial: 7 days

### 4.7 Safety System
**Priority: P0**
- Block: one tap from wave sheet or chat window
- Report: category selection (inappropriate, spam, threatening)
- Blocked users: never appear on each other's map
- Auto-suspension: 3 reports from unique users triggers review
- No-go zones: admin can blacklist specific coordinates (used for known trouble areas)

---

## 5. NON-FUNCTIONAL REQUIREMENTS

| Requirement | Target |
|------------|--------|
| App launch time | < 1.5 seconds cold start |
| Map load time | < 2 seconds to first dot visible |
| Icebreaker generation latency | < 1.5 seconds (p95) |
| WebSocket reconnection | < 3 seconds after network restore |
| Location precision delivered to server | ~50m radius (privacy reduction applied) |
| Presence data retention | 0 hours post-expiry (deleted immediately) |
| Chat message history retention | 0 hours post-session |
| Crash-free sessions | > 99.5% |
| Accessibility | WCAG AA, full VoiceOver support |

---

## 6. SUCCESS METRICS

### North Star Metric
**Real Connections Per Week** — number of waves that result in a mutual wave-back across all active users

### Supporting Metrics
| Metric | Week 4 Target | Month 6 Target |
|--------|---------------|----------------|
| DAU/MAU | 30% | 40% |
| Presences/active user/week | 1.5 | 2.5 |
| Wave send rate (dots tapped that send wave) | 20% | 30% |
| Wave accept rate (waves received that wave back) | 25% | 35% |
| Free → Presence+ conversion | 3% | 6% |
| Presence+ 30-day retention | 70% | 80% |
| App Store rating | 4.4+ | 4.6+ |

---

## 7. LAUNCH STRATEGY

### Phase 1: Stealth City Launch (Month 1-2)
- Single city: target a major metro with active social scene + high remote worker %, e.g., Austin TX or Denver CO
- Invite-only via QR codes at select coffee shops + co-working spaces
- 500 user target
- Personal outreach to venue managers for Venue Partner pilot

### Phase 2: City Expansion (Month 3-4)
- 3 cities based on Phase 1 learning
- PR: pitch the "loneliness epidemic" angle to local city media
- TikTok: "I met my new best friend because we were at the same coffee shop" stories (authentic, not scripted)

### Phase 3: National + Presence+ Launch (Month 5-6)
- RevenueCat paywall goes live
- Press: Tech press + wellness media angle
- App Store feature pitch: fits "Apps We Love" social category

---

*This document governs all product decisions. Changes require updating this file.*
