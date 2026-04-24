//  Presence backend
//  icebreaker.ts
//  POST /api/icebreaker — generates a single icebreaker via Claude.
//  Rate limited to 1 request / 30s per sender to control cost and abuse.

import { Router, type Request, type Response } from "express";
import { generateIcebreaker, IcebreakerRequestSchema } from "../services/matchingService.js";

export const icebreakerRouter: Router = Router();

// In-memory sender throttle. Fine for single-instance dev; replace with
// Redis or a DB-backed counter when we horizontally scale.
const lastCallAt = new Map<string, number>();
const RATE_LIMIT_MS = 30_000;

icebreakerRouter.post("/", async (req: Request, res: Response) => {
  // Sender identity — required. We don't have auth yet, so the client
  // must pass a stable id via x-sender-id. Falling back to req.ip collides
  // across users behind a reverse proxy or NAT (all requests see the same
  // IP) and would rate-limit unrelated users together. Replace with the
  // authenticated user id once Supabase Auth lands.
  const header = req.header("x-sender-id");
  if (!header || header.length === 0 || header.length > 64) {
    res.status(400).json({
      error: "missing_sender_id",
      message: "x-sender-id header is required (1-64 chars)"
    });
    return;
  }
  const senderId = header;

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
