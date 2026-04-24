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
// Honor X-Forwarded-For when deployed behind a proxy. Off by default
// (TRUST_PROXY=0); Railway/Render/Fly users should set TRUST_PROXY=1.
app.set("trust proxy", config.TRUST_PROXY);
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
// Preserves the status code set by earlier middleware (notably body-parser,
// which throws 400 on malformed JSON and 413 on payload-too-large). Only
// masks the message for true 5xx faults.
interface HttpError extends Error {
  status?: number;
  statusCode?: number;
  type?: string;
  expose?: boolean;
}
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: HttpError, req: Request, res: Response, _next: NextFunction) => {
  const status = err.status ?? err.statusCode ?? 500;
  if (status >= 500) {
    req.log.error({ err }, "unhandled error");
    res.status(status).json({ error: "internal_error" });
    return;
  }
  req.log.warn(
    { msg: err.message, type: err.type, status },
    "client error"
  );
  res.status(status).json({
    error: err.type ?? "bad_request",
    message: err.message
  });
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
