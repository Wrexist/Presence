//  Presence backend
//  chat.ts
//  Chat-room messaging. Server enforces the 10-minute window — any POST
//  after `ends_at` is rejected with 410. Only the two participants can
//  read or post; everyone else gets 403.
//
//  Routes:
//    GET  /api/chat/:roomId            — room metadata + recent messages
//    POST /api/chat/:roomId/messages   — append one message + socket fan-out

import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { getSupabase } from "../services/supabase.js";
import { broadcast } from "../services/socketHub.js";

export const chatRouter: Router = Router();

const UuidParamSchema = z.object({ roomId: z.string().uuid() });
const MessageBodySchema = z.object({
  body: z.string().min(1).max(500)
});

type ChatRoomRow = {
  id: string;
  wave_id: string;
  user_a: string;
  user_b: string;
  started_at: string;
  ends_at: string;
};

type ChatMessageRow = {
  id: string;
  room_id: string;
  sender_id: string;
  body: string;
  created_at: string;
};

async function loadRoom(roomId: string): Promise<ChatRoomRow | null> {
  const supabase = getSupabase();
  if (!supabase) return null;
  const { data } = await supabase
    .from("chat_rooms")
    .select("id, wave_id, user_a, user_b, started_at, ends_at")
    .eq("id", roomId)
    .single();
  return (data as ChatRoomRow | null) ?? null;
}

function isParticipant(room: ChatRoomRow, userId: string): boolean {
  return room.user_a === userId || room.user_b === userId;
}

// ─── GET /api/chat/:roomId ───────────────────────────────────────────────────

chatRouter.get("/:roomId", requireAuth, async (req: Request, res: Response) => {
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

  const room = await loadRoom(parsed.data.roomId);
  if (!room) {
    res.status(404).json({ error: "not_found" });
    return;
  }
  if (!isParticipant(room, req.userId!)) {
    res.status(403).json({ error: "forbidden" });
    return;
  }

  const messagesResp = await supabase
    .from("chat_messages")
    .select("id, room_id, sender_id, body, created_at")
    .eq("room_id", room.id)
    .order("created_at", { ascending: true })
    .limit(200);

  if (messagesResp.error) {
    req.log.error({ err: messagesResp.error }, "chat list failed");
    res.status(500).json({ error: "list_failed" });
    return;
  }

  const messages = (messagesResp.data as ChatMessageRow[] | null) ?? [];
  res.json({
    room: {
      id: room.id,
      waveId: room.wave_id,
      userA: room.user_a,
      userB: room.user_b,
      startedAt: room.started_at,
      endsAt: room.ends_at
    },
    messages: messages.map((m) => ({
      id: m.id,
      roomId: m.room_id,
      senderId: m.sender_id,
      body: m.body,
      createdAt: m.created_at
    }))
  });
});

// ─── POST /api/chat/:roomId/messages ─────────────────────────────────────────

chatRouter.post("/:roomId/messages", requireAuth, async (req: Request, res: Response) => {
  const paramsParsed = UuidParamSchema.safeParse(req.params);
  const bodyParsed = MessageBodySchema.safeParse(req.body);
  if (!paramsParsed.success || !bodyParsed.success) {
    res.status(400).json({ error: "invalid_request" });
    return;
  }
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  const room = await loadRoom(paramsParsed.data.roomId);
  if (!room) {
    res.status(404).json({ error: "not_found" });
    return;
  }
  if (!isParticipant(room, req.userId!)) {
    res.status(403).json({ error: "forbidden" });
    return;
  }
  // Hard server-side enforcement of the 10-minute window. The iOS countdown
  // is just UI — never trust the client clock for the close.
  if (new Date(room.ends_at).getTime() <= Date.now()) {
    res.status(410).json({ error: "chat_closed" });
    return;
  }

  const insertResp = await supabase
    .from("chat_messages")
    .insert({
      room_id: room.id,
      sender_id: req.userId!,
      body: bodyParsed.data.body
    })
    .select("id, room_id, sender_id, body, created_at")
    .single();

  const row = insertResp.data as ChatMessageRow | null;
  if (insertResp.error || !row) {
    req.log.error({ err: insertResp.error }, "chat insert failed");
    res.status(500).json({ error: "insert_failed" });
    return;
  }

  const payload = {
    id: row.id,
    roomId: row.room_id,
    senderId: row.sender_id,
    body: row.body,
    createdAt: row.created_at
  };

  broadcast(`chat:${room.id}`, "chat_message", payload);

  res.status(201).json(payload);
});
