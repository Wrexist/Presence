# App Store Submission Pack — E4

> Everything App Store Connect asks for, drafted. Copy directly into the
> portal at submission time. Verify character counts in the App Store
> Connect form (limits change over time — these are accurate as of
> 2026-04).

---

## Listing basics

**App name (30 chars max)**
> Presence — Glow Nearby

**Subtitle (30 chars max)**
> See who's open, right now

**Promotional text (170 chars; updateable without resubmission)**
> Every Sunday Luma takes a deep breath and starts glowing again. Coffee shops, parks, gyms — see who's open to a moment, no swipes, no DMs, just real life.

**Bundle id**
> `app.presence.ios`

**Primary category**
> Social Networking

**Secondary category**
> Lifestyle

**Age rating**
> 17+ — chat feature is unrestricted human-to-human text. See "Age rating
> rationale" below for the App Review Notes copy.

---

## Description (≤4000 chars)

```
Presence is the loneliness app that's not about apps.

Open it when you're somewhere — a coffee shop, a park, your gym — and tap "Go Present." A small light starts glowing. Other people who are also open to a moment see your glow. You see theirs. Tap one, and Presence quietly writes a single icebreaker just for the two of you, based on where you are and who you both said you'd want to meet.

If you both wave back, you get ten minutes to chat — then the window closes, and the rest is up to you. Walk over. Say hi. The whole point is real life.

Why Presence is different
• No feed. No likes. No DMs. No flexing.
• No location tracking — your location is collected only while you're glowing, never in the background, and it's reduced by ~50m before it ever leaves your phone.
• Phone-only signup. We never ask for your email, your real name, or your photo.
• Every Presence auto-expires after 3 hours. Every chat closes after 10 minutes. By design.
• It's not a dating app. There's no romantic framing anywhere. Block + report are one tap from any wave.

Meet Luma
A small bioluminescent creature who lives in the app. Luma celebrates with you when a wave lands, gets sleepy when you're alone for too long, and never — ever — guilt-trips you for being away.

Presence+ ($6.99/month or $49.99/year)
• Unlimited Presences (free is 3 per week)
• Enhanced icebreakers from a smarter model
• See how many people are glowing nearby before you decide
• Quiet Hours — schedule auto-Presence
• Seasonal Luma skins

Privacy promises
• Your bio (max 3 words) is anonymized before it ever touches our AI.
• You can export everything we have on you in one tap.
• You can delete your account in two taps.

Built for the way the loneliness epidemic is actually shaped: most people have plenty of weak ties, just no permission to turn one into a moment. Presence is the permission.

Glow when you're ready.
```

(~1850 chars — well under 4000.)

---

## Keywords (≤100 chars, comma-separated, no spaces between commas)

```
loneliness,make friends,meet people,nearby,social,real life,connection,community,presence,solo
```

(98 chars.)

---

## Support URL / Marketing URL

- **Support URL:** `https://app.presence.ios/support`
- **Marketing URL:** `https://app.presence.ios`
- **Privacy Policy URL:** `https://app.presence.ios/privacy` (matches `legal/privacy.md`)

---

## Age rating rationale (App Review Notes)

```
Age rating: 17+

Why: Presence facilitates one-on-one real-time text chat between two
adults who have mutually opted in via a "wave" handshake. Each chat
window is hard-capped at 10 minutes (server-enforced) and explicitly
designed to push toward real-world meetup, not extended digital chat.

Safety design (please review):
• Phone-only signup; no email, no real name required
• Block + report reachable in ≤2 taps from every user-to-user surface
• Reports auto-block; reports queue is reviewed within 24h
• Block list is mutual-effect (blocked user disappears from each side)
• 18+ language not displayed; chat is plain text, no media
• No public profiles, no feed, no public posts
• No DMs outside the 10-minute window
• Location is reduced by ~50m before storage; never collected in background
• Presences auto-expire after 3 hours

The 17+ rating reflects unrestricted user-generated text between
adults; we are choosing to be conservative even though chat content is
moderated. We are NOT marketing this as a dating app and there is no
romantic language in the product anywhere — please flag if anything
slipped through.
```

---

## Screenshot frames (5 required for 6.9" + 6.1")

Pixel sizes per Apple's 2026 guidelines:
- **6.9" iPhone**: `1320 × 2868`
- **6.1" iPhone**: `1206 × 2622`

Each frame: aurora gradient background, headline at top in SF Pro Rounded
Bold (~64pt at 6.9"), the actual app screen below, optional Luma in
matching state at the corner.

### Frame 1 — Map
- **Headline:** "Find your people, right now"
- **Sub:** "A glass map of who's open, nearby"
- **Capture:** `HomeView` with 8–10 dots scattered, ambient Luma idle in
  bottom-left corner, header chip showing "12 people glowing nearby"

### Frame 2 — Wave compose
- **Headline:** "Break the ice without the awkward"
- **Sub:** "Claude writes you a single perfect line"
- **Capture:** `WaveComposeView` mid-load, Luma in `.connecting`, then
  the same frame after the icebreaker text fades in

### Frame 3 — Luma
- **Headline:** "Luma shows the way"
- **Sub:** "Glows with you. Sleeps when you're alone. Never nags."
- **Capture:** Mostly Luma — `LumaView(state: .excited, size: 360)`
  centered, soft aurora behind, no chrome

### Frame 4 — Connection
- **Headline:** "Real connections, real life"
- **Sub:** "Ten minutes to chat. Then go say hi."
- **Capture:** `CelebrationView` mid-burst, "You connected!" + "Open
  chat" CTA visible

### Frame 5 — Presence+
- **Headline:** "Glow without limits"
- **Sub:** "Unlimited Presences and richer icebreakers"
- **Capture:** `PaywallView` with annual selected (Save 40% chip
  visible), 7-day trial CTA prominent

### App preview video (30 seconds)
Optional but bumps download conversion ~25%. Storyboard:
- 0–3s: city block at dusk, Luma glow appearing
- 3–10s: tap Go Present → glow on map
- 10–18s: tap a dot → icebreaker fades in → wave sent
- 18–25s: notification "Maya waved back" → mutual celebration
- 25–30s: "Walk over and say hi." → app icon fade out

Voiceover: none. Music: a soft ambient piece (royalty-free; lock down
license before submission).

---

## Submission checklist (when ready)

- [ ] All screenshots exported at exact pixel sizes (no resampling)
- [ ] App preview video uploaded for 6.9" and 6.1"
- [ ] App icon (1024 × 1024 PNG, no alpha, no rounded corners)
- [ ] Description finalized + spell-checked
- [ ] Keywords copy-pasted verbatim (PRESERVE the comma-separated form)
- [ ] Privacy Policy URL live (deploy `legal/privacy.md`)
- [ ] Support URL live
- [ ] Demo account credentials in App Review Notes (phone + OTP test
      number wired through Twilio)
- [ ] Age-rating rationale pasted into App Review Notes
- [ ] Build uploaded via Xcode Organizer or `fastlane pilot`
- [ ] Build set as the version's primary build in App Store Connect
- [ ] Subscription products approved (RevenueCat dashboard mirrors them)
- [ ] Tax + banking info filled in App Store Connect
- [ ] Submit for review with "Expedite for loneliness epidemic context"
      cover note (cite Cigna 2024 loneliness study + the sub-3-min
      on-screen interaction time)

## After submission

- Monitor `App Store Connect → App Review → Status` daily
- Average review time as of 2026-04: 18 hours
- If rejected, the most likely flag is "social networking with chat —
  needs an active moderation queue." Have the moderation runbook from
  `docs/testflight-runbook.md` ready as evidence.
