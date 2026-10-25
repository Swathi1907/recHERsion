
import { Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "../types/database.types";
import { AuthenticatedRequest } from "../middleware/auth.middleware";
import { env } from "../config/env";
import { HttpError } from "../utils/httpError";
import { z } from "zod";

function getUserSupabaseClient(token: string) {
  if (!env.supabaseUrl || !env.supabaseAnonKey) {
    throw new HttpError(500, "Supabase is not configured.");
  }

  return createClient<Database>(
    env.supabaseUrl,
    env.supabaseAnonKey,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
    },
  );
}

function getToken(req: AuthenticatedRequest): string {
  const authorization = req.headers.authorization;

  if (!authorization?.startsWith("Bearer ")) {
    throw new HttpError(401, "Authentication token is required.");
  }

  const token = authorization.slice("Bearer ".length).trim();

  if (!token) {
    throw new HttpError(401, "Authentication token is required.");
  }

  return token;
}

const contactSchema = z.object({
  name: z.string().trim().min(1).max(100),
  phone: z.string().trim().min(7).max(20),
  relationship: z.string().trim().min(1).max(50),
});

// GET /api/trusted-contacts
export async function getTrustedContacts(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const supabase = getUserSupabaseClient(getToken(req));

    const { data, error } = await supabase
      .from("trusted_contacts")
      .select("id, name, phone, relationship, created_at")
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Trusted contacts retrieval failed:", error.message);
      throw new HttpError(500, "Unable to retrieve trusted contacts.");
    }

    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

// POST /api/trusted-contacts
export async function addTrustedContact(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.userId) {
      throw new HttpError(401, "Authenticated user ID is missing.");
    }

    const parsed = contactSchema.safeParse(req.body);

    if (!parsed.success) {
      res.status(400).json({
        success: false,
        message: "Invalid contact data.",
        errors: parsed.error.flatten(),
      });
      return;
    }

    const supabase = getUserSupabaseClient(getToken(req));

    const { data, error } = await supabase
      .from("trusted_contacts")
      .insert({
        user_id: req.userId,
        name: parsed.data.name,
        phone: parsed.data.phone,
        relationship: parsed.data.relationship,
      })
      .select("id, name, phone, relationship, created_at")
      .single();

    if (error) {
      console.error("Trusted contact insert failed:", error.message);
      throw new HttpError(500, "Unable to save trusted contact.");
    }

    res.status(201).json({ success: true, data });
  } catch (error) {
    next(error);
  }
}

// DELETE /api/trusted-contacts/:id
export async function deleteTrustedContact(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    if (!req.userId) {
      throw new HttpError(401, "Authenticated user ID is missing.");
    }

    const contactId = req.params.id;

    if (typeof contactId !== "string" || !contactId) {
      throw new HttpError(400, "Invalid contact ID.");
    }

    const supabase = getUserSupabaseClient(getToken(req));

    const { data, error } = await supabase
      .from("trusted_contacts")
      .delete()
      .eq("id", contactId)
      .select("id")
      .maybeSingle();

    if (error) {
      console.error("Trusted contact deletion failed:", error.message);
      throw new HttpError(500, "Unable to delete trusted contact.");
    }

    if (!data) {
      throw new HttpError(404, "Trusted contact not found.");
    }

    res.status(200).json({
      success: true,
      message: "Trusted contact deleted.",
    });
  } catch (error) {
    next(error);
  }
}
