import "dotenv/config";

function positiveInteger(value: string | undefined, fallback: number): number {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

export const env = {
  port: positiveInteger(process.env.PORT, 3000),
  nodeEnv: process.env.NODE_ENV ?? "development",
  corsOrigins: (process.env.CORS_ORIGINS ?? "*")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
  appUserAgent:
    process.env.APP_USER_AGENT ??
    "SHIELD-Safety-App/1.0 (replace-with-a-real-contact)",
  requestTimeoutMs: positiveInteger(process.env.REQUEST_TIMEOUT_MS, 30000)
};


