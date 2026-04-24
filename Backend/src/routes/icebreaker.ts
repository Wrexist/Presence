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
  // Sender identity: we don't have auth yet, so use a header + IP fallback.
  // Replace with the authenticated user id once Supabase Auth lands.
  const senderId =
    (req.header("x-sender-id") ?? req.ip ?? "anonymous").slice(0, 64);

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
