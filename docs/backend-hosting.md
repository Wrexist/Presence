# Backend Hosting — Decision

> Where to run `Backend/` (Node.js 22 + Express + Socket.io).

## TL;DR

**Pick: Railway.**
Reasons in priority order: (1) WebSockets work out of the box on a long-lived process, no extra config; (2) zero cold-start (the container stays warm) — critical because socket reconnects after a cold start break the realtime presence feel; (3) the GitHub integration + `railway up` CLI is the simplest deploy path for a 2-person team; (4) ~$5/mo hobby tier comfortably handles dev + early beta; (5) generous logs/metrics in the dashboard, no separate observability stack needed for v1.

Move off Railway only if (a) usage outgrows the $20/mo Pro tier, or (b) you need multi-region — at that point Fly.io or self-hosted on Hetzner make sense.

---

## Comparison

| Criterion | Railway | Render | Fly.io |
|---|---|---|---|
| WebSockets | ✅ Native | ✅ Native | ✅ Native |
| Cold start | None (always-on container) | ~15s on free, none on paid | None on paid |
| Pricing (early-stage) | $5/mo Hobby covers this app | $7/mo per service | $0–5/mo, but per-service add-ons stack up |
| Deploy from GitHub Actions | `railway up` CLI, single token | Auto-deploy or API | `flyctl deploy`, single token |
| Persistent connections | Fine | Fine | Fine, plus regional routing |
| Multi-region | Single region | Single region | Best-in-class |
| Logs/metrics in dashboard | Built-in, good | Built-in, decent | Built-in, requires `flyctl logs` |
| Docker required | No (auto-detects Node) | No | Yes (Dockerfile) |
| Setup time for this repo | ~10 min | ~15 min | ~30 min (Dockerfile + fly.toml) |
| Best fit for | Solo/small team, single region, fast iteration | Same, slightly cheaper at idle | Multi-region, ops-heavy teams |

### Why not Vercel / Netlify / AWS Lambda?
WebSockets on serverless are second-class — you'd need Vercel's separate websocket product, AWS API Gateway WebSocket APIs, or Pusher/Ably as a layer. All three add latency, complexity, and cost. Presence's realtime presence-dot updates need a long-lived connection per active user; a long-lived container is the right shape.

### Why not Heroku?
Heroku's free tier is gone, the cheapest dyno is ~$7/mo, dynos sleep on the lowest paid tier, and the deploy story is no better than Railway. No reason to pick it in 2026.

---

## Setup steps (Railway)

1. <https://railway.app> → sign in with GitHub.
2. **New Project** → **Deploy from GitHub repo** → pick `wrexist/presence`.
3. **Configure**:
   - **Root directory:** `Backend`
   - **Build command:** auto-detected (`npm install && npm run build`)
   - **Start command:** auto-detected (`npm start`)
   - **Watch paths:** `Backend/**` (so iOS-only changes don't redeploy)
4. **Variables** tab → add:
   - `NODE_ENV=production`
   - `SUPABASE_URL=...`
   - `SUPABASE_SERVICE_ROLE_KEY=...`
   - `ANTHROPIC_API_KEY=...`
   - `CORS_ORIGINS=https://app.presence.ios` (the iOS bundle id origin used during dev — adjust)
   - `TRUST_PROXY=1`
   - `LOG_LEVEL=info`
5. **Settings → Networking → Generate Domain** → copy the `*.up.railway.app` URL.
6. Smoke test:
   ```sh
   curl -s https://<your-app>.up.railway.app/health | jq
   ```
   Should return `{ ok: true, supabase: true, anthropic: true }`.
7. In Railway **Project Settings → Tokens** → create a project token. This goes into GitHub repo secrets as `RAILWAY_TOKEN`.
8. Also note your **Service ID** (from the service URL or `railway service`) — goes into the workflow as a literal.

---

## GitHub Actions deploy

See `.github/workflows/backend-deploy.yml` (added in this same change). It triggers only on `Backend/**` changes pushed to `main`, runs typecheck, then `railway up` with the token from secrets.

### Required repo secrets
- `RAILWAY_TOKEN` — project token from step 7 above

### Why path filtering matters
iOS-only PRs on this repo touch `Presence/**` constantly. Without path filtering, every iOS commit would redeploy the backend, blow CI minutes, and risk a bad deploy from a Swift-only PR. The `paths:` filter scopes redeploys to actual backend changes.

---

## Rollback

Railway keeps a deploy history. From the dashboard: **Deployments → Older deploy → Rollback**. Takes ~30s.

For emergency rollback from CLI:
```sh
railway redeploy <previous-deployment-id>
```
