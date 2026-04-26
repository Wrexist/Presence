//  Presence backend
//  users.ts
//  Self-only user endpoints. Currently just push-token registration; will
//  grow to cover bio/avatar updates and account delete (Phase D).

import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { getSupabase } from "../services/supabase.js";

export const usersRouter: Router = Router();

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

  // Upsert keyed on token (unique). If the same physical device reinstalls
  // and re-registers, the user_id may change — onConflict updates that too.
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
