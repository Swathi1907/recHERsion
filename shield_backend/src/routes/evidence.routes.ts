
import { Router, Response, NextFunction } from "express";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "../types/database.types";
import {
  requireAuth,
  AuthenticatedRequest,
} from "../middleware/auth.middleware";
import { env } from "../config/env";
import { HttpError } from "../utils/httpError";
import multer from "multer";
import { createHash, randomUUID } from "node:crypto";
import { z } from "zod";

const router = Router();

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB

const allowedMimeTypes: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
  "audio/mpeg": "mp3",
  "audio/wav": "wav",
  "audio/mp4": "m4a",
  "audio/webm": "webm",
  "video/mp4": "mp4",
  "video/webm": "webm",
  "video/quicktime": "mov",
};

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: MAX_FILE_SIZE,
    files: 1,
  },
  fileFilter: (_req, file, callback) => {
    if (!allowedMimeTypes[file.mimetype]) {
      callback(new Error("Unsupported file type."));
      return;
    }

    callback(null, true);
  },
});

// Convert upload errors into appropriate HTTP errors.
function uploadSingleFile(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void {
  upload.single("file")(req, res, (error: unknown) => {
    if (error instanceof multer.MulterError) {
      if (error.code === "LIMIT_FILE_SIZE") {
        next(new HttpError(413, "File size must not exceed 10 MB."));
        return;
      }

      next(new HttpError(400, "Invalid file upload."));
      return;
    }

    if (error) {
      next(new HttpError(400, "Unsupported or invalid file upload."));
      return;
    }

    next();
  });
}

// Shared helper: create a Supabase client using the user's token.
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
    }
  );
}

// Validate metadata submitted to POST /api/evidence.
const createEvidenceSchema = z.object({
  title: z.string().trim().min(1).max(200),
  evidence_type: z.enum(["photo", "audio", "video", "note"]),
  description: z.string().trim().max(5000).optional(),
  sha256: z.string().regex(/^[a-f0-9]{64}$/).optional(),
  captured_at: z.string().datetime({ offset: true }).optional(),
});

// All evidence routes require authentication.
router.use(requireAuth);

// GET /api/evidence
// Retrieve the logged-in user's evidence records.
router.get(
  "/",
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const authorization = req.headers.authorization;

      if (!authorization?.startsWith("Bearer ")) {
        throw new HttpError(401, "Authentication token is required.");
      }

      const token = authorization.slice("Bearer ".length).trim();

      if (!token) {
        throw new HttpError(401, "Authentication token is required.");
      }

      const supabase = getUserSupabaseClient(token);

      const { data, error } = await supabase
        .from("evidence_items")
        .select(
          "id, title, evidence_type, description, sha256, captured_at, created_at, updated_at, verification_status"
        )
        .order("created_at", { ascending: false });

      if (error) {
        console.error("Evidence retrieval failed:", error.message);
        throw new HttpError(500, "Unable to retrieve evidence records.");
      }

      res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }
);

// POST /api/evidence
// Save evidence metadata without uploading a file.
router.post(
  "/",
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      if (!req.userId) {
        throw new HttpError(401, "Authenticated user ID is missing.");
      }

      const parsed = createEvidenceSchema.safeParse(req.body);

      if (!parsed.success) {
        res.status(400).json({
          success: false,
          message: "Invalid evidence data.",
          errors: parsed.error.flatten(),
        });
        return;
      }

      const authorization = req.headers.authorization;

      if (!authorization?.startsWith("Bearer ")) {
        throw new HttpError(401, "Authentication token is required.");
      }

      const token = authorization.slice("Bearer ".length).trim();

      if (!token) {
        throw new HttpError(401, "Authentication token is required.");
      }

      const supabase = getUserSupabaseClient(token);

      const { data, error } = await supabase
        .from("evidence_items")
        .insert({
          user_id: req.userId,
          title: parsed.data.title,
          evidence_type: parsed.data.evidence_type,
          description: parsed.data.description ?? null,
          sha256: parsed.data.sha256 ?? null,
          captured_at: parsed.data.captured_at ?? null,
        })
        .select(
          "id, title, evidence_type, description, sha256, captured_at, created_at, verification_status"
        )
        .single();

      if (error) {
        console.error("Evidence metadata insert failed:", error.message);
        throw new HttpError(500, "Unable to save evidence metadata.");
      }

      res.status(201).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }
);

// POST /api/evidence/upload
// Upload one file and save its metadata.
router.post(
  "/upload",
  uploadSingleFile,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    let uploadedPath: string | undefined;
    let supabase:
      | ReturnType<typeof getUserSupabaseClient>
      | undefined;

    try {
      if (!req.userId) {
        throw new HttpError(401, "Authenticated user ID is missing.");
      }

      if (!req.file) {
        throw new HttpError(
          400,
          "Attach a file using the multipart field named 'file'."
        );
      }
      console.log("Upload form fields:", req.body);
      const title =
        typeof req.body?.title === "string" ? req.body.title.trim() : "";

      if (title.length < 1 || title.length > 200) {
        throw new HttpError(400, "Title must contain 1–200 characters.");
      }

      const description =
        typeof req.body?.description === "string"
          ? req.body.description.trim()
          : "";

      if (description.length > 5000) {
        throw new HttpError(
          400,
          "Description cannot exceed 5000 characters."
        );
      }

      const authorization = req.headers.authorization;

      if (!authorization?.startsWith("Bearer ")) {
        throw new HttpError(401, "Authentication token is required.");
      }

      const token = authorization.slice("Bearer ".length).trim();

      if (!token) {
        throw new HttpError(401, "Authentication token is required.");
      }

      const mimeType = req.file.mimetype;
      const extension = allowedMimeTypes[mimeType];

      if (!extension) {
        throw new HttpError(400, "Unsupported file type.");
      }

      const evidenceType: "photo" | "audio" | "video" =
        mimeType.startsWith("image/")
          ? "photo"
          : mimeType.startsWith("audio/")
            ? "audio"
            : "video";

      const sha256 = createHash("sha256")
        .update(req.file.buffer)
        .digest("hex");

      supabase = getUserSupabaseClient(token);

      // Keep files inside the authenticated user's UUID folder.
      uploadedPath = `${req.userId}/${randomUUID()}.${extension}`;

      const { error: uploadError } = await supabase.storage
        .from("evidence-files")
        .upload(uploadedPath, req.file.buffer, {
          contentType: mimeType,
          upsert: false,
        });

      if (uploadError) {
        console.error("Evidence file upload failed:", uploadError.message);
        throw new HttpError(500, "Unable to upload the evidence file.");
      }

      const { data, error: insertError } = await supabase
        .from("evidence_items")
        .insert({
          user_id: req.userId,
          title,
          evidence_type: evidenceType,
          description: description || null,
          storage_path: uploadedPath,
          sha256,
        })
        .select(
          "id, title, evidence_type, description, storage_path, sha256, created_at, verification_status"
        )
        .single();

      if (insertError) {
        console.error("Evidence metadata insert failed:", insertError.message);

        // Remove the uploaded file if its metadata could not be saved.
        const { error: cleanupError } = await supabase.storage
          .from("evidence-files")
          .remove([uploadedPath]);

        if (cleanupError) {
          console.error(
            "Evidence file cleanup failed:",
            cleanupError.message
          );
        }

        uploadedPath = undefined;

        throw new HttpError(500, "Unable to save evidence metadata.");
      }

      res.status(201).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }
);

export default router;
