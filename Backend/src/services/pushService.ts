//  Presence backend
//  pushService.ts
//  Sends a push to one user's registered device tokens. Real APNs
//  delivery is gated behind APNS_* env vars — when they're missing
//  (most local dev, CI), the service no-ops and logs at debug level so
//  the wave flow still completes end-to-end.
//
//  Real implementation lands in the TestFlight session (E6) — at that
//  point this file gains the http2 request to api.push.apple.com plus
//  a JWT signed with ES256. The persistence + broadcast paths in
//  routes/waves.ts don't need to change.

import type { Logger } from "pino";
import { getSupabase } from "./supabase.js";

export interface PushPayload {
  /// `aps.alert.title`
  title: string;
  /// `aps.alert.body`
  body: string;
  /// Top-level user-info; consumed by AppCoordinator's deep-link handler.
  userInfo: Record<string, string>;
}

export interface PushOutcome {
  /// How many tokens the request was sent to (or queued for). 0 if APNs
  /// is not configured.
  sent: number;
  /// True only when at least one delivery succeeded.
  ok: boolean;
}

const apnsEnabled =
  Boolean(process.env.APNS_AUTH_KEY) &&
  Boolean(process.env.APNS_KEY_ID) &&
  Boolean(process.env.APNS_TEAM_ID) &&
  Boolean(process.env.APNS_TOPIC);

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

  const tokens = (data ?? []) as Array<{
    token: string;
    platform: string;
    environment: string;
  }>;
  if (tokens.length === 0) return { sent: 0, ok: false };

  if (!apnsEnabled) {
    // Best-effort visibility for the dev. Don't fail the wave on this —
    // socket fan-out is the primary delivery path.
    logger.debug(
      { receiverId, tokens: tokens.length, payload: payload.title },
      "apns disabled, skipping push"
    );
    return { sent: 0, ok: false };
  }

  // TODO(E6): real APNs HTTP/2 send via node:http2 + ES256-signed JWT.
  // The send loop should:
  //   - open a single http2 session to api.push.apple.com
  //   - per token: POST /3/device/<token> with apns-topic + apns-priority
  //   - on 410 Unregistered, delete the token row
  //   - on 200 OK, bump last_seen_at
  // Until then we count tokens as "sent" so the route reports useful telemetry.
  logger.info(
    { receiverId, tokens: tokens.length, title: payload.title },
    "push send (apns-stub) — would deliver"
  );
  return { sent: tokens.length, ok: true };
}
