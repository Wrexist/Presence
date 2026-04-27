//  Presence backend
//  config.ts
//  Loads environment variables and validates them with Zod.
//  Fails fast on startup if anything required is missing.

import "dotenv/config";
import { z } from "zod";

const schema = z.object({
  PORT: z.coerce.number().int().positive().default(3000),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  LOG_LEVEL: z.enum(["fatal", "error", "warn", "info", "debug", "trace"]).default("info"),

  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),

  ANTHROPIC_API_KEY: z.string().min(1).optional(),

  SENTRY_DSN: z.string().url().optional(),
  SENTRY_TRACES_SAMPLE_RATE: z.coerce.number().min(0).max(1).default(0.1),

  // Apple Push Notification service. The four APNS_* env vars are all
  // required together for a real send; missing any disables push and
  // pushService falls back to a no-op log path.
  APNS_AUTH_KEY: z.string().optional(),       // raw .p8 PEM contents (multiline)
  APNS_KEY_ID: z.string().optional(),         // 10-char ASCII key id from Apple Developer
  APNS_TEAM_ID: z.string().optional(),        // 10-char team id
  APNS_TOPIC: z.string().optional(),          // bundle id, e.g. app.presence.ios
  APNS_PRODUCTION: z
    .string()
    .default("false")
    .transform((s) => s === "true"),

  CORS_ORIGINS: z
    .string()
    .default("")
    .transform((s) =>
      s.split(",").map((o) => o.trim()).filter((o) => o.length > 0)
    ),

  // Express `trust proxy` setting. Set to the number of proxy hops in front
  // of the app (Railway/Render/Fly typically = 1). `true` trusts everything;
  // `false` / `0` trusts nothing (the default, safe for local dev).
  // When false, req.ip returns the direct socket peer — do not use it for
  // per-user throttling behind a proxy.
  TRUST_PROXY: z
    .string()
    .default("0")
    .transform((s) => {
      if (s === "true") return true;
      if (s === "false") return false;
      const n = Number(s);
      return Number.isFinite(n) ? n : false;
    })
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  // eslint-disable-next-line no-console
  console.error("Invalid environment configuration:", parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const config = parsed.data;

export const featureFlags = {
  supabaseEnabled: Boolean(config.SUPABASE_URL && config.SUPABASE_SERVICE_ROLE_KEY),
  anthropicEnabled: Boolean(config.ANTHROPIC_API_KEY),
  sentryEnabled: Boolean(config.SENTRY_DSN),
  apnsEnabled: Boolean(
    config.APNS_AUTH_KEY &&
      config.APNS_KEY_ID &&
      config.APNS_TEAM_ID &&
      config.APNS_TOPIC
  )
};
