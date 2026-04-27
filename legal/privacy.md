# Privacy Policy

**Effective:** [TO FILL — date you publish this page]
**Last updated:** 2026-04-26

## The short version

We built Presence around a small set of privacy non-negotiables. Here's
what they mean for you in plain English:

- Your **location is collected only while you're glowing**. Never in
  the background. The moment you stop a Presence (or three hours pass —
  whichever comes first), location collection stops.
- Before your location ever leaves your phone, it's reduced by about
  **50 meters** of random jitter. We never know exactly where you are,
  even when you're glowing.
- We sign you in with your **phone number only**. We never ask for
  your email, your real name, or your photo.
- Your **bio is anonymized** before it's used to write an icebreaker —
  no user id, no name, no phone number is ever sent to our AI.
- You can **export everything** we have on you, in JSON, with one tap
  in Settings → Privacy → Export my data.
- You can **delete your account** in two taps. The deletion cascades to
  every row that mentions you. We don't keep a "shadow copy."

The rest of this document explains what each of those promises means,
in detail, in legalese where the law requires it.

---

## 1. Who we are

"Presence" is the iOS app and supporting backend operated by
[TO FILL — legal entity name + registered address]. You can reach us
at `privacy@app.presence.ios`. Our data protection contact is the same
address.

If you're in the EU/EEA, we are the data controller for the personal
data described in this policy. Under GDPR Article 6(1)(b), our legal
basis for processing your data is the **performance of the contract**
that arises when you sign up — Presence cannot function without the
specific data points listed below.

If you're in California, this policy doubles as our CCPA notice.

---

## 2. What we collect

### 2.1 Data you give us directly

- **Phone number** — used only for sign-in (one-time SMS code via
  Twilio). Stored in our auth provider (Supabase Auth) so we can sign
  you in next time. Never shared with other users.
- **Username** — chosen at onboarding, displayed to nearby users.
  Lowercase, 3–24 characters.
- **Bio (optional)** — a 3-word description displayed to nearby users
  and sent (anonymized) to our icebreaker engine.
- **Profile photo (optional)** — uploaded to Supabase Storage; public
  URL. Most users keep the default Luma avatar.
- **Push notification token** — provided by Apple, used to send wave +
  mutual-connection notifications. We rotate the token on every
  install.

### 2.2 Data we collect automatically

- **Approximate location** — only while a Presence is active. Reduced
  by ~50m of random jitter before storage. Used to compute who's
  nearby. Deleted when the Presence expires (max 3 hours).
- **Device platform** (iOS) and **environment** (sandbox / production)
  — used to route push notifications correctly.
- **Crash and performance data** — via Sentry. We've explicitly
  disabled screenshot and view-hierarchy capture; IPs and user PII
  are scrubbed before the event leaves your device or our backend.
- **Product analytics** — via PostHog. Event metadata only — never
  message bodies, never bios, never coordinates. Identifies you by
  your Presence user id (a UUID), not your phone or name.

### 2.3 Data we do NOT collect

We want to be explicit. Presence does **not** collect:

- Your real name
- Your email address
- Your contacts / address book
- Your photos / camera roll
- Your microphone / speech
- Your background location
- Your other apps
- Any device fingerprinting beyond Apple's IDFV

---

## 3. How we use your data

| Purpose | Data used | Legal basis (GDPR) |
|---|---|---|
| Sign you in | Phone, OTP token | Contract |
| Show your dot to nearby users | Reduced coords, username | Contract |
| Generate icebreakers | Anonymized bio + venue context | Contract |
| Deliver wave + mutual notifications | Push token | Contract |
| Stop fraud + abuse | Block lists, reports | Legitimate interest |
| Crash debugging | Sentry events (PII-scrubbed) | Legitimate interest |
| Improve the product | Aggregate analytics events | Legitimate interest |

We do **not** use your data for advertising. Presence has no ads.

We do **not** sell your data. Under CCPA, this means we do not "sell"
or "share" personal information for cross-context behavioral advertising.

---

## 4. Who we share it with

| Vendor | What they see | Why | Where |
|---|---|---|---|
| Supabase | DB rows + auth + storage | Hosts the data | US/EU |
| Twilio | Phone number | Sends OTP SMS | US |
| Anthropic (Claude API) | **Anonymized** bios + venue context | Generates icebreakers | US |
| Apple Push Notification service | Device token + notification body | Pushes wave alerts | US |
| RevenueCat | App-Store transaction id, your Presence id | Subscription state | US |
| Sentry | PII-scrubbed crash events | Crash reporting | US |
| PostHog | Event metadata + your Presence id | Analytics | US/EU |
| Railway / our hosting provider | Encrypted traffic + logs | Runs the backend | US |

Each vendor has a Data Processing Agreement with us. We don't share
your data with any other third party.

---

## 5. Where your data lives

Our database lives in [TO FILL — Supabase project region, e.g.
`us-west-1`]. If you're in the EEA, your data is transferred to the
United States under Standard Contractual Clauses. You can request a
copy of the SCCs at the privacy email above.

---

## 6. How long we keep it

| Data | Retention |
|---|---|
| Active Presence row | Auto-deleted at expiry (max 3 hours) |
| Wave row | Deleted at expiry (2 hours) or on delete |
| Chat messages | Deleted with the chat room (10 minutes after creation) |
| Connections | Kept until you delete your account |
| User row | Until you delete your account |
| Crash events | 90 days at Sentry |
| Analytics events | 12 months at PostHog |

When you delete your account, every row in our database that mentions
your user id is removed via a cascade. The Sentry / PostHog records
expire on the schedule above.

---

## 7. Your rights

Wherever you live, you have the right to:

- **Access** — Settings → Privacy → Export my data gives you JSON of
  every row that mentions you.
- **Delete** — Settings → Account → Delete account. Two-tap confirm.
- **Correct** — Settings → Profile → tap username or bio.
- **Object / restrict** — email `privacy@app.presence.ios` and we'll
  process the request within 30 days.
- **Withdraw consent / opt out** — analytics is optional but currently
  on by default. To opt out before in-app toggles ship, email us.

If you're in the EU/EEA, you also have the right to lodge a complaint
with your national data-protection authority. We hope you'll email us
first so we can fix whatever's wrong.

---

## 8. Children

Presence is **17+**. We do not knowingly collect data from anyone under
17. If we learn we've collected data from a minor, we'll delete it. If
you believe a friend has lied about their age, you can report it
through Settings → Privacy → contact us.

---

## 9. Security

- All API traffic is HTTPS / WSS only.
- Authentication tokens are stored in iOS Keychain, not UserDefaults.
- Database access at the backend uses the service-role key, which never
  ships in the iOS bundle.
- We test against the OWASP Mobile Top 10 before each App Store release.

If you discover a vulnerability, please email
`security@app.presence.ios`. We respond within 72 hours.

---

## 10. Changes to this policy

We'll update this page when we change something material, and we'll
post the change date at the top. If the change is significant — for
example, adding a new vendor or a new data category — we'll show a
banner in-app the next time you open it.

---

## 11. Contact

`privacy@app.presence.ios` — for any of the above.
