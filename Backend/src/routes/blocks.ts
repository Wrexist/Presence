//  Presence backend
//  blocks.ts
//  Lightweight block management. Blocks are mutual-effect: once user A
//  blocks user B, neither side can wave at the other, and B drops out of
//  A's nearby_presences results (the RPC already filters mutually).
//
//  Routes:
//    GET    /api/blocks          — list users I've blocked
//    POST   /api/blocks          — block someone
//    DELETE /api/blocks/:userId  — unblock

import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { getSupabase } from "../services/supabase.js";

export const blocksRouter: Router = Router();

const BlockSchema = z.object({ blockedId: z.string().uuid() });
const UuidParamSchema = z.object({ userId: z.string().uuid() });

blocksRouter.get("/", requireAuth, async (req: Request, res: Response) => {
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }
  // Hydrate the blocked user's username so the settings list reads cleanly.
  const blocksResp = await supabase
    .from("blocks")
    .select("blocked_id, created_at")
    .eq("blocker_id", req.userId!)
    .order("created_at", { ascending: false });

  type BlockRow = { blocked_id: string; created_at: string };
  const blocks = (blocksResp.data as BlockRow[] | null) ?? [];
  if (blocks.length === 0) {
    res.json({ blocks: [] });
    return;
  }

  const userResp = await supabase
    .from("users")
    .select("id, username")
    .in("id", blocks.map((b) => b.blocked_id));

  type UserRow = { id: string; username: string };
  const users = (userResp.data as UserRow[] | null) ?? [];
  const usernameById = new Map(users.map((u) => [u.id, u.username]));

  res.json({
    blocks: blocks.map((b) => ({
      blockedId: b.blocked_id,
      username: usernameById.get(b.blocked_id) ?? "Unknown",
      createdAt: b.created_at
    }))
  });
});

blocksRouter.post("/", requireAuth, async (req: Request, res: Response) => {
  const parsed = BlockSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request" });
    return;
  }
  if (parsed.data.blockedId === req.userId) {
    res.status(400).json({ error: "self_block" });
    return;
  }
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }
  const { error } = await supabase.from("blocks").upsert(
    { blocker_id: req.userId!, blocked_id: parsed.data.blockedId },
    { onConflict: "blocker_id,blocked_id" }
  );
  if (error) {
    req.log.error({ err: error }, "block upsert failed");
    res.status(500).json({ error: "block_failed" });
    return;
  }
  res.status(201).json({ ok: true });
});

blocksRouter.delete("/:userId", requireAuth, async (req: Request, res: Response) => {
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
  const { error } = await supabase
    .from("blocks")
    .delete()
    .eq("blocker_id", req.userId!)
    .eq("blocked_id", parsed.data.userId);
  if (error) {
    req.log.error({ err: error }, "unblock failed");
    res.status(500).json({ error: "unblock_failed" });
    return;
  }
  res.status(204).end();
});
