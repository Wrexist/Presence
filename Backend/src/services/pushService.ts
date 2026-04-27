//  Presence backend
//  pushService.ts
//  Sends a push to one user's registered device tokens via the real APNs
//  HTTP/2 client in apns.ts. No-ops cleanly when APNS_* env vars are
//  unset (CI, local dev) — the wave flow's primary delivery path is
//  the socket fan-out, push is the fallback for backgrounded apps.
//
//  On 410 Unregistered the matching device_tokens row is deleted so the
//  next push to the same user doesn't try the dead token again. Other
//  failures are logged and discarded — the wave still succeeded as far
//  as the route is concerned.

import type { Logger } from "pino";
import { featureFlags } from "../config.js";
import { getSupabase } from "./supabase.js";
import { sendApns, type ApnsEnvironment } from "./apns.js";

export interface PushPayload {
  /// `aps.alert.title`
  title: string;
  /// `aps.alert.body`
  body: string;
  /// Top-level user-info; consumed by AppCoordinator's deep-link handler.
  userInfo: Record<string, string>;
}

export interface PushOutcome {
  /// How many tokens were successfully delivered to (200 from APNs).
  /// 0 if APNs is not configured.
  sent: number;
  /// True only when at least one delivery succeeded.
  ok: boolean;
}

interface DeviceTokenRow {
  token: string;
  platform: string;
  environment: string;
}

export async function sendPushToUser(
  receiverId: string,
  payload: PushPayload,
  logger: Logger
): Promise<PushOutcome> {
  const supabase = getSupabase();
  if (!supabase) return { sent: 0, ok: false };

  const { data, error } = await supabase
    .from("device_tokens")
    .select("token, platform, environment")
    .eq("user_id", receiverId);

  if (error) {
    logger.warn({ err: error }, "device-token lookup failed");
    return { sent: 0, ok: false };
  }

  const tokens = (data ?? []) as DeviceTokenRow[];
  if (tokens.length === 0) return { sent: 0, ok: false };

  if (!featureFlags.apnsEnabled) {
    logger.debug(
      { receiverId, tokens: tokens.length, payload: payload.title },
      "apns disabled, skipping push"
    );
    return { sent: 0, ok: false };
  }

  let delivered = 0;

  // Send sequentially. Apple recommends parallelism within a single
  // HTTP/2 session, but the volume of tokens per user is tiny (1-3
  // typically) so the overhead of parallelism isn't worth the extra
  // error-handling state. Revisit if usage grows.
  for (const row of tokens) {
    if (row.platform !== "ios") continue;
    const env: ApnsEnvironment = row.environment === "production" ? "production" : "sandbox";
    const result = await sendApns(
      {
        token: row.token,
        environment: env,
        alert: { title: payload.title, body: payload.body },
        userInfo: payload.userInfo,
        priority: 10
      },
      logger
    );

    if (result.status === "ok") {
      delivered++;
      // Bump last_seen_at so we know this token is still alive. Best
      // effort — failures here don't affect the user.
      await supabase
        .from("device_tokens")
        .update({ last_seen_at: new Date().toISOString() })
        .eq("token", row.token);
    } else if (result.status === "unregistered") {
      // Token's gone. Drop the row so the next push doesn't retry.
      await supabase.from("device_tokens").delete().eq("token", row.token);
      logger.info({ receiverId }, "apns unregistered — token removed");
    } else if (result.status === "bad_token") {
      // Bad shape, not transient — same outcome as unregistered.
      await supabase.from("device_tokens").delete().eq("token", row.token);
      logger.warn({ receiverId }, "apns bad_token — token removed");
    } else {
      logger.warn({ result, receiverId }, "apns send failed");
    }
  }

  return { sent: delivered, ok: delivered > 0 };
}
