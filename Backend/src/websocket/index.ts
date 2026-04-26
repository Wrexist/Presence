//  Presence backend
//  websocket/index.ts
//  Real Socket.io bootstrap. Auth on the handshake (Supabase JWT either
//  in `auth.token` or the `?token=` query param), `subscribe` event joins
//  the caller's geohash room plus its 8 neighbors. Routes emit
//  presence_joined / presence_left to those rooms (see routes/presence.ts).

import { Server as HttpServer } from "node:http";
import { Server as IOServer, type Socket } from "socket.io";
import type { Logger } from "pino";

import { getSupabase } from "../services/supabase.js";
import { geohashOf, geohashAndNeighbors } from "../services/geohash.js";

interface SubscribePayload {
  lat?: unknown;
  lng?: unknown;
}

declare module "socket.io" {
  interface Socket {
    userId?: string;
  }
}

export function attachWebSocket(http: HttpServer, logger: Logger): IOServer {
  const io = new IOServer(http, {
    cors: { origin: true },
    transports: ["websocket", "polling"]
  });

  // Connection-time auth. Reject before the connection event fires so
  // unauthenticated clients never enter any room or receive any broadcast.
  io.use(async (socket, next) => {
    try {
      const token = extractToken(socket);
      if (!token) return next(new Error("unauthorized"));

      const supabase = getSupabase();
      if (!supabase) return next(new Error("auth_unavailable"));

      const { data, error } = await supabase.auth.getUser(token);
      if (error || !data.user) return next(new Error("unauthorized"));

      socket.userId = data.user.id;
      next();
    } catch {
      next(new Error("unauthorized"));
    }
  });

  io.on("connection", (socket: Socket) => {
    logger.info({ socketId: socket.id, userId: socket.userId }, "socket connected");

    socket.on("disconnect", (reason) => {
      logger.info({ socketId: socket.id, reason }, "socket disconnected");
    });

    socket.on("subscribe", (payload: SubscribePayload) => {
      const lat = typeof payload?.lat === "number" ? payload.lat : Number(payload?.lat);
      const lng = typeof payload?.lng === "number" ? payload.lng : Number(payload?.lng);
      if (!Number.isFinite(lat) || lat < -90 || lat > 90) return;
      if (!Number.isFinite(lng) || lng < -180 || lng > 180) return;

      const center = geohashOf(lat, lng);
      const rooms = geohashAndNeighbors(center).map((g) => `zone:${g}`);
      const previous = Array.from(socket.rooms).filter((r) => r.startsWith("zone:"));

      // Leave any previously joined zones first so a re-subscribe doesn't
      // accumulate rooms (and therefore broadcast fan-out) over time.
      for (const r of previous) {
        if (!rooms.includes(r)) socket.leave(r);
      }
      for (const r of rooms) {
        socket.join(r);
      }
      logger.debug(
        { socketId: socket.id, userId: socket.userId, center, rooms: rooms.length },
        "subscribed to zones"
      );
    });

    socket.on("unsubscribe", () => {
      for (const room of Array.from(socket.rooms)) {
        if (room.startsWith("zone:")) socket.leave(room);
      }
    });
  });

  return io;
}

function extractToken(socket: Socket): string | null {
  // Preferred: socket.io v3 auth field — `socket.handshake.auth.token`.
  const auth = socket.handshake.auth as Record<string, unknown> | undefined;
  if (auth && typeof auth.token === "string" && auth.token.length > 0) {
    return auth.token;
  }
  // Fallback: query string `?token=...` (older client libs / Swift socket
  // implementations send via connectParams).
  const queryToken = socket.handshake.query?.token;
  if (typeof queryToken === "string" && queryToken.length > 0) {
    return queryToken;
  }
  // Last resort: Authorization header (HTTP polling phase only). Node's
  // http parser lowercases header names, so we only check the lowercase form.
  const authHeader = socket.handshake.headers.authorization;
  if (typeof authHeader === "string") {
    const match = authHeader.match(/^Bearer\s+(.+)$/i);
    if (match) return match[1]!;
  }
  return null;
}
