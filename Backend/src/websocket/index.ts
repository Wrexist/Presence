//  Presence backend
//  websocket/index.ts
//  Socket.io server scaffold. Real event wiring (presence_joined,
//  presence_left, chat rooms for mutual waves) lands in Sprints 1 and 2;
//  this just stands the server up so the iOS app can connect for testing.

import { Server as HttpServer } from "node:http";
import { Server as IOServer, type Socket } from "socket.io";
import type { Logger } from "pino";

export function attachWebSocket(http: HttpServer, logger: Logger): IOServer {
  const io = new IOServer(http, {
    cors: { origin: true },
    // Keep the path on the default; iOS client will target ws://host:3000.
    transports: ["websocket", "polling"]
  });

  io.on("connection", (socket: Socket) => {
    logger.info({ socketId: socket.id }, "socket connected");

    socket.on("disconnect", (reason) => {
      logger.info({ socketId: socket.id, reason }, "socket disconnected");
    });

    // Placeholder — real rooms are keyed by geohash in Sprint 1.
    socket.on("join:zone", (zone: string) => {
      if (typeof zone !== "string" || zone.length > 32) return;
      socket.join(`zone:${zone}`);
      logger.debug({ socketId: socket.id, zone }, "joined zone");
    });
  });

  return io;
}
