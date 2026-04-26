//  Presence backend
//  waves.ts
//  Three routes for the wave + mutual-wave flow:
//    POST /api/waves                 — send a wave + push + socket fan-out
//    POST /api/waves/:id/respond     — wave back / decline; mutual creates a connection
//    GET  /api/waves                 — list incoming + outgoing for the auth user
//
//  All routes require auth. Sender id always comes from the JWT (req.userId);
//  the body never carries it. Block-list filter applies on send.

import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { getSupabase } from "../services/supabase.js";
import { broadcast } from "../services/socketHub.js";
import { sendPushToUser } from "../services/pushService.js";

export const wavesRouter: Router = Router();

const WAVE_TTL_HOURS = 2;

const SendWaveSchema = z.object({
  receiverId: z.string().uuid(),
  icebreaker: z.string().min(20).max(200)
});

const RespondSchema = z.object({
  accepted: z.boolean()
});

const UuidParamSchema = z.object({ id: z.string().uuid() });

type WaveRow = {
  id: string;
  sender_id: string;
  receiver_id: string;
  icebreaker: string;
  status: "sent" | "waved_back" | "expired" | "blocked";
  sent_at: string;
  responded_at: string | null;
  expires_at: string;
};

type SenderProfile = { id: string; username: string; bio: string | null };

// ─── POST /api/waves ─────────────────────────────────────────────────────────

wavesRouter.post("/", requireAuth, async (req: Request, res: Response) => {
  const parsed = SendWaveSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }

  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  const senderId = req.userId!;
  const { receiverId, icebreaker } = parsed.data;

  if (senderId === receiverId) {
    res.status(400).json({ error: "self_wave" });
    return;
  }

  // Block check — either direction. A blocked sender can't reach the receiver,
  // and a sender who has blocked the receiver shouldn't be able to wave at them.
  const blockResp = await supabase
    .from("blocks")
    .select("blocker_id")
    .or(
      `and(blocker_id.eq.${senderId},blocked_id.eq.${receiverId}),` +
        `and(blocker_id.eq.${receiverId},blocked_id.eq.${senderId})`
    )
    .limit(1);

  if (blockResp.error) {
    req.log.error({ err: blockResp.error }, "block lookup failed");
    res.status(500).json({ error: "block_check_failed" });
    return;
  }
  if ((blockResp.data ?? []).length > 0) {
    res.status(403).json({ error: "blocked" });
    return;
  }

  // Insert the wave with a 2h expiry. status defaults to 'sent' in the schema.
  const expiresAt = new Date(Date.now() + WAVE_TTL_HOURS * 60 * 60 * 1000).toISOString();
  const insertResp = await supabase
    .from("waves")
    .insert({
      sender_id: senderId,
      receiver_id: receiverId,
      icebreaker,
      expires_at: expiresAt
    })
    .select("id, sender_id, receiver_id, icebreaker, status, sent_at, responded_at, expires_at")
    .single();

  const wave = insertResp.data as WaveRow | null;
  if (insertResp.error || !wave) {
    req.log.error({ err: insertResp.error }, "wave insert failed");
    res.status(500).json({ error: "insert_failed" });
    return;
  }

  // Fetch sender profile for the push + socket payload. Don't block the
  // wave response on this — fall back to a generic title if it fails.
  const senderResp = await supabase
    .from("users")
    .select("id, username, bio")
    .eq("id", senderId)
    .single();
  const sender = (senderResp.data as SenderProfile | null) ?? {
    id: senderId,
    username: "Someone",
    bio: null
  };

  // Socket fan-out: emit on a per-user inbox room. The iOS SocketService
  // joins `user:<myId>` automatically on subscribe (B5/B6 follow-up — for
  // now broadcast on a `wave:<receiverId>` event name that any listener
  // can switch on).
  broadcast(`user:${receiverId}`, "wave_received", {
    id: wave.id,
    senderId: sender.id,
    senderUsername: sender.username,
    senderBio: sender.bio,
    icebreaker: wave.icebreaker,
    sentAt: wave.sent_at,
    expiresAt: wave.expires_at
  });

  // Push (best-effort, fully async).
  void sendPushToUser(
    receiverId,
    {
      title: `${sender.username} waved at you`,
      body: wave.icebreaker,
      userInfo: { type: "wave_received", waveId: wave.id }
    },
    req.log
  );

  res.status(201).json({
    id: wave.id,
    expiresAt: wave.expires_at,
    status: wave.status
  });
});

// ─── POST /api/waves/:id/respond ─────────────────────────────────────────────

wavesRouter.post("/:id/respond", requireAuth, async (req: Request, res: Response) => {
  const paramsParsed = UuidParamSchema.safeParse(req.params);
  const bodyParsed = RespondSchema.safeParse(req.body);
  if (!paramsParsed.success || !bodyParsed.success) {
    res.status(400).json({ error: "invalid_request" });
    return;
  }

  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  const callerId = req.userId!;
  const waveId = paramsParsed.data.id;

  // Load + verify caller is the receiver.
  const waveResp = await supabase
    .from("waves")
    .select("id, sender_id, receiver_id, status, expires_at")
    .eq("id", waveId)
    .single();
  const wave = waveResp.data as WaveRow | null;
  if (!wave) {
    res.status(404).json({ error: "not_found" });
    return;
  }
  if (wave.receiver_id !== callerId) {
    res.status(403).json({ error: "not_receiver" });
    return;
  }
  if (new Date(wave.expires_at).getTime() < Date.now()) {
    res.status(410).json({ error: "expired" });
    return;
  }

  if (!bodyParsed.data.accepted) {
    // Decline = leave the wave alone; it'll expire on its own. Just stamp
    // responded_at so the sender's UI can move on.
    await supabase
      .from("waves")
      .update({ responded_at: new Date().toISOString() })
      .eq("id", waveId);
    res.status(200).json({ mutual: false });
    return;
  }

  // Accept → flip to waved_back. Always a mutual moment from the receiver's
  // POV; we record the connection here.
  const nowIso = new Date().toISOString();
  const updateResp = await supabase
    .from("waves")
    .update({ status: "waved_back", responded_at: nowIso })
    .eq("id", waveId)
    .select("id")
    .single();

  if (updateResp.error) {
    req.log.error({ err: updateResp.error }, "wave update failed");
    res.status(500).json({ error: "update_failed" });
    return;
  }

  // Insert the connection. The unique pair index prevents duplicates if
  // both sides hit "wave back" at nearly the same time.
  const connectionResp = await supabase
    .from("connections")
    .insert({
      user_a: wave.sender_id,
      user_b: wave.receiver_id
    })
    .select("id")
    .maybeSingle();

  if (connectionResp.error) {
    // 23505 = unique violation = already connected. Treat as success.
    if (connectionResp.error.code !== "23505") {
      req.log.warn({ err: connectionResp.error }, "connection insert failed");
    }
  }

  // Broadcast on both inbox rooms so each side's UI flips into the
  // celebration / chat path.
  for (const userId of [wave.sender_id, wave.receiver_id]) {
    broadcast(`user:${userId}`, "wave_mutual", {
      waveId: wave.id,
      senderId: wave.sender_id,
      receiverId: wave.receiver_id,
      respondedAt: nowIso
    });
  }

  // Push the original sender — they're the one who's been waiting.
  void sendPushToUser(
    wave.sender_id,
    {
      title: "You connected!",
      body: "You both waved. Time to say hi in person.",
      userInfo: { type: "wave_mutual", waveId: wave.id }
    },
    req.log
  );

  res.status(200).json({ mutual: true, waveId: wave.id });
});

// ─── GET /api/waves ──────────────────────────────────────────────────────────

wavesRouter.get("/", requireAuth, async (req: Request, res: Response) => {
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  const callerId = req.userId!;
  const nowIso = new Date().toISOString();

  // Two parallel queries — server-side join would be cleaner but the
  // PostgREST embedded-resource syntax adds noise; this is fine at this
  // scale.
  const incomingResp = await supabase
    .from("waves")
    .select("id, sender_id, receiver_id, icebreaker, status, sent_at, expires_at")
    .eq("receiver_id", callerId)
    .gt("expires_at", nowIso)
    .order("sent_at", { ascending: false })
    .limit(50);

  const outgoingResp = await supabase
    .from("waves")
    .select("id, sender_id, receiver_id, icebreaker, status, sent_at, expires_at")
    .eq("sender_id", callerId)
    .gt("expires_at", nowIso)
    .order("sent_at", { ascending: false })
    .limit(50);

  if (incomingResp.error || outgoingResp.error) {
    req.log.error(
      { in: incomingResp.error, out: outgoingResp.error },
      "wave list failed"
    );
    res.status(500).json({ error: "list_failed" });
    return;
  }

  const map = (rows: WaveRow[] | null) =>
    (rows ?? []).map((r) => ({
      id: r.id,
      senderId: r.sender_id,
      receiverId: r.receiver_id,
      icebreaker: r.icebreaker,
      status: r.status,
      sentAt: r.sent_at,
      expiresAt: r.expires_at
    }));

  res.json({
    incoming: map(incomingResp.data as WaveRow[] | null),
    outgoing: map(outgoingResp.data as WaveRow[] | null)
  });
});
