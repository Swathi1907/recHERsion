
import { Request, Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import { env } from "../config/env";
import { HttpError } from "../utils/httpError";

export interface AuthenticatedRequest extends Request {
  userId?: string;
}

export async function requireAuth(
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction
): Promise<void> {
  try {
    if (!env.supabaseUrl || !env.supabaseAnonKey) {
      throw new HttpError(500, "Supabase authentication is not configured.");
    }

    const authorization = req.headers.authorization;

    if (!authorization?.startsWith("Bearer ")) {
      throw new HttpError(401, "Authentication token is required.");
    }

    const token = authorization.slice("Bearer ".length).trim();

    if (!token) {
      throw new HttpError(401, "Authentication token is required.");
    }

    const supabase = createClient(
      env.supabaseUrl,
      env.supabaseAnonKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false,
        },
      }
    );

    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data.user) {
      throw new HttpError(401, "Invalid or expired authentication token.");
    }

    req.userId = data.user.id;
    next();
  } catch (error) {
    next(error);
  }
}
