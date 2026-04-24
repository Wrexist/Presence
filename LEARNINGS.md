# LEARNINGS.md — Accumulated Project Knowledge
> Everything discovered the hard way. Read before making architectural decisions.
> Add to this file whenever something important is learned.

---

## 🍎 iOS 26 / Liquid Glass

### glassEffect API Rules (Critical)
- `.glassEffect()` requires iOS 26+ — always gate with `#available(iOS 26.0, *)`
- `GlassEffectContainer` is required when you have multiple glass shapes that should morph together (e.g., tab bar items)
- Stacking glass layers creates visual mud — avoid entirely
- Glass on scrollable content looks broken — confirmed by Apple HIG
- `Reduce Transparency` accessibility setting: test every glass screen with this ON
  - Use `.background(.regularMaterial)` as fallback
- The `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: GlassTokens.Radius.card))` pattern is the correct way for cards

### MapKit + Liquid Glass
- MapKit overlays in iOS 26 support glass natively via `.mapControlVisibility(.visible)`
- Custom overlays on top of the map must use glass — confirmed pattern from Apple samples
- Map annotations (presence dots) should NOT use glass — use custom glowing views instead

### SwiftUI Concurrency
- Swift 6 strict concurrency: all `@Observable` ViewModels must be `@MainActor`
- Location updates must come through an `actor` (LocationService as actor) to avoid data races
- WebSocket messages: receive on background actor, publish to @MainActor view models

---

## 🌐 Supabase

### PostGIS Geolocation Queries
- `ST_DWithin` is the correct function for "find users within X meters"
- Query pattern for nearby presences:
```sql
SELECT * FROM presences 
WHERE ST_DWithin(
  location, 
  ST_MakePoint($longitude, $latitude)::geography, 
  $radiusMeters
)
AND is_active = TRUE 
AND expires_at > NOW()
AND user_id != $currentUserId
LIMIT 50;
```
- Always index with `USING GIST` on geography columns
- Geography type (not geometry) for distance calculations in meters

### Real-time
- Supabase Realtime works well for presence state changes
- For high-frequency location updates, use WebSocket directly (socket.io) — Supabase Realtime has rate limits

---

## 🤖 Claude API (Opus 4.7)

### Icebreaker generation notes
- Effort level `high` is sufficient for icebreakers — `xhigh` is overkill and slower
- Keeping system prompt < 500 tokens is important for latency
- Average latency at `high` effort: ~800ms — acceptable with Luma connecting animation
- Always validate output: if response > 200 chars, truncate or retry once
- Edge case: if venue type is "other", the icebreaker defaults to time-based context — works fine

### Token efficiency
- New Opus 4.7 tokenizer uses up to 35% more tokens than 4.6 — budget accordingly
- Icebreaker calls: ~150 tokens input, ~80 tokens output → ~0.0003 per call at standard pricing
- At 10,000 icebreakers/day → ~$3/day in AI costs — very manageable

---

## 💳 RevenueCat

### iOS 26 compatibility
*(Add notes as discovered)*

### Known issues from Dynasty Manager
- Always call `Purchases.configure()` before any UI appears (in App init)
- Test on physical device — simulator receipt validation behaves differently
- Sandbox mode: use a fresh Apple ID for each test to avoid cached entitlements

---

## 📍 Location + Privacy

### CoreLocation iOS 26
- `whenInUse` auth is sufficient for our use case — never request `always`
- The new iOS 26 location permission dialog shows a map preview — good for us (shows we're legit)
- Location accuracy: use `kCLLocationAccuracyHundredMeters` — we don't need GPS precision
  - This also reduces battery impact significantly
- Geofencing: NOT used (would require `always` permission)

### Privacy UX pattern
- Show privacy explanation BEFORE requesting permission (tested: 40% better grant rate)
- The "Why we need location" screen should show Luma in `idle` state for warmth

---

## 🎭 Luma — Technical Notes

### Lottie integration
- Use `LottieAnimationView` from Lottie iOS 4.x
- State switching: call `play(fromProgress:toProgress:)` for seamless state transitions
- Luma animations loop by default — set `loopMode = .loop` for idle states
- For celebration: `loopMode = .playOnce` then transition back to idle

### Performance
- Luma at 128pt: ~2MB Lottie JSON — acceptable
- Preload all Luma animations at app launch into `LottieAnimationCache.shared`
- On memory warning: keep idle animation, flush others

---

## 🐛 BUG REGISTRY

### Resolved
*(None yet)*

### Open
*(None yet)*

---

*Always add to this file when you learn something new about the project.*
