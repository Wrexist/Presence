//  Presence backend
//  apns.ts
//  Apple Push Notification service client over HTTP/2 with an ES256-signed
//  JWT. No external deps — node:http2 + node:crypto handle the entire
//  protocol. Sessions are kept open and reused across sends; the JWT is
//  regenerated every 30 minutes (Apple's hard cap is 60). On 410 the
//  caller is told to delete the device token row; on 401/403 the JWT is
//  invalidated and reissued before the next send.

import { connect as http2Connect, type ClientHttp2Session, constants } from "node:http2";
import { createPrivateKey, createSign } from "node:crypto";
import type { Logger } from "pino";
import { config, featureFlags } from "../config.js";

export type ApnsEnvironment = "production" | "sandbox";

export interface ApnsAlert {
  title: string;
  body: string;
}

export interface ApnsSendInput {
  token: string;
  environment: ApnsEnvironment;
  alert: ApnsAlert;
  /// Top-level user-info that the iOS AppDelegate's notification handler
  /// will read. Sits ALONGSIDE the `aps` block in the JSON payload.
  userInfo: Record<string, string>;
  /// 5 = low priority (default); 10 = immediate. Waves are immediate.
  priority?: 5 | 10;
}

export type ApnsSendResult =
  | { status: "ok"; httpStatus: 200 }
  | { status: "unregistered" }    // 410 — caller should delete the row
  | { status: "bad_token" }       // 400 BadDeviceToken / TopicDisallowed etc.
  | { status: "auth_error" }      // 401 / 403 — JWT cycled, retry once
  | { status: "transient_error"; httpStatus: number; reason?: string };

const HOSTS: Record<ApnsEnvironment, string> = {
  production: "api.push.apple.com",
  sandbox: "api.sandbox.push.apple.com"
};

// JWTs live up to 60 minutes per Apple; we rotate at 30 to leave margin.
const JWT_TTL_MS = 30 * 60 * 1000;

interface CachedJwt {
  token: string;
  generatedAt: number;
}

let cachedJwt: CachedJwt | null = null;
const sessions: Partial<Record<ApnsEnvironment, ClientHttp2Session>> = {};

// MARK: - Public API

export async function sendApns(input: ApnsSendInput, logger: Logger): Promise<ApnsSendResult> {
  if (!featureFlags.apnsEnabled) {
    // Caller is responsible for falling back to the no-op log path; the
    // pushService layer handles that. We never get here when disabled.
    return { status: "transient_error", httpStatus: 0, reason: "apns_disabled" };
  }

  try {
    const result = await sendOnce(input, logger);
    if (result.status === "auth_error") {
      // Force a fresh JWT and retry exactly once.
      cachedJwt = null;
      logger.warn("apns auth_error — retrying with new JWT");
      return await sendOnce(input, logger);
    }
    return result;
  } catch (err) {
    logger.error({ err }, "apns send threw");
    return { status: "transient_error", httpStatus: 0, reason: (err as Error).message };
  }
}

/// Close all open HTTP/2 sessions. Call from the index.ts SIGTERM handler.
export function closeApns(): void {
  for (const env of Object.keys(sessions) as ApnsEnvironment[]) {
    const session = sessions[env];
    if (session && !session.closed) {
      session.close();
    }
    sessions[env] = undefined;
  }
  cachedJwt = null;
}

// MARK: - Send loop (single attempt)

async function sendOnce(input: ApnsSendInput, logger: Logger): Promise<ApnsSendResult> {
  const session = await getSession(input.environment, logger);
  const jwt = getJwt();
  const body = buildPayload(input);

  return new Promise<ApnsSendResult>((resolve) => {
    const req = session.request({
      [constants.HTTP2_HEADER_METHOD]: "POST",
      [constants.HTTP2_HEADER_PATH]: `/3/device/${input.token}`,
      [constants.HTTP2_HEADER_AUTHORITY]: HOSTS[input.environment],
      [constants.HTTP2_HEADER_SCHEME]: "https",
      [constants.HTTP2_HEADER_CONTENT_TYPE]: "application/json",
      "apns-topic": config.APNS_TOPIC!,
      "apns-push-type": "alert",
      "apns-priority": String(input.priority ?? 10),
      "apns-expiration": "0",
      authorization: `bearer ${jwt}`
    });

    let status = 0;
    let chunks = "";

    req.on("response", (headers) => {
      status = Number(headers[constants.HTTP2_HEADER_STATUS]) || 0;
    });
    req.on("data", (chunk: Buffer) => {
      chunks += chunk.toString("utf8");
    });
    req.on("end", () => {
      resolve(mapResponse(status, chunks));
    });
    req.on("error", (err) => {
      logger.warn({ err, token: redactToken(input.token) }, "apns request error");
      resolve({ status: "transient_error", httpStatus: 0, reason: err.message });
    });

    req.setEncoding("utf8");
    req.write(body);
    req.end();
  });
}

function mapResponse(status: number, body: string): ApnsSendResult {
  if (status === 200) return { status: "ok", httpStatus: 200 };

  let reason: string | undefined;
  try {
    const parsed = JSON.parse(body) as { reason?: string };
    reason = parsed.reason;
  } catch { /* body wasn't JSON — fine */ }

  if (status === 410 || reason === "Unregistered" || reason === "BadDeviceToken") {
    return { status: "unregistered" };
  }
  if (status === 400) return { status: "bad_token" };
  if (status === 401 || status === 403) return { status: "auth_error" };
  return { status: "transient_error", httpStatus: status, reason };
}

// MARK: - Payload

function buildPayload(input: ApnsSendInput): string {
  // Apple caps payload at 4 KB for alerts; we're well under that. The
  // `aps.alert` shape is the only required key; everything else is
  // surfaced to the iOS app's notification.userInfo.
  const payload: Record<string, unknown> = {
    aps: {
      alert: { title: input.alert.title, body: input.alert.body },
      sound: "default"
    },
    ...input.userInfo
  };
  return JSON.stringify(payload);
}

// MARK: - HTTP/2 session

function getSession(env: ApnsEnvironment, logger: Logger): ClientHttp2Session {
  const existing = sessions[env];
  if (existing && !existing.closed && !existing.destroyed) {
    return existing;
  }
  const url = `https://${HOSTS[env]}`;
  const session = http2Connect(url);
  session.on("error", (err) => {
    logger.warn({ err, env }, "apns http2 session error");
  });
  session.on("goaway", () => {
    logger.info({ env }, "apns goaway — session will reopen on next send");
    sessions[env] = undefined;
  });
  session.on("close", () => {
    sessions[env] = undefined;
  });
  // No keep-alive ping; Apple closes idle sessions after a few minutes
  // and we transparently reopen above. Saves a heartbeat we don't need.
  sessions[env] = session;
  return session;
}

// MARK: - JWT (ES256)

function getJwt(): string {
  if (cachedJwt && Date.now() - cachedJwt.generatedAt < JWT_TTL_MS) {
    return cachedJwt.token;
  }
  const token = makeJwt();
  cachedJwt = { token, generatedAt: Date.now() };
  return token;
}

function makeJwt(): string {
  const header = { alg: "ES256", kid: config.APNS_KEY_ID! };
  const claims = {
    iss: config.APNS_TEAM_ID!,
    iat: Math.floor(Date.now() / 1000)
  };
  const headerEncoded = base64url(JSON.stringify(header));
  const claimsEncoded = base64url(JSON.stringify(claims));
  const signingInput = `${headerEncoded}.${claimsEncoded}`;

  const key = createPrivateKey({
    key: config.APNS_AUTH_KEY!,
    format: "pem"
  });

  const signer = createSign("SHA256");
  signer.update(signingInput);
  // Apple expects raw IEEE P1363 (r||s) signature, not DER.
  const signature = signer.sign({ key, dsaEncoding: "ieee-p1363" });
  const signatureEncoded = base64url(signature);

  return `${signingInput}.${signatureEncoded}`;
}

function base64url(input: string | Buffer): string {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=+$/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function redactToken(token: string): string {
  if (token.length <= 8) return "***";
  return `${token.slice(0, 4)}…${token.slice(-4)}`;
}
