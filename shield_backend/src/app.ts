import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { env } from "./config/env";
import { healthRouter } from "./routes/health.routes";
import { placesRouter } from "./routes/places.routes";
import { routesRouter } from "./routes/routes.routes";
import { errorHandler } from "./middleware/errorHandler";
import { HttpError } from "./utils/httpError";

export const app = express();

app.disable("x-powered-by");
app.use(helmet());

app.use(cors({
  origin(origin, callback) {
    if (!origin || env.corsOrigins.includes("*") || env.corsOrigins.includes(origin)) {
      callback(null, true);
      return;
    }
    callback(new HttpError(403, "This origin is not allowed by CORS."));
  }
}));

app.use(express.json({ limit: "1mb" }));

app.use("/api", rateLimit({
  windowMs: 60_000,
  limit: 60,
  standardHeaders: "draft-7",
  legacyHeaders: false,
  message: { error: "Too many requests. Please try again in a minute." }
}));

app.get("/", (_req, res) => {
  res.json({ name: "SHIELD API", status: "running", health: "/api/health" });
});

app.use("/api/health", healthRouter);
app.use("/api/places", placesRouter);
app.use("/api/routes", routesRouter);

app.use((_req, _res, next) => {
  next(new HttpError(404, "API endpoint not found."));
});

app.use(errorHandler);
