//  Presence backend
//  reports.ts
//  POST /api/reports — file an abuse / safety report. Auto-blocks the
//  reported user as a side-effect so the reporter doesn't have to take
//  a second action. Moderation triage happens in Supabase Studio for
//  MVP (CLAUDE.md § Sprint 4 — Beta).

import { Router, type Request, type Response } from "express";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { getSupabase } from "../services/supabase.js";

export const reportsRouter: Router = Router();

const ReportSchema = z.object({
  reportedId: z.string().uuid(),
  category: z.enum([
    "harassment",
    "spam",
    "inappropriate",
    "unwanted_advances",
    "underage",
    "other"
  ]),
  context: z.enum(["wave", "chat", "presence", "other"]).default("other"),
  referenceId: z.string().uuid().optional(),
  detail: z.string().max(1000).optional()
});

reportsRouter.post("/", requireAuth, async (req: Request, res: Response) => {
  const parsed = ReportSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }
  if (parsed.data.reportedId === req.userId) {
    res.status(400).json({ error: "self_report" });
    return;
  }
  const supabase = getSupabase();
  if (!supabase) {
    res.status(503).json({ error: "db_unavailable" });
    return;
  }

  const { error: insertErr } = await supabase.from("reports").insert({
    reporter_id: req.userId!,
    reported_id: parsed.data.reportedId,
    category: parsed.data.category,
    context: parsed.data.context,
    reference_id: parsed.data.referenceId ?? null,
    detail: parsed.data.detail ?? null
  });
  if (insertErr) {
    req.log.error({ err: insertErr }, "report insert failed");
    res.status(500).json({ error: "report_failed" });
    return;
  }

  // Auto-block — idempotent via the unique constraint on (blocker_id,
  // blocked_id). 23505 is the duplicate code; everything else logs warn.
  const { error: blockErr } = await supabase.from("blocks").upsert(
    { blocker_id: req.userId!, blocked_id: parsed.data.reportedId },
    { onConflict: "blocker_id,blocked_id" }
  );
  if (blockErr && (blockErr as { code?: string }).code !== "23505") {
    req.log.warn({ err: blockErr }, "auto-block on report failed");
  }

  res.status(201).json({ ok: true, autoBlocked: true });
});
