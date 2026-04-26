# Supabase Setup — Step-by-Step

> One-time provisioning guide for the Presence Supabase project.
> Follow top to bottom. Do not skip the "verify" lines — they catch silent misconfiguration.

---

## 0. Prerequisites
- A GitHub account (Supabase signs you in with it)
- A Twilio account with one purchased phone number (for SMS OTP)
- The repo cloned locally; `.env.example` copied to `.env.development`

---

## 1. Create the project

1. Go to <https://supabase.com> → **Start your project** → sign in with GitHub.
2. **New project** in your default org.
   - **Name:** `presence-prod` (we'll add a `presence-dev` later if needed)
   - **Database password:** generate one, save it in your password manager (you will need it for `psql`/CLI later, never commits to git)
   - **Region:** pick the region geographically closest to your launch city (e.g. `us-west-1` for SF, `eu-west-2` for London) — PostGIS distance queries care about latency
   - **Pricing plan:** Free is fine for now; upgrade to Pro ($25/mo) before public launch for daily backups + 8GB DB
3. Wait ~2 min for provisioning.

**Verify:** the dashboard shows "Setting up project" → "Project is ready" without errors.

---

## 2. Enable PostGIS

The PostGIS extension is required for the `GEOGRAPHY(POINT, 4326)` columns and `ST_DWithin` queries in our migration.

1. Left nav → **Database** → **Extensions**.
2. Search `postgis` → toggle it ON.
3. Confirm. (Supabase enables it in the `extensions` schema automatically.)

**Verify:** still on the Extensions page, `postgis` shows a green "Enabled" badge.

---

## 3. Run the schema migration

1. Left nav → **SQL Editor** → **New query**.
2. Open `Backend/supabase/migrations/0001_initial_schema.sql` from the repo, copy the entire file, paste it into the editor.
3. Click **Run** (or `Cmd/Ctrl+Enter`).
4. You should see "Success. No rows returned." Errors usually mean PostGIS wasn't enabled in step 2 — go back and enable it.

**Verify:**
- Left nav → **Table Editor** → confirm tables exist: `users`, `presences`, `waves`, `connections`, `blocks`, `venue_partners`.
- Left nav → **Database** → **Indexes** → confirm `presences_location_idx` exists with type `gist`.

---

## 4. Configure Phone Auth (Twilio)

Presence uses phone-only auth — no email — to reduce signup friction.

### 4a. In Twilio
1. <https://console.twilio.com> → grab from the dashboard:
   - **Account SID**
   - **Auth Token**
   - **Messaging Service SID** (create one under Messaging → Services if you don't have it; attach your purchased number to the service)

### 4b. In Supabase
1. Left nav → **Authentication** → **Providers** → **Phone**.
2. Toggle **Enable phone provider** ON.
3. **SMS provider:** Twilio.
4. Paste **Account SID**, **Auth Token**, **Messaging Service SID**.
5. **OTP expiry:** 600 seconds (10 minutes) — matches our retry UX.
6. **OTP length:** 6 digits.
7. **Rate limits:** leave defaults; we add an app-side limiter later.
8. Save.

### 4c. (Optional but recommended) Disable email auth
1. Same screen → **Email** provider → toggle OFF.
   - Prevents accidental email-based signup paths.

**Verify:** `supabase.auth.signInWithOtp({ phone: '+15555550100' })` from the JS SDK should send an SMS to your real phone in ~10 seconds. Don't waste real OTPs — just confirm one delivers, then move on.

---

## 5. Configure Storage (for optional avatars)

Most users will keep the Luma default avatar, but Plus users can upload one.

1. Left nav → **Storage** → **Create a new bucket**.
   - **Name:** `avatars`
   - **Public:** ON (avatars are non-sensitive — the username already identifies the user to nearby presences)
   - **File size limit:** 2 MB
   - **Allowed MIME types:** `image/jpeg, image/png, image/heic`
2. Create a second bucket `luma-assets` for the Lottie JSON files.
   - **Public:** ON
   - **File size limit:** 1 MB

**Verify:** both buckets appear in the Storage list.

---

## 6. Copy keys into `.env.development`

1. Left nav → **Project Settings** → **API**.
2. Copy these into `Backend/.env.development` and `.env.development` at the repo root:

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...                  # Project API keys → "anon public"
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...          # Project API keys → "service_role" — BACKEND ONLY
```

3. Confirm `.env.development` is gitignored (it is — `.gitignore` covers `.env*` already, but double-check).

**Critical:** the **service-role key bypasses RLS**. It must NEVER ship in the iOS bundle. Only the backend (`Backend/src/services/supabase.ts`) reads it.

---

## 7. Smoke-test the backend

```sh
cd Backend
cp .env.example .env
# fill in SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY (+ ANTHROPIC_API_KEY if you have one)
npm install
npm run dev
```

Expected log line:
```
presence-backend listening  port=3000  supabase=true  anthropic=true
```

`supabase=true` means the env validation in `src/config.ts` passed.

Then:
```sh
curl -s http://localhost:3000/health | jq
```

Should return `{ ok: true, supabase: true, anthropic: true }`.

---

## 8. (Sprint 1) Replace placeholder RLS

The migration ships with `deny_all_anon` placeholder policies. Once `AuthService` lands real Supabase Auth (Phase B, prompt B1), we replace those with per-user policies. Don't loosen them before Auth is wired — anonymous read of `presences` would leak location.

---

## Common gotchas

- **"extension postgis does not exist"** → step 2 not done.
- **OTPs not arriving** → Twilio Messaging Service has no number attached, or trial account can only send to verified numbers.
- **`new row violates RLS`** in backend logs → you're using the anon key on the server. Switch to `SUPABASE_SERVICE_ROLE_KEY`.
- **Free tier project paused after 7 days idle** → log into the dashboard once a week during dev, or upgrade to Pro.
