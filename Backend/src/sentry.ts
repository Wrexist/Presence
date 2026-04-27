//  Presence backend
//  sentry.ts
//  Wraps @sentry/node init + Express handlers. No-ops cleanly when
//  SENTRY_DSN is unset (dev / CI). Scrubs phone + bio fields from
//  request bodies on every event so PII never leaves the box.

import * as Sentry from "@sentry/node";
import type { Express, Request } from "express";
import { config, featureFlags } from "./config.js";

let initialized = false;

export function initSentry(): void {
  if (initialized || !featureFlags.sentryEnabled || !config.SENTRY_DSN) return;
  Sentry.init({
    dsn: config.SENTRY_DSN,
    environment: config.NODE_ENV,
    tracesSampleRate: config.SENTRY_TRACES_SAMPLE_RATE,
    // Don't ship request bodies wholesale — scrub PII first.
    beforeSend(event) {
      scrubEvent(event);
      return event;
    },
    beforeBreadcrumb(breadcrumb) {
      // Drop any breadcrumb whose data carries a phone or bio.
      const data = breadcrumb.data ?? {};
      if ("phone" in data) data.phone = "[redacted]";
      if ("bio" in data) data.bio = "[redacted]";
      return breadcrumb;
    }
  });
  initialized = true;
}

/// Express wiring. Call after `createApp()` has built the app but before
/// any custom error middleware so Sentry's request handler is first and
/// its error handler is last among error middlewares.
export function attachSentry(app: Express): void {
  if (!initialized) return;
  Sentry.setupExpressErrorHandler(app);
}

/// Helper: capture a typed error with extra context. Routes call this
/// for cases worth a Sentry event (5xx-mapped errors, unexpected DB
/// failures). Idempotent if Sentry isn't initialized.
export function captureError(err: unknown, context?: Record<string, unknown>): void {
  if (!initialized) return;
  Sentry.captureException(err, { extra: context });
}

// MARK: - Scrubbing

/// Mutates the event in place to remove PII before it ships to Sentry.
/// We type the event loosely (Record<string, unknown>) rather than against
/// the SDK's strict ErrorEvent so future SDK type drift doesn't break this.
function scrubEvent(event: Sentry.ErrorEvent): void {
  const req = event.request as Record<string, unknown> | undefined;
  if (req && typeof req.data === "object" && req.data !== null) {
    req.data = redactPII(req.data as Record<string, unknown>);
  }
  // Drop the IP — we don't need it and most jurisdictions treat it as PII.
  if (event.user) {
    event.user.ip_address = undefined;
  }
  // Authorization header carries the JWT — strip it.
  const headers = req?.headers as Record<string, unknown> | undefined;
  if (headers && "authorization" in headers) {
    headers.authorization = "[redacted]";
  }
}

const REDACT_KEYS = new Set(["phone", "bio", "token", "password", "icebreaker", "body"]);

function redactPII(input: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input)) {
    if (REDACT_KEYS.has(key)) {
      out[key] = "[redacted]";
    } else if (value && typeof value === "object" && !Array.isArray(value)) {
      out[key] = redactPII(value as Record<string, unknown>);
    } else {
      out[key] = value;
    }
  }
  return out;
}

/// Optional Express helper for route-level breadcrumbs.
export function breadcrumb(_req: Request, name: string, data?: Record<string, unknown>): void {
  if (!initialized) return;
  Sentry.addBreadcrumb({ category: "route", message: name, data, level: "info" });
}
