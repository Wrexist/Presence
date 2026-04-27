//  Presence backend
//  debugSentry.ts
//  GET /debug-sentry — intentionally throws so Sentry can capture an
//  event end-to-end. Gated to non-production environments.

import { Router, type Request, type Response } from "express";
import { config } from "../config.js";

export const debugSentryRouter: Router = Router();

debugSentryRouter.get("/", (_req: Request, _res: Response) => {
  if (config.NODE_ENV === "production") {
    // No 404 — just refuse to even mount logic in prod.
    throw new Error("disabled in production");
  }
  throw new Error("Sentry verification: this is intentional.");
});
