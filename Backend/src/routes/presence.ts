//  Presence backend
//  presence.ts
//  Three routes implementing the core presence loop:
//    POST   /api/presence            — go-present, inserts a row + broadcasts
//    GET    /api/presence/nearby     — ST_DWithin via the nearby_presences RPC
//    DELETE /api/presence/:id        — owner-only deactivate + broadcast
//
//  All routes require a valid Supabase JWT. The body NEVER carries userId —
//  it always comes from the JWT, so a malicious client can't impersonate
//  another user just by spoofing the body.

import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { getSupabase } from "../services/supabase.js";
import { broadcast } from "../services/socketHub.js";
import { geohashOf } from "../services/geohash.js";

export const presenceRouter: Router = Router();

const ActivateSchema = z.object({
  location: z.object({
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180)
  }),
  venueName: z.string().min(1).max(120).optional(),
  venueType: z
    .enum(["cafe", "park", "gym", "library", "bar", "coworking", "other"])
    .optional(),
  durationMinutes: z.number().int().min(15).max(180).default(180)
});

const NearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radiusM: z.coerce.number().int().min(50).max(5000).default(500)
});

const UuidParamSchema = z.object({ id: z.string().uuid() });

type NearbyRow = {
  id: string;
  user_id: string;
  username: string;
  bio: string | null;
  lat: number;
  lng: number;
  venue_name: string | null;
  expires_at: string;
};

type PresenceInsertResult = {
  id: string;
  expires_at: string;
};

type DeleteResult = {
  id: string;
  location: unknown;
};

// ─── POST /api/presence ──────────────────────────────────────────────────────

presenceRouter.post("/", requireAuth, async (req: Request, res: Response) => {
  const parsed = ActivateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }

  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  const { location, venueName, venueType, durationMinutes } = parsed.data;
  const expiresAt = new Date(Date.now() + durationMinutes * 60_000).toISOString();
  const wkt = `SRID=4326;POINT(${location.lng} ${location.lat})`;

  // ─ Free-tier gate ─────────────────────────────────────────────────────
  // Free users get 3 Presences per ISO week. Plus users are uncapped.
  // The week boundary is Mon 00:00 UTC — same definition the profile
  // chip surfaces, so the user's mental model matches the server's.
  const userResp = await supabase
    .from("users")
    .select("is_plus")
    .eq("id", req.userId!)
    .single();
  const userRow = userResp.data as { is_plus: boolean } | null;
  const isPlus = userRow?.is_plus ?? false;

  if (!isPlus) {
    const weekStart = isoWeekStart(new Date());
    const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000);
    const countResp = await supabase
      .from("presences")
      .select("id", { count: "exact", head: true })
      .eq("user_id", req.userId!)
      .gte("started_at", weekStart.toISOString())
      .lt("started_at", weekEnd.toISOString());

    const used = countResp.count ?? 0;
    if (used >= 3) {
      res.status(402).json({
        error: "free_limit",
        weeklyUsed: used,
        resetsAt: weekEnd.toISOString()
      });
      return;
    }
  }

  const insertResp = await supabase
    .from("presences")
    .insert({
      user_id: req.userId!,
      location: wkt,
      venue_name: venueName ?? null,
      venue_type: venueType ?? null,
      expires_at: expiresAt,
      is_active: true
    })
    .select("id, expires_at")
    .single();

  const data = insertResp.data as PresenceInsertResult | null;
  if (insertResp.error || !data) {
    req.log.error({ err: insertResp.error }, "presence insert failed");
    res.status(500).json({ error: "insert_failed" });
    return;
  }

  const room = `zone:${geohashOf(location.lat, location.lng)}`;
  broadcast(room, "presence_joined", {
    id: data.id,
    userId: req.userId,
    lat: location.lat,
    lng: location.lng,
    venueName: venueName ?? null,
    expiresAt: data.expires_at
  });

  res.status(201).json({
    id: data.id,
    expiresAt: data.expires_at
  });
});

// ─── GET /api/presence/nearby ────────────────────────────────────────────────

presenceRouter.get("/nearby", requireAuth, async (req: Request, res: Response) => {
  const parsed = NearbyQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }

  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  const { lat, lng, radiusM } = parsed.data;
  const { data, error } = await supabase.rpc("nearby_presences", {
    p_lat: lat,
    p_lng: lng,
    p_radius_m: radiusM,
    p_caller: req.userId!
  });

  if (error) {
    req.log.error({ err: error }, "nearby rpc failed");
    res.status(500).json({ error: "query_failed" });
    return;
  }

  const rows = (data ?? []) as NearbyRow[];
  res.json({
    presences: rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      username: r.username,
      bio: r.bio,
      lat: r.lat,
      lng: r.lng,
      venueName: r.venue_name,
      expiresAt: r.expires_at
    }))
  });
});

// ─── DELETE /api/presence/:id ────────────────────────────────────────────────

presenceRouter.delete("/:id", requireAuth, async (req: Request, res: Response) => {
  const parsed = UuidParamSchema.safeParse(req.params);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request" });
    return;
  }

  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  // Update + select returns the row we just touched. Filtering on
  // user_id makes this owner-only — a foreign id silently no-ops.
  const deleteResp = await supabase
    .from("presences")
    .update({ is_active: false })
    .eq("id", parsed.data.id)
    .eq("user_id", req.userId!)
    .eq("is_active", true)
    .select("id, location")
    .maybeSingle();

  if (deleteResp.error) {
    req.log.error({ err: deleteResp.error }, "presence delete failed");
    res.status(500).json({ error: "delete_failed" });
    return;
  }

  const row = deleteResp.data as DeleteResult | null;
  if (row) {
    // Best-effort broadcast. The location column comes back as GeoJSON
    // when selected if Supabase's GeoJSON output is enabled. If the
    // shape doesn't match, we skip — the next nearby refresh reconciles.
    const coords = extractLngLat(row.location);
    if (coords) {
      const broadcastRoom = `zone:${geohashOf(coords.lat, coords.lng)}`;
      broadcast(broadcastRoom, "presence_left", { id: row.id });
    }
  }

  // Idempotent: returning 204 even if the row was already inactive matches
  // a typical REST pattern and keeps the iOS client simple.
  res.status(204).end();
});

/// First moment of the ISO week (Monday 00:00 UTC) containing `now`.
function isoWeekStart(now: Date): Date {
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  // getUTCDay: Sun=0..Sat=6. ISO week starts Monday: shift Sun -> 6, others -> day-1.
  const dayOfWeek = (d.getUTCDay() + 6) % 7;
  d.setUTCDate(d.getUTCDate() - dayOfWeek);
  return d;
}

function extractLngLat(loc: unknown): { lat: number; lng: number } | null {
  // PostGIS returns GeoJSON when selected if Supabase's GeoJSON output is
  // enabled, or a hex EWKB string otherwise. Parse the common shapes.
  if (loc && typeof loc === "object" && "coordinates" in (loc as Record<string, unknown>)) {
    const arr = (loc as { coordinates?: unknown[] }).coordinates;
    if (Array.isArray(arr) && typeof arr[0] === "number" && typeof arr[1] === "number") {
      return { lng: arr[0], lat: arr[1] };
    }
  }
  return null;
}
