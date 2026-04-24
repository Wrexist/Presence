//  Presence backend
//  presence.ts
//  Stubs for presence CRUD. Real implementations arrive in Sprint 1 once
//  the iOS LocationService is wired up and the PostGIS schema is applied.

import { Router, type Request, type Response } from "express";
import { z } from "zod";

export const presenceRouter: Router = Router();

const ActivateSchema = z.object({
  userId: z.string().uuid(),
  location: z.object({
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180)
  }),
  venueName: z.string().min(1).max(120).optional(),
  venueType: z.enum(["cafe", "park", "gym", "library", "bar", "coworking", "other"]).optional(),
  durationMinutes: z.number().int().min(15).max(180).default(180)
});

presenceRouter.post("/", (req: Request, res: Response) => {
  const parsed = ActivateSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: "invalid_request", details: parsed.error.flatten() });
    return;
  }
  // TODO(sprint-1): insert into Supabase presences with PostGIS point.
  res.status(501).json({ error: "not_implemented", hint: "Sprint 1: wire PostGIS insert" });
});

presenceRouter.get("/nearby", (_req: Request, res: Response) => {
  // TODO(sprint-1): ST_DWithin query, 50-presence cap, blocked-user filter.
  res.status(501).json({ error: "not_implemented", hint: "Sprint 1: ST_DWithin query" });
});

presenceRouter.delete("/:id", (_req: Request, res: Response) => {
  // TODO(sprint-1): deactivate presence, broadcast over socket.
  res.status(501).json({ error: "not_implemented" });
});
