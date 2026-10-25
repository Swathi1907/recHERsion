
import type { Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import { createHash, randomBytes } from "node:crypto";

import type { Database } from "../types/database.types";
import type { AuthenticatedRequest } from "../middleware/auth.middleware";
import { env } from "../config/env";

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

function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

function normalizePhone(phone: string): string {
  return phone.replace(/[^\d+]/g, "");
}

// POST /api/trusted-contacts/:id/invite
export async function createTrustedContactInvitation(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const inviterUserId = req.userId;
    const contactId = req.params.id;

    if (!inviterUserId) {
      return res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
    }

    if (typeof contactId !== "string" || !contactId) {
      return res.status(400).json({
        success: false,
        message: "A valid contact ID is required.",
      });
    }

    const { data: contact, error: contactError } =
      await adminSupabase
        .from("trusted_contacts")
        .select("id, user_id, name, phone, contact_user_id")
        .eq("id", contactId)
        .eq("user_id", inviterUserId)
        .maybeSingle();

    if (contactError) throw contactError;

    if (!contact) {
      return res.status(404).json({
        success: false,
        message: "Trusted contact not found.",
      });
    }

    if (contact.contact_user_id) {
      return res.status(409).json({
        success: false,
        message: "This contact is already linked to an account.",
      });
    }

    const phone = normalizePhone(contact.phone);

    // Require an international phone number, e.g. +919876543210.
    if (!/^\+[1-9]\d{7,14}$/.test(phone)) {
      return res.status(400).json({
        success: false,
        message:
          "Save the contact's phone number in international format, such as +919876543210.",
      });
    }

    // The raw token is shared once. Only its hash is stored.
    const token = randomBytes(32).toString("hex");
    const tokenHash = hashToken(token);
    const expiresAt = new Date(
      Date.now() + 48 * 60 * 60 * 1000
    ).toISOString();

    const { error: invitationError } = await adminSupabase
      .from("trusted_contact_invitations")
      .upsert(
        {
          inviter_user_id: inviterUserId,
          contact_id: contact.id,
          invitee_user_id: null,
          status: "pending",
          token_hash: tokenHash,
          expires_at: expiresAt,
          responded_at: null,
        },
        { onConflict: "contact_id" }
      );

    if (invitationError) throw invitationError;

    // Configure SHIELD_INVITE_BASE_URL later when app links are ready.
    const baseUrl =
      process.env.SHIELD_INVITE_BASE_URL ??
      "shield://invite";

    const separator = baseUrl.includes("?") ? "&" : "?";
    const inviteLink =
      `${baseUrl}${separator}token=${encodeURIComponent(token)}`;

    return res.status(201).json({
      success: true,
      message: "Invitation created. Share this link with the contact.",
      contactName: contact.name,
      inviteLink,
      expiresAt,
    });
  } catch (error) {
    next(error);
  }
}

// POST /api/trusted-contacts/invitations/:invitationId/respond
// The invitation ID is not the secret. Acceptance uses the one-time token.
export async function respondToTrustedContactInvitation(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const inviteeUserId = req.userId;
    const token = req.body?.token;

    if (!inviteeUserId) {
      return res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
    }

    if (
      typeof token !== "string" ||
      !/^[a-f0-9]{64}$/i.test(token)
    ) {
      return res.status(400).json({
        success: false,
        message: "A valid invitation token is required.",
      });
    }

    // Get the user's actual Supabase Auth record. Do not trust a phone
    // number sent by the Flutter client.
    const { data: authData, error: authError } =
      await adminSupabase.auth.admin.getUserById(inviteeUserId);

    if (authError) throw authError;

    const authUser = authData.user;

    if (
      !authUser?.phone ||
      !authUser.phone_confirmed_at
    ) {
      return res.status(403).json({
        success: false,
        message:
          "Verify your phone number with SHIELD before accepting an invitation.",
      });
    }

    // Supabase Auth supplies the phone number and confirmation status.
    // The SQL function performs the one-time acceptance and account link.
  const rpcClient = adminSupabase as any;

const { data, error } = await rpcClient.rpc(
  "accept_trusted_contact_invitation",
  {
    p_token_hash: hashToken(token),
    p_invitee_user_id: inviteeUserId,
    p_verified_phone: authUser.phone,
  }
);
    if (error) {
      return res.status(400).json({
        success: false,
        message:
          "The invitation could not be accepted. It may have expired, already been used, or the verified phone may not match.",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Invitation accepted. The trusted accounts are now linked.",
      result: data,
    });
  } catch (error) {
    next(error);
  }
}
