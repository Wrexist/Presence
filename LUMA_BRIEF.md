# LUMA — Complete Mascot Design Brief & Specification
**Presence App Mascot**  
**Version:** 1.0  

---

## 1. THE MASCOT DECISION — RESEARCH & RATIONALE

### Why Presence Needs a Mascot

Research across top-performing apps confirms:
- Apps with mascots see **20–40% higher user retention** vs. those without
- Duolingo attributes a **4.5x increase in DAU** to Duo the Owl's presence
- Mascots create emotional anchors — users form attachments that make them **less likely to churn**
- A mascot's push notification appearance generates **5% higher DAU lift** vs. plain notifications
- Discord's Wumpus generates more fan art than most indie games — unpaid brand amplification

### Why Loneliness Apps Specifically Need This

The loneliness epidemic app category has a unique challenge: users feel vulnerable using it. Admitting you need help making friends carries social stigma. A mascot transforms the emotional context:

- **Without mascot:** "I'm using an app because I'm lonely" → shame
- **With Luma:** "I'm connecting with Luma's world" → delight + community

The mascot creates a third party in the relationship between app and user — one that feels supportive rather than transactional.

### The Mascot Design Decision Framework

Every major design choice for Luma was driven by psychological research:

| Design Element | Choice | Psychological Reason |
|----------------|--------|---------------------|
| Animal type | Marine creature | Non-threatening, alien enough to be novel, familiar enough to bond with |
| Shape | Rounded, no sharp edges | Rounded shapes = approachability, safety, warmth (confirmed by HCI research) |
| Eyes | Large, expressive, simple | Oversized eyes trigger caregiving response (same reason babies and puppies work) |
| Gender | Non-binary / none | Maximum inclusivity; loneliness is universal |
| Color | Bioluminescent aurora | Connects to the app's core metaphor; feels magical not corporate |
| Size | Small, slight | Luma is there to support, not dominate. User is the hero. Luma is the guide. |
| Behavior | Reactive, not proactive | Luma responds to the user's state. Never demands attention. Anti-Duolingo. |

---

## 2. LUMA'S IDENTITY

### Origin Story (internal, informs design)
> Luma is a bioluminescent creature from the deep ocean — a place where light is rare and precious. In the deep dark, creatures evolved to make their own light, not just to see, but to signal: *I'm here. I'm safe. Come closer.*
> 
> Luma found a way to the surface world and discovered something strange: all these beings, surrounded by each other, somehow alone in the dark. So Luma does what comes naturally — glows. A soft invitation. A presence that says: *you're not alone right now.*

### Brand Personality
- **Warm** without being suffocating
- **Curious** about people (the perfect quality for a connection app mascot)
- **Gentle** — never demanding, never guilt-tripping
- **Joyful** about connection — celebrates quietly, meaningfully
- **Honest** about loneliness — doesn't pretend it away, sits with the user in it

### Luma's Voice (for copy, if Luma ever "speaks")
- Short sentences. Never more than 10 words.
- Warm, present-tense, direct
- Never exclamatory (no "YAY!!!")
- Examples:
  - "Someone nearby is glowing too." ✅
  - "There you are." ✅  
  - "Someone out there needs a Luma too." ✅
  - "Great job connecting today!!!!" ❌
  - "Don't forget to go Present today or Luma will be sad!" ❌ (guilt = never)

---

## 3. VISUAL DESIGN SPECIFICATION

### 3.1 Base Form

```
Shape:          Teardrop-ovoid, slightly squished — 70% width : 100% height ratio
Base size:      The design master at 256pt canvas
Body:           Smooth, slightly translucent — feels like a water droplet
               Not perfectly round — has personality wobble in idle animation
Tentacles:      3-4 small trailing wisps below the body
               They have their own gentle physics — lag behind body movement
               Thin at tips, slightly thicker where they meet the body
Eyes:           Two circular eyes, ~25% of body width each
               Simple black pupil + white highlight dot
               Pupil can dilate (excitement) or constrict (sleepy)
               Eyelids visible only when sleepy (not permanent)
Mouth:          Optional, tiny — a subtle curve only in celebrating state
               Usually no visible mouth — expression comes from eyes + glow
```

### 3.2 The Glow System

Luma's glow is the primary communication tool. It's not decoration — it's meaning.

```
Glow anatomy:
  Layer 1 (inner): Solid fill of body — slightly transparent
  Layer 2 (middle): Inner glow, tighter radius, brighter
  Layer 3 (outer): Soft gaussian halo, large radius, color-saturated

Glow colors by state:
  idle        →  Pearl white (#F8F8FF) with soft blue tint, gentle pulse
  excited     →  Warm amber (#FFB84D) → golden (#FFD700), faster pulse
  waving      →  Cyan (#00E5FF) → turquoise (#1DE9B6), rhythmic wave
  connecting  →  Violet (#7C4DFF) → blue-violet (#651FFF), spiral motion
  celebrating →  Full aurora spectrum, rapid color cycling
              →  Colors: #FF6B6B → #FFD93D → #6BCB77 → #4D96FF → #C77DFF
  sleepy      →  Dim steel blue (#546E7A), slow 6-second breathing cycle
  gentle      →  Soft lavender (#CE93D8), eyes closed, no outer glow
```

### 3.3 State Animations (Lottie specs)

**IDLE (loop, continuous)**
```
Duration: 3.2 seconds per loop
Motion:   Gentle floating — sinusoidal Y movement, ±8pt amplitude
          Subtle body squish on lowest point (slight xScale decrease)
          Tentacles trail with 0.4s lag behind body
          Outer glow pulses: 4s cycle, opacity 60%→90%→60%
```

**EXCITED (loop while nearby users are Present)**
```
Duration: 2.0 seconds per loop (faster than idle)
Motion:   More energetic floating, ±12pt amplitude
          Body slightly larger (110% scale)
          Eyes: pupils dilated to 130% normal size
          Tentacles: more active, faster trailing
          Glow: amber, pulsing 2s cycle, brighter (75%→100%→75%)
          Small sparkle particles orbiting body (4 particles)
```

**WAVING (play once on wave send)**
```
Duration: 1.8 seconds
Motion:   One tentacle lifts and waves (0.9s out, 0.9s back)
          Body tilts 15° during wave
          Cyan ripple emanates from body (1 ring, expanding)
          Returns to idle after complete
```

**CONNECTING (loop while icebreaker loads)**
```
Duration: 2.4 seconds per loop
Motion:   Slow spiral orbit of body itself (body moves in small circle)
          Violet glow spirals around body — like a loading halo
          Eyes slightly squinted — "thinking" expression
          Tentacles follow the spiral motion
```

**CELEBRATING (play once on successful connection)**
```
Duration: 3.5 seconds, play once then return to excited
Motion:   Body rapidly grows to 140% scale (0.3s ease-out)
          Aurora burst — radiating color rings (3 rings)
          Sparkles: 8 particles burst outward
          Body gently shrinks back to normal size (1.2s ease-in)
          Final frame: content smile, slight warm glow
```

**SLEEPY (loop when no one nearby)**
```
Duration: 6.0 seconds per loop (slow)
Motion:   Very slow floating, ±4pt amplitude
          Slow blink cycle (eyes close fully, reopen)
          Glow: dim, 40% opacity, no pulse
          Tentacles nearly still
```

**GENTLE (loop during quiet/private moments)**
```
Duration: 5.0 seconds per loop
Motion:   Eyes closed, subtle breathing (scale 100%→102%→100%)
          Soft lavender glow, stable opacity
          No tentacle movement
```

### 3.4 Size Variants

| Use case | Size | Notes |
|----------|------|-------|
| Push notification icon | 32pt | Eyes only visible, simplified glow |
| Chat inline / list | 48pt | Full form, idle or waving state only |
| Map corner companion | 64pt | Full form, reacts to map state |
| Card / inline hero | 128pt | All states supported |
| Onboarding hero | 256pt | Full detail, all states |
| App icon | 1024pt → 60pt | Custom version — face only, no tentacles |

---

## 4. LUMA IN-APP PLACEMENT

### 4.1 Onboarding
- Enters with a slow float from bottom of screen (256pt hero)
- Eye contact with user before any text appears
- Guides through each screen with relevant state
- Celebrates the end of onboarding (celebrating state, then gentle)

### 4.2 Map Screen (Companion)
- Permanent resident: bottom-left corner, 64pt, above tab bar
- Reacts to map state in real-time:
  - No one nearby → sleepy
  - Someone appears → transitions to excited (smooth crossfade)
  - User goes Present → idle (content floating)
  - Wave sent → waving animation
- Tapping Luma: shows "X people are glowing nearby" tooltip (or "Be the first to glow!")

### 4.3 Empty States
- Illustrated with Luma in sleepy or gentle state
- Copy is from Luma's voice: "No one nearby yet. Be the first to glow."
- Never use a generic empty state icon here — always Luma

### 4.4 Wave Sheet
- Small (48pt) in the wave sheet, waving state after wave is sent
- Transitions to connecting while icebreaker loads
- Disappears after icebreaker loads (human-to-human moment, Luma steps back)

### 4.5 Celebrations
- Fullscreen burst after first connection (256pt, celebrating)
- Smaller (128pt) at milestones (5th, 10th connections)

### 4.6 Push Notifications
- 32pt notification icon always shows Luma (not app icon)
- Visual association: Luma icon = something social is happening
- Example notification: [Luma icon] "Someone glowing nearby waved at you 👋"

---

## 5. WHAT LUMA NEVER DOES

Based on research showing guilt-based mascot behavior reduces long-term retention:

❌ **Never guilt-trips:** No "Luma misses you" notifications  
❌ **Never threatens:** No Duolingo-style passive aggression  
❌ **Never demands:** Luma never pushes the user to go Present  
❌ **Never appears in human-to-human moments:** Chat window is Luma-free  
❌ **Never appears on error screens:** Errors are clinical, not Luma's domain  
❌ **Never performs inauthentically:** If the app has a problem, no cheerful Luma  

---

## 6. LUMA & SOCIAL MEDIA STRATEGY

The mascot is a growth engine, not just a product element.

### Organic virality plays
1. **"Meet Luma" reveal post** — animated intro on TikTok/Instagram at launch
2. **Luma seasonal skins** — exclusive to Presence+ subscribers, shared on social
3. **Luma reaction GIFs** — export-able from app after major connections
4. **"Luma reacts to..." content** — show Luma in different states to create meme templates
5. **Luma merchandise** — stickers, enamel pins (future, builds brand equity)

### The anti-Duolingo approach
Duolingo's Duo guilt trips (found to be 5-8% more effective short-term) also create negative brand sentiment over time. Luma's strategy is the opposite: **positive association only**. Users should think of Luma as a supportive friend, never a nag. This trades short-term DAU nudge for long-term brand loyalty.

---

## 7. LUMA IMPLEMENTATION CHECKLIST

**Deliverables needed from designer/animator:**
- [ ] Luma master SVG (all proportions, color palette defined)
- [ ] Idle animation Lottie JSON
- [ ] Excited animation Lottie JSON
- [ ] Waving animation Lottie JSON
- [ ] Connecting animation Lottie JSON
- [ ] Celebrating animation Lottie JSON
- [ ] Sleepy animation Lottie JSON
- [ ] Gentle animation Lottie JSON
- [ ] 32pt simplified version (notification)
- [ ] App icon version (face-forward, no tentacles)
- [ ] Sticker sheet (for in-app sharing)
- [ ] Dark mode variants (subtle adjustments to glow opacity)
- [ ] Luma with seasonal skins: winter (snowflake wisps), summer (sunrays), halloween (orange glow)

**Engineering deliverables:**
- [ ] LumaView.swift component
- [ ] LumaState.swift enum + state machine
- [ ] LumaAnimations.swift (Lottie key mapping)
- [ ] Preloading on app launch
- [ ] Accessibility: Luma animations respect "Reduce Motion" setting
  - If Reduce Motion ON: crossfade between states (no physics/bounce)
