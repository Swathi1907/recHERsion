
import { Request, Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import { Database } from "../types/database.types";
import { env } from "../config/env";
import { AuthenticatedRequest } from "../middleware/auth.middleware";
import { firebaseMessaging } from "../config/firebase";
export async function registerDeviceToken(
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

    const { fcm_token, platform = "android" } = req.body ?? {};

    if (
      typeof fcm_token !== "string" ||
      fcm_token.trim().length === 0
    ) {
      res.status(400).json({ error: "A valid FCM token is required." });
      return;
    }

    if (platform !== "android" && platform !== "ios") {
      res.status(400).json({ error: "Platform must be android or ios." });
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
  .from("device_tokens")
  .upsert(
    {
      user_id: userId,
      fcm_token: fcm_token.trim(),
      platform,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "fcm_token" }
  )
  .select("id, user_id, platform");

console.log("FCM UPSERT RESULT:", {
  saved: data?.length ?? 0,
  error: error?.message ?? null,
});
    if (error) {
      next(error);
      return;
    }

    res.status(200).json({
      message: "Device token registered successfully.",
    });
  } catch (error) {
    next(error);
  }
}

export async function deleteDeviceToken(
  req: Request,
  res: Response,
  next: NextFunction
) {
  try {
    const authReq = req as AuthenticatedRequest;
    const userId = authReq.userId;
    const { fcm_token } = req.body ?? {};

    if (!userId) {
      res.status(401).json({ error: "Authentication required." });
      return;
    }

    if (typeof fcm_token !== "string" || !fcm_token.trim()) {
      res.status(400).json({ error: "A valid FCM token is required." });
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

    const { error } = await supabase
      .from("device_tokens")
      .delete()
      .eq("user_id", userId)
      .eq("fcm_token", fcm_token.trim());

    if (error) {
      next(error);
      return;
    }

    res.status(200).json({
      message: "Device token deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
}
export async function sendTestNotification(
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

    const { data: devices, error } = await supabase
      .from("device_tokens")
      .select("fcm_token")
      .eq("user_id", userId);

    if (error) {
      next(error);
      return;
    }

    if (!devices || devices.length === 0) {
      res.status(404).json({
        error: "No FCM device tokens found for this user.",
      });
      return;
    }

    const result = await firebaseMessaging.sendEachForMulticast({
      tokens: devices.map((device) => device.fcm_token),
      notification: {
        title: "SHIELD Test Notification",
        body: "Your push notifications are connected successfully!",
      },
      data: {
        type: "FCM_TEST",
      },
    });

    res.status(200).json({
      message: "Test notification request completed.",
      successCount: result.successCount,
      failureCount: result.failureCount,
      responses: result.responses.map((response) => ({
        success: response.success,
        error: response.error?.code ?? null,
      })),
    });
  } catch (error) {
    next(error);
  }
}


