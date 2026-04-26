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
  if (initialized || !featureFlags.sentryEnabled) return;
  Sentry.init({
    dsn: config.SENTRY_DSN!,
    environment: config.NODE_ENV,
    tracesSampleRate: config.SENTRY_TRACES_SAMPLE_RATE,
    // Don't ship request bodies wholesale — scrub PII first.
    beforeSend(event) {
      return scrubEvent(event);
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

interface SentryEventLike {
  request?: {
    data?: unknown;
    headers?: Record<string, unknown>;
    query_string?: string;
  };
  user?: { ip_address?: string };
}

function scrubEvent<T extends SentryEventLike>(event: T): T {
  const reqRecord = (event.request ?? {}) as { data?: unknown; headers?: Record<string, unknown> };
  if (reqRecord.data && typeof reqRecord.data === "object") {
    reqRecord.data = redactPII(reqRecord.data as Record<string, unknown>);
  }
  // Drop the IP — we don't need it and most jurisdictions treat it as PII.
  if (event.user) {
    event.user.ip_address = undefined;
  }
  // Authorization header carries the JWT — strip it.
  if (reqRecord.headers && "authorization" in reqRecord.headers) {
    reqRecord.headers.authorization = "[redacted]";
  }
  return event;
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
