
import { Request, Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "../types/database.types";
import { env } from "../config/env";
import { AuthenticatedRequest } from "../middleware/auth.middleware";
import { sendFcmNotification } from "../services/fcm.services";

export async function createSosAlert(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
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

    if (typeof sender_name !== "string" || !sender_name.trim()) {
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

    const userSupabase = createClient<Database>(
      env.supabaseUrl,
      env.supabaseAnonKey,
      {
        global: {
          headers: { Authorization: authorization },
        },
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    const { data: alert, error } = await userSupabase
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

    console.log("SOS ALERT CREATED:", alert.id);

    let notificationResult = {
      successCount: 0,
      failureCount: 0,
    };

    try {
      if (!env.supabaseServiceRoleKey) {
        throw new Error("Supabase service-role key is not configured.");
      }

      const adminSupabase = createClient<Database>(
        env.supabaseUrl,
        env.supabaseServiceRoleKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        }
      );

      const { data: contacts, error: contactsError } = await adminSupabase
        .from("trusted_contacts")
        .select("contact_user_id")
        .eq("user_id", userId)
        .not("contact_user_id", "is", null);

      if (contactsError) {
        throw new Error(
          `Could not load linked trusted contacts: ${contactsError.message}`
        );
      }

      const recipientUserIds = [
        ...new Set(
          (contacts ?? [])
            .map((contact) => contact.contact_user_id)
            .filter((id): id is string => Boolean(id) && id !== userId)
        ),
      ];

      if (recipientUserIds.length > 0) {
        notificationResult = await sendFcmNotification({
          userIds: recipientUserIds,
          title: "SHIELD SOS ALERT",
          body: `${alert.sender_name} has sent an emergency alert.`,
          data: {
            type: "SOS",
            alertId: alert.id,
          },
        });
      }
    } catch (notificationError) {
      console.error("SOS FCM notification failed:", notificationError);
    }

    const notificationsSent = notificationResult.successCount > 0;

    res.status(201).json({
      success: true,
      message: "SOS alert saved successfully.",
      alert,
      notificationsSent,
      notificationResult,
    });
  } catch (error) {
    next(error);
  }
}
