//  Presence backend
//  health.ts
//  GET /health — liveness probe. Reports which optional services are wired up.

import { Router } from "express";
import { featureFlags } from "../config.js";

export const healthRouter: Router = Router();

healthRouter.get("/", (_req, res) => {
  res.json({
    ok: true,
    service: "presence-backend",
    version: "0.1.0",
    features: {
      supabase: featureFlags.supabaseEnabled,
      anthropic: featureFlags.anthropicEnabled
    },
    time: new Date().toISOString()
  });
});
