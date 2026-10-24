import type { Request, Response } from "express";
import { z } from "zod";
import { getDrivingRoutes } from "../services/osrm.service";

const latitude = z.coerce.number().finite().min(-90).max(90);
const longitude = z.coerce.number().finite().min(-180).max(180);

export async function getRoutesController(req: Request, res: Response) {
  const query = z.object({
    startLat: latitude,
    startLon: longitude,
    endLat: latitude,
    endLon: longitude,
    alternatives: z.enum(["true", "false"]).default("true")
  }).parse(req.query);

  if (query.startLat === query.endLat && query.startLon === query.endLon) {
    res.status(400).json({ error: "Start and destination must be different coordinates." });
    return;
  }

  const result = await getDrivingRoutes(
    { latitude: query.startLat, longitude: query.startLon },
    { latitude: query.endLat, longitude: query.endLon },
    query.alternatives === "true"
  );

  res.json(result);
}
