
import { firebaseMessaging } from "../config/firebase";
import { createClient } from "@supabase/supabase-js";
import { Database } from "../types/database.types";
import { env } from "../config/env";


if (!env.supabaseUrl || !env.supabaseServiceRoleKey) {
  throw new Error("Supabase server configuration is missing.");
}

const supabase = createClient<Database>(
  env.supabaseUrl,
  env.supabaseServiceRoleKey,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  }
);

interface SendFcmNotificationParams {
  userIds: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendFcmNotification({
  userIds,
  title,
  body,
  data = {},
}: SendFcmNotificationParams) {
  const uniqueUserIds = [...new Set(userIds)].filter(Boolean);

  if (uniqueUserIds.length === 0) {
    return { successCount: 0, failureCount: 0 };
  }

  const { data: devices, error } = await supabase
    .from("device_tokens")
    .select("id, user_id, fcm_token")
    .in("user_id", uniqueUserIds);

  if (error) {
    throw new Error(`Failed to fetch device tokens: ${error.message}`);
  }

  if (!devices?.length) {
    return { successCount: 0, failureCount: 0 };
  }

  const tokens = [...new Set(devices.map((device) => device.fcm_token))];

const response = await firebaseMessaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "shield_alerts",
        sound: "default",
      },
    },
  });

  const invalidTokens: string[] = [];

  response.responses.forEach((result, index) => {
    if (
      !result.success &&
      (
        result.error?.code === "messaging/registration-token-not-registered" ||
        result.error?.code === "messaging/invalid-registration-token"
      )
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    const { error: deleteError } = await supabase
      .from("device_tokens")
      .delete()
      .in("fcm_token", invalidTokens);

    if (deleteError) {
      console.error("Could not remove invalid FCM tokens:", deleteError.message);
    }
  }

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
  };
}
