//  Presence backend
//  index.ts
//  Entry point. Wires the Express app from app.ts to an HTTP server,
//  attaches Socket.io, and starts listening.

import { createServer } from "node:http";
import pino from "pino";

import { createApp } from "./app.js";
import { config, featureFlags } from "./config.js";
import { setIO } from "./services/socketHub.js";
import { attachWebSocket } from "./websocket/index.js";

const logger = pino({ level: config.LOG_LEVEL });
const app = createApp(logger);

const http = createServer(app);
const io = attachWebSocket(http, logger);
setIO(io);

http.listen(config.PORT, () => {
  logger.info(
    {
      port: config.PORT,
      env: config.NODE_ENV,
      supabase: featureFlags.supabaseEnabled,
      anthropic: featureFlags.anthropicEnabled
    },
    "presence-backend listening"
  );
});

for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, () => {
    logger.info({ signal }, "shutting down");
    http.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 5000).unref();
  });
}
