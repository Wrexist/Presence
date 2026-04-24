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

  CORS_ORIGINS: z
    .string()
    .default("")
    .transform((s) =>
      s.split(",").map((o) => o.trim()).filter((o) => o.length > 0)
    ),
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
  anthropicEnabled: Boolean(config.ANTHROPIC_API_KEY)
};
