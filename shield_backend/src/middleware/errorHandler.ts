import type { ErrorRequestHandler } from "express";
import { ZodError } from "zod";
import { HttpError } from "../utils/httpError";
import { env } from "../config/env";

export const errorHandler: ErrorRequestHandler = (error, _req, res, _next) => {
  if (error instanceof ZodError) {
    res.status(400).json({
      error: "Invalid request",
      details: error.issues.map((issue) => ({
        path: issue.path.join("."),
        message: issue.message
      }))
    });
    return;
  }

  if (error instanceof HttpError) {
    res.status(error.statusCode).json({ error: error.message });
    return;
  }

  console.error("Unhandled API error:", error);
  res.status(500).json({
    error: "Internal server error",
    ...(env.nodeEnv === "development" && error instanceof Error
      ? { details: error.message }
      : {})
  });
};
