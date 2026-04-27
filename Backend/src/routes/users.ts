//  Presence backend
//  users.ts
//  Self-only user endpoints. Everything here keys off req.userId — there
//  is intentionally no /api/users/:id surface, so a user can never read
//  another user's row via this router.
//
//  Routes:
//    GET    /api/users/me                 — profile + counts
//    PATCH  /api/users/me                 — bio / username updates
//    DELETE /api/users/me                 — account delete (cascades via FKs)
//    GET    /api/users/me/journey         — stats + 7-day activity
//    GET    /api/users/me/export          — GDPR/CCPA data dump (JSON)
//    POST   /api/users/me/subscription    — RevenueCat entitlement mirror
//    POST   /api/users/me/push-token      — APNs device-token registration

import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { getSupabase } from "../services/supabase.js";

export const usersRouter: Router = Router();

// ─── GET /api/users/me ───────────────────────────────────────────────────────

usersRouter.get("/me", requireAuth, async (req: Request, res: Response) => {
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }
  const callerId = req.userId!;

  const userResp = await supabase
    .from("users")
    .select("id, username, bio, avatar_url, created_at, is_plus, plus_expires_at")
    .eq("id", callerId)
    .single();

  type UserRow = {
    id: string;
    username: string;
    bio: string | null;
    avatar_url: string | null;
    created_at: string;
    is_plus: boolean;
    plus_expires_at: string | null;
  };
  const user = userResp.data as UserRow | null;
  if (!user) {
    res.status(404).json({ error: "not_found" });
    return;
  }

  const weekStart = isoWeekStart(new Date());
  const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000);

  const [connectionCountResp, weeklyResp] = await Promise.all([
    supabase
      .from("connections")
      .select("id", { count: "exact", head: true })
      .or(`user_a.eq.${callerId},user_b.eq.${callerId}`),
    supabase
      .from("presences")
      .select("id", { count: "exact", head: true })
      .eq("user_id", callerId)
      .gte("started_at", weekStart.toISOString())
      .lt("started_at", weekEnd.toISOString())
  ]);

  res.json({
    id: user.id,
    username: user.username,
    bio: user.bio,
    avatarUrl: user.avatar_url,
    createdAt: user.created_at,
    isPlus: user.is_plus,
    plusExpiresAt: user.plus_expires_at,
    connectionCount: connectionCountResp.count ?? 0,
    weeklyPresenceCount: weeklyResp.count ?? 0,
    weeklyResetsAt: weekEnd.toISOString()
  });
});

// ─── PATCH /api/users/me ─────────────────────────────────────────────────────

const PatchSchema = z.object({
  username: z
    .string()
    .min(3)
    .max(24)
    .regex(/^[a-z0-9_]+$/, "lowercase, digits, underscore only")
    .optional(),
  bio: z.string().max(60).nullable().optional()
});

usersRouter.patch("/me", requireAuth, async (req: Request, res: Response) => {
  const parsed = PatchSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }
  if (Object.keys(parsed.data).length === 0) {
    res.status(400).json({ error: "no_fields" });
    return;
  }
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  // Build the update object only with provided fields so missing keys
  // don't accidentally null-out columns.
  const update: Record<string, unknown> = {};
  if (parsed.data.username !== undefined) update.username = parsed.data.username;
  if (parsed.data.bio !== undefined) update.bio = parsed.data.bio;

  const { data, error } = await supabase
    .from("users")
    .update(update)
    .eq("id", req.userId!)
    .select("id, username, bio")
    .single();

  if (error) {
    if ((error as { code?: string }).code === "23505") {
      res.status(409).json({ error: "username_taken" });
      return;
    }
    req.log.error({ err: error }, "user patch failed");
    res.status(500).json({ error: "update_failed" });
    return;
  }
  res.json(data);
});

// ─── DELETE /api/users/me ────────────────────────────────────────────────────

usersRouter.delete("/me", requireAuth, async (req: Request, res: Response) => {
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  // Schema cascades via the on-delete FKs we set up in 0001. We also
  // delete the auth.users row so the user can never log back in with the
  // same number until they sign up afresh.
  const { error } = await supabase.from("users").delete().eq("id", req.userId!);
  if (error) {
    req.log.error({ err: error }, "user delete (public) failed");
    res.status(500).json({ error: "delete_failed" });
    return;
  }

  // Best-effort auth-side delete via the Admin API (service-role).
  try {
    // Newer supabase-js exposes admin under .auth.admin; older versions
    // need a different shape. Both calls just return a void response.
    type AdminCapableAuth = {
      admin?: { deleteUser?: (id: string) => Promise<unknown> };
    };
    const auth = supabase.auth as unknown as AdminCapableAuth;
    if (auth.admin?.deleteUser) {
      await auth.admin.deleteUser(req.userId!);
    }
  } catch (err) {
    req.log.warn({ err }, "auth user delete failed (non-fatal)");
  }

  res.status(204).end();
});

// ─── GET /api/users/me/journey ───────────────────────────────────────────────

usersRouter.get("/me/journey", requireAuth, async (req: Request, res: Response) => {
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }
  const callerId = req.userId!;
  const now = new Date();
  const since = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const [connectionsResp, wavesSentResp, presencesResp] = await Promise.all([
    supabase
      .from("connections")
      .select("id", { count: "exact", head: true })
      .or(`user_a.eq.${callerId},user_b.eq.${callerId}`),
    supabase
      .from("waves")
      .select("id", { count: "exact", head: true })
      .eq("sender_id", callerId),
    supabase
      .from("presences")
      .select("started_at, expires_at")
      .eq("user_id", callerId)
      .gte("started_at", since.toISOString())
      .order("started_at", { ascending: true })
      .limit(500)
  ]);

  type PresenceRow = { started_at: string; expires_at: string };
  const presences = (presencesResp.data as PresenceRow[] | null) ?? [];

  // Build a 7-day bucket (today inclusive, going back 6 more days).
  const buckets: { day: string; count: number }[] = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(now);
    d.setUTCDate(d.getUTCDate() - i);
    const key = d.toISOString().slice(0, 10);
    buckets.push({ day: key, count: 0 });
  }
  for (const p of presences) {
    const day = p.started_at.slice(0, 10);
    const bucket = buckets.find((b) => b.day === day);
    if (bucket) bucket.count++;
  }

  // Approximate "time glowing" by summing min(now, expires_at) - started_at.
  let glowingSeconds = 0;
  for (const p of presences) {
    const start = new Date(p.started_at).getTime();
    const end = Math.min(new Date(p.expires_at).getTime(), Date.now());
    if (end > start) glowingSeconds += (end - start) / 1000;
  }

  res.json({
    connectionCount: connectionsResp.count ?? 0,
    wavesSentCount: wavesSentResp.count ?? 0,
    glowingSeconds: Math.round(glowingSeconds),
    activity: buckets
  });
});

// ─── GET /api/users/me/export ────────────────────────────────────────────────

usersRouter.get("/me/export", requireAuth, async (req: Request, res: Response) => {
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }
  const callerId = req.userId!;

  // GDPR/CCPA: ship every row that pertains to the user, in JSON. The
  // iOS client offers this via the share sheet — we don't email so no
  // privacy delegation to a third-party SMTP.
  const [user, presences, wavesSent, wavesRecv, connections, blocks, reports] = await Promise.all([
    supabase.from("users").select("*").eq("id", callerId).single(),
    supabase.from("presences").select("*").eq("user_id", callerId),
    supabase.from("waves").select("*").eq("sender_id", callerId),
    supabase.from("waves").select("*").eq("receiver_id", callerId),
    supabase
      .from("connections")
      .select("*")
      .or(`user_a.eq.${callerId},user_b.eq.${callerId}`),
    supabase.from("blocks").select("*").eq("blocker_id", callerId),
    supabase.from("reports").select("*").eq("reporter_id", callerId)
  ]);

  res.json({
    exportedAt: new Date().toISOString(),
    user: user.data ?? null,
    presences: presences.data ?? [],
    wavesSent: wavesSent.data ?? [],
    wavesReceived: wavesRecv.data ?? [],
    connections: connections.data ?? [],
    blocks: blocks.data ?? [],
    reports: reports.data ?? []
  });
});

// ─── POST /api/users/me/subscription ─────────────────────────────────────────

const SubscriptionSyncSchema = z.object({
  isPlus: z.boolean(),
  expiresAt: z.string().datetime().nullable().optional()
});

usersRouter.post("/me/subscription", requireAuth, async (req: Request, res: Response) => {
  const parsed = SubscriptionSyncSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  // TODO(E6): replace this client-trust path with a RevenueCat webhook
  // that writes is_plus directly. Until then the iOS client tells us its
  // entitlement state — only affects that user's own free-tier counter.
  const { error } = await supabase
    .from("users")
    .update({
      is_plus: parsed.data.isPlus,
      plus_expires_at: parsed.data.expiresAt ?? null
    })
    .eq("id", req.userId!);

  if (error) {
    req.log.error({ err: error }, "subscription sync failed");
    res.status(500).json({ error: "update_failed" });
    return;
  }
  res.status(204).end();
});

// ─── POST /api/users/me/push-token ───────────────────────────────────────────

const PushTokenSchema = z.object({
  token: z.string().min(40).max(200),
  platform: z.enum(["ios", "android"]).default("ios"),
  environment: z.enum(["production", "sandbox"]).default("sandbox")
});

usersRouter.post("/me/push-token", requireAuth, async (req: Request, res: Response) => {
  const parsed = PushTokenSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }
  const { error } = await supabase.from("device_tokens").upsert(
    {
      user_id: req.userId!,
      token: parsed.data.token,
      platform: parsed.data.platform,
      environment: parsed.data.environment,
      last_seen_at: new Date().toISOString()
    },
    { onConflict: "token" }
  );
  if (error) {
    req.log.error({ err: error }, "push-token upsert failed");
    res.status(500).json({ error: "upsert_failed" });
    return;
  }
  res.status(204).end();
});

// MARK: - Helpers

/// First moment of the ISO week (Monday 00:00 UTC) containing `now`.
/// Duplicated from presence.ts to keep this router self-contained.
function isoWeekStart(now: Date): Date {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const dayOfWeek = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - dayOfWeek);
  return d;
}
