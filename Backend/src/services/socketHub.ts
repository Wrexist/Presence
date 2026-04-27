//  Presence backend
//  socketHub.ts
//  Tiny singleton holding the io instance, so HTTP routes can broadcast
//  without taking a hard dep on the websocket bootstrap module.

import type { Server as IOServer } from "socket.io";

let io: IOServer | null = null;

export function setIO(server: IOServer): void {
  io = server;
}

export function broadcast(room: string, event: string, payload: unknown): void {
  if (!io) return;
  io.to(room).emit(event, payload);
}
