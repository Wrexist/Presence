# iOS Widget — Design Spec (F.2)

> A small Home Screen / StandBy widget showing "X people glowing nearby"
> with an idle Luma. Targets Month 3 from `ROADMAP.md`. **Spec only.**

---

## Why

The widget is a low-cost re-engagement surface for users who fell off
the daily-active loop. Glance at the home screen → see "5 people
glowing within walking distance" → open the app. Apple's StandBy mode
adds a second always-on surface that's basically free real estate for
ambient-presence apps.

## Non-goals

- Interactive widgets (taps that don't open the app — Apple's `Button`
  in widgets is power-limited, and the wave flow needs the full app
  context anyway).
- Live data refresh more often than ~15 minutes (battery + APNs cost).
- Complications on Apple Watch (defer to a separate watchOS pass).

## Sizes

| Family | Display | Use |
|---|---|---|
| `.systemSmall` | Single tile | Count + Luma |
| `.systemMedium` | Wide tile | Count + Luma + a sample venue name |
| `.accessoryInline` | Lock-screen text | "5 people glowing nearby" |
| `.accessoryCircular` | Lock-screen ring | Luma silhouette + count |

StandBy adopts the medium variant on iPhone 15+; iPhone 14 and earlier
fall back to the small one.

## Data shape

Widget timeline entries carry only what the widget renders:

```swift
struct GlowingNearbyEntry: TimelineEntry {
    let date: Date
    let count: Int          // 0..N, capped at 9 for display ("9+")
    let topVenue: String?   // "Bluestone · 4 min walk"
    let lumaState: LumaState  // idle / excited
    let isAuthed: Bool      // false → "Sign in to Presence"
}
```

## Data delivery: APNs background push, NOT polling

Polling on a 15-minute timeline is fine for correctness but bad for
freshness — by the time the user looks, the count is stale. The right
shape:

1. **Default timeline**: refresh every 30 minutes (`Date().addingTimeInterval(1800)`).
2. **Background push**: when a `presence_joined` or `presence_left`
   event lands in the user's geohash, the backend fires a silent APNs
   `content-available: 1` push. The app's NotificationService handles
   it and calls `WidgetCenter.shared.reloadAllTimelines()`.
3. The widget's TimelineProvider re-reads from a shared App Group cache
   that the host app populates from the same socket events.

This gives < 1-minute freshness without the widget extension itself
holding a socket connection (which it can't — widgets are not
long-lived).

## Privacy: count rounding

Per the privacy non-negotiables, **never display a count under 3** —
showing "1 person glowing 200m from you" is a triangulation risk. The
widget shows:

| Real count | Display |
|---|---|
| 0 | "No one glowing yet" |
| 1–2 | "Be the first to glow" (we lie a tiny bit; better than triangulation) |
| 3–9 | exact count |
| 10+ | "10+ glowing nearby" |

This is also why the widget renders the user's *own* dot only after
they're already glowing — never when they're not.

## App Group + shared cache

```swift
extension UserDefaults {
    static let widgetShared = UserDefaults(
        suiteName: "group.app.presence.ios"
    )!
}
```

The host app's `MapViewModel` writes a small struct to widget shared
defaults whenever `presences` updates:

```swift
struct WidgetCachedState: Codable {
    let count: Int
    let topVenue: String?
    let updatedAt: Date
}
```

The widget reads this in `TimelineProvider.placeholder` and
`getTimeline`. Falls back to "No one glowing yet" when stale (>15
minutes old).

## Project + entitlements changes

`project.yml` gains a second target:

```yaml
PresenceWidgets:
  type: app-extension
  platform: iOS
  sources: [PresenceWidgets]
  info:
    properties:
      NSExtension:
        NSExtensionPointIdentifier: com.apple.widgetkit-extension
  entitlements:
    com.apple.security.application-groups:
      - group.app.presence.ios
```

The host app target also adds the same App Group entitlement.

## Tap deep-link

Tapping the widget opens the app to the Map tab — not the Compose
sheet, since by the time the app loads the count has likely shifted.

```swift
.widgetURL(URL(string: "presence://map")!)
```

Host app handles the URL via the existing `AppCoordinator.deepLink`
flow.

## Launch checklist

- [ ] App Group entitlement provisioned in Apple Developer
- [ ] Widget extension target added via `xcodegen generate`
- [ ] Silent push in production (depends on real APNs send from E6)
- [ ] Privacy review of the count-rounding rule
- [ ] StandBy + Lock-screen variants tested on iPhone 15 + iPhone 14
