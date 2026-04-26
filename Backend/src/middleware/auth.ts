//  Presence backend
//  middleware/auth.ts
//  Verifies Supabase JWTs in the Authorization header. On success, attaches
//  `userId` (= `auth.users.id` = `public.users.id`) onto the request. On
//  failure, sends 401 and ends the chain. Responses don't reveal *why* the
//  token was rejected — just "unauthorized".

import type { Request, Response, NextFunction } from "express";
import { getSupabase } from "../services/supabase.js";

declare module "express-serve-static-core" {
  interface Request {
    userId?: string;
  }
}

export async function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const header = req.header("authorization") ?? req.header("Authorization");
  if (!header) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    res.status(401).json({ error: "unauthorized" });
    return;
  }
  const token = match[1]!;

  const supabase = getSupabase();
  if (!supabase) {
    // Fail closed: in environments where Supabase isn't configured, refuse
    // to authenticate rather than silently letting traffic through.
    res.status(503).json({ error: "auth_unavailable" });
    return;
  }

  try {
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) {
      res.status(401).json({ error: "unauthorized" });
      return;
    }
    req.userId = data.user.id;
    next();
  } catch {
    res.status(401).json({ error: "unauthorized" });
  }
}
