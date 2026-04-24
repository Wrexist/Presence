# Presence — Backend

> Node.js 22 + TypeScript. REST + WebSocket. Fully Windows-friendly — no Mac needed.

## Run it locally

```sh
cd Backend
cp .env.example .env          # then fill in values
npm install
npm run dev                   # Express + Socket.io on http://localhost:3000
```

You'll see:

```
presence-backend listening  port=3000  supabase=false  anthropic=false
```

`false` for a feature means the corresponding env var is missing — the server still runs, it just uses stubs / fallbacks for that feature.

## Verify it

```sh
# Liveness + feature flags
curl -s http://localhost:3000/health | jq

# Generate an icebreaker (real Claude call if ANTHROPIC_API_KEY is set,
# deterministic fallback library otherwise)
curl -s -X POST http://localhost:3000/api/icebreaker \
  -H "Content-Type: application/json" \
  -H "x-sender-id: test-user-abc" \
  -d '{
    "venue":      {"name":"Bluestone Coffee","type":"cafe","vibe":"quiet"},
    "timeContext":{"hour":10,"dayOfWeek":"tuesday","isWeekend":false},
    "userA":      {"bio":"loves coffee mornings","connectionCount":0},
    "userB":      {"bio":"runs at golden hour","connectionCount":4}
  }' | jq
```

## Environment variables

| Name                        | Purpose                                              | Required for   |
|-----------------------------|------------------------------------------------------|----------------|
| `PORT`                      | Listening port (default 3000)                        | —              |
| `NODE_ENV`                  | `development` / `production` / `test`                | —              |
| `LOG_LEVEL`                 | pino log level (default `info`)                      | —              |
| `SUPABASE_URL`              | Supabase project URL                                 | DB writes      |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side key — bypasses RLS. **Never ship to iOS.** | DB writes   |
| `ANTHROPIC_API_KEY`         | Anthropic API key                                    | Real icebreakers |
| `CORS_ORIGINS`              | Comma-separated allowlist for dev                    | —              |
| `TRUST_PROXY`               | Proxy hop count (0=off, 1 for Railway/Render/Fly)    | Prod honesty   |

If `ANTHROPIC_API_KEY` is missing, `/api/icebreaker` returns a deterministic fallback from a hand-written library — useful for offline dev.

## Structure

```
Backend/
├── src/
│   ├── index.ts                # Entry point — Express + Socket.io
│   ├── config.ts               # Env validation (Zod)
│   ├── routes/
│   │   ├── health.ts           # GET  /health
│   │   ├── icebreaker.ts       # POST /api/icebreaker  (rate-limited)
│   │   ├── presence.ts         # POST /api/presence  (stub — Sprint 1)
│   │   └── waves.ts            # POST /api/waves     (stub — Sprint 2)
│   ├── services/
│   │   ├── matchingService.ts  # Claude icebreaker + fallback library
│   │   └── supabase.ts         # Server-side Supabase client
│   └── websocket/
│       └── index.ts            # Socket.io scaffold (rooms land Sprint 1)
└── supabase/
    ├── migrations/
    │   └── 0001_initial_schema.sql   # users, presences, waves, connections, blocks, venue_partners
    └── edge-functions/               # (future)
```

## Claude API usage

`src/services/matchingService.ts` uses `@anthropic-ai/sdk` directly with:

- **Model:** `claude-opus-4-7` (per `CLAUDE.md`)
- **`max_tokens`:** 200 — icebreakers must be short
- **`thinking: {type: "disabled"}`** — short creative output, not reasoning
- **No `temperature` / `top_p` / `top_k`** — those are removed on Opus 4.7 (would 400)
- **`cache_control: {type: "ephemeral"}`** on the system prompt — doesn't actually cache at ~300 chars (Opus 4.7's floor is 4096 tokens) but is in place for when the prompt grows

**Validation:** responses < 20 or > 200 chars, or that mention "AI" / "assistant" / "language model", fall back silently to the hand-written library. Hard SLA target is ~800ms p95 — well within the "Luma connecting animation" mask.

**Privacy:** callers must anonymize before invoking. No user IDs, no real names — only bios and venue context.

## Supabase setup

1. Create a project at [supabase.com](https://supabase.com)
2. Copy `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (Settings → API) into `.env`
3. Open the SQL editor, paste `supabase/migrations/0001_initial_schema.sql`, run it
4. (Sprint 1) Wire up Supabase Auth for phone OTP — see `CLAUDE.md` § Auth

Row-level security is enabled on all user-facing tables with a placeholder `deny_all_anon` policy. Sprint 1 replaces it with per-user policies once Auth lands.

## Deploying

The code has no platform-specific dependencies. Any Node 22 host works:

- **Railway** — `railway up` from this directory
- **Render** — set root directory to `Backend/`, build `npm install && npm run build`, start `npm start`
- **Fly.io** — standard Node Dockerfile

Expose `PORT`, set environment variables, attach a Supabase project and an Anthropic key, and point the iOS app's `BACKEND_URL` at the public hostname.
