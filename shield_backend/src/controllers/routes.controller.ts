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
export async function searchDestinationsController(
  req: Request,
  res: Response
) {
  const query = z.object({
    query: z.string().trim().min(3).max(150)
  }).parse(req.query);

  const url = new URL("https://nominatim.openstreetmap.org/search");

  url.searchParams.set("q", query.query);
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("limit", "6");
  url.searchParams.set("addressdetails", "1");

  const response = await fetch(url, {
    headers: {
      "User-Agent": "SHIELD-SafetyApp/1.0"
    }
  });

  if (!response.ok) {
    res.status(502).json({ error: "Destination search failed." });
    return;
  }

  const results = await response.json();

  res.json({
    destinations: results.map((place: any) => ({
      name: place.name || place.display_name,
      address: place.display_name,
      latitude: Number(place.lat),
      longitude: Number(place.lon)
    }))
  });
}
