
import { Request, Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import { Database } from "../types/database.types";
import { env } from "../config/env";
import { AuthenticatedRequest } from "../middleware/auth.middleware";

export async function createSosAlert(
  req: Request,
  res: Response,
  next: NextFunction
) {
  try {
    const authReq = req as AuthenticatedRequest;
    const userId = authReq.userId;

    if (!userId) {
      res.status(401).json({ error: "Authentication required." });
      return;
    }

    const {
      sender_name,
      sender_phone,
      latitude,
      longitude,
      message,
    } = req.body ?? {};

    if (
      typeof sender_name !== "string" ||
      sender_name.trim().length === 0
    ) {
      res.status(400).json({ error: "Sender name is required." });
      return;
    }

    if (
      (latitude != null &&
        (typeof latitude !== "number" ||
          !Number.isFinite(latitude) ||
          latitude < -90 ||
          latitude > 90)) ||
      (longitude != null &&
        (typeof longitude !== "number" ||
          !Number.isFinite(longitude) ||
          longitude < -180 ||
          longitude > 180))
    ) {
      res.status(400).json({ error: "Invalid coordinates." });
      return;
    }

    if (
      (sender_phone != null && typeof sender_phone !== "string") ||
      (message != null && typeof message !== "string")
    ) {
      res.status(400).json({ error: "Invalid phone or message." });
      return;
    }

    const authorization = req.headers.authorization;

    if (!authorization?.startsWith("Bearer ")) {
      res.status(401).json({ error: "Authentication token missing." });
      return;
    }

    const supabase = createClient<Database>(
      env.supabaseUrl,
      env.supabaseAnonKey,
      {
        global: {
          headers: { Authorization: authorization },
        },
      }
    );

    const { data, error } = await supabase
      .from("emergency_alerts")
      .insert({
        user_id: userId,
        sender_name: sender_name.trim(),
        sender_phone: sender_phone?.trim() || null,
        latitude: latitude ?? null,
        longitude: longitude ?? null,
        message: message?.trim() || "Emergency! I need help.",
      })
      .select(
        "id, user_id, sender_name, sender_phone, latitude, longitude, message, status, created_at"
      )
      .single();

    if (error) {
      console.error("SOS database error:", error.message);
      next(error);
      return;
    }

    console.log("SOS ALERT CREATED:", data.id);

    res.status(201).json({
      success: true,
      message: "SOS alert saved successfully.",
      alert: data,
      notificationsSent: false,
    });
  } catch (error) {
    next(error);
  }
}
