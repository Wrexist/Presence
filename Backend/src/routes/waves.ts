//  Presence backend
//  waves.ts
//  Stubs for the wave + mutual-wave flow. Sprint 2 fills these in.

import { Router, type Request, type Response } from "express";
import { z } from "zod";

export const wavesRouter: Router = Router();

const SendWaveSchema = z.object({
  senderId: z.string().uuid(),
  receiverId: z.string().uuid(),
  icebreaker: z.string().min(20).max(200)
});

wavesRouter.post("/", (req: Request, res: Response) => {
  const parsed = SendWaveSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }
  // TODO(sprint-2): insert wave, push-notify receiver, schedule 2h expiry.
  res.status(501).json({ error: "not_implemented", hint: "Sprint 2: wave persistence + APNs" });
});

wavesRouter.post("/:id/respond", (_req: Request, res: Response) => {
  // TODO(sprint-2): mark mutual, create Connection row, open chat room.
  res.status(501).json({ error: "not_implemented" });
});
