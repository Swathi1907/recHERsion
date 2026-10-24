
import { Router } from "express";
import { calculateSafetyScore } from "../services/safety-score.service";

export const safetyRouter = Router();

safetyRouter.get("/score", (_req, res) => {
  // Real safety indicators are not connected yet.
  const result = calculateSafetyScore({
    lightingScore: null,
    activityScore: null,
    infrastructureScore: null,
    incidentScore: null,
  });

  res.json({
    ...result,
    indicators: {
      lighting: "unavailable",
      activity: "unavailable",
      infrastructure: "unavailable",
      incidents: "unavailable",
    },
  });
});
