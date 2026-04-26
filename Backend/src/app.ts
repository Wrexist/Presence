//  Presence backend
//  app.ts
//  Express app factory — extracted from index.ts so tests can import it
//  without binding to a port. index.ts boots the server with this app.

import express, { type Request, type Response, type NextFunction } from "express";
import cors from "cors";
import pinoHttp from "pino-http";
import pino, { type Logger } from "pino";

import { config } from "./config.js";
import { attachSentry } from "./sentry.js";
import { blocksRouter } from "./routes/blocks.js";
import { chatRouter } from "./routes/chat.js";
import { debugSentryRouter } from "./routes/debugSentry.js";
import { healthRouter } from "./routes/health.js";
import { icebreakerRouter } from "./routes/icebreaker.js";
import { presenceRouter } from "./routes/presence.js";
import { reportsRouter } from "./routes/reports.js";
import { usersRouter } from "./routes/users.js";
import { wavesRouter } from "./routes/waves.js";

interface HttpError extends Error {
  status?: number;
  statusCode?: number;
  type?: string;
  expose?: boolean;
}

export function createApp(logger: Logger = pino({ level: config.LOG_LEVEL })): express.Express {
  const app = express();
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
  app.use("/api/blocks", blocksRouter);
  app.use("/api/chat", chatRouter);
  app.use("/api/icebreaker", icebreakerRouter);
  app.use("/api/presence", presenceRouter);
  app.use("/api/reports", reportsRouter);
  app.use("/api/users", usersRouter);
  app.use("/api/waves", wavesRouter);

  if (config.NODE_ENV !== "production") {
    app.use("/debug-sentry", debugSentryRouter);
  }

  app.use((req, res) => {
    res.status(404).json({ error: "not_found", path: req.path });
  });

  // Sentry's error handler must come BEFORE our own — it captures the
  // exception, then our handler (with `next(err)` semantics elided since
  // we always send the response here) shapes the JSON body. attachSentry
  // is a no-op when SENTRY_DSN is unset.
  attachSentry(app);

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  app.use((err: HttpError, req: Request, res: Response, _next: NextFunction) => {
    const status = err.status ?? err.statusCode ?? 500;
    if (status >= 500) {
      req.log.error({ err }, "unhandled error");
      res.status(status).json({ error: "internal_error" });
      return;
    }
    req.log.warn({ msg: err.message, type: err.type, status }, "client error");
    res.status(status).json({
      error: err.type ?? "bad_request",
      message: err.message
    });
  });

  return app;
}
