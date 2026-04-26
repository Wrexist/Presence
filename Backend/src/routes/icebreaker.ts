//  Presence backend
//  icebreaker.ts
//  POST /api/icebreaker — generates a single icebreaker via Claude.
//  Auth required (sender id is taken from the JWT, never the body or
//  headers). Rate limited to 1 request / 30s per sender.

import { Router, type Request, type Response } from "express";
import { requireAuth } from "../middleware/auth.js";
import { generateIcebreaker, IcebreakerRequestSchema } from "../services/matchingService.js";

export const icebreakerRouter: Router = Router();

// In-memory sender throttle. Fine for single-instance dev; replace with
// Redis or a DB-backed counter when we horizontally scale.
const lastCallAt = new Map<string, number>();
const RATE_LIMIT_MS = 30_000;

icebreakerRouter.post("/", requireAuth, async (req: Request, res: Response) => {
  const senderId = req.userId!;

  const now = Date.now();
  const last = lastCallAt.get(senderId) ?? 0;
  if (now - last < RATE_LIMIT_MS) {
    const retryAfterMs = RATE_LIMIT_MS - (now - last);
    res.setHeader("Retry-After", Math.ceil(retryAfterMs / 1000));
    res.status(429).json({
      error: "rate_limited",
      retryAfterMs
    });
    return;
  }

  const parsed = IcebreakerRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: "invalid_request",
      details: parsed.error.flatten()
    });
    return;
  }

  lastCallAt.set(senderId, now);
  const result = await generateIcebreaker(parsed.data);
  res.json(result);
});
