//  Presence backend
//  index.ts
//  Entry point. Boots Express, mounts routes, attaches Socket.io, starts
//  listening. Fails fast on port conflicts and logs feature availability.

import { createServer } from "node:http";
import express, { type Request, type Response, type NextFunction } from "express";
import cors from "cors";
import pinoHttp from "pino-http";
import pino from "pino";

import { config, featureFlags } from "./config.js";
import { healthRouter } from "./routes/health.js";
import { icebreakerRouter } from "./routes/icebreaker.js";
import { presenceRouter } from "./routes/presence.js";
import { wavesRouter } from "./routes/waves.js";
import { attachWebSocket } from "./websocket/index.js";

const logger = pino({ level: config.LOG_LEVEL });

const app = express();
app.use(express.json({ limit: "64kb" }));
app.use(
  cors({
    origin: config.CORS_ORIGINS.length > 0 ? config.CORS_ORIGINS : true,
    credentials: true
  })
);
app.use(pinoHttp({ logger }));

app.use("/health", healthRouter);
app.use("/api/icebreaker", icebreakerRouter);
app.use("/api/presence", presenceRouter);
app.use("/api/waves", wavesRouter);

// 404
app.use((req, res) => {
  res.status(404).json({ error: "not_found", path: req.path });
});

// Error handler — last middleware. Must have 4 params for Express to recognize it.
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: Error, req: Request, res: Response, _next: NextFunction) => {
  req.log.error({ err }, "unhandled error");
  res.status(500).json({ error: "internal_error" });
});

const http = createServer(app);
attachWebSocket(http, logger);

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
