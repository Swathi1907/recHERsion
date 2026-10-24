import type { Request, Response } from "express";
import { z } from "zod";
import { searchPlaces, reverseGeocode } from "../services/nominatim.service";
import { findNearbyPlaces } from "../services/foursquare.service";

const coordinate = z.coerce.number().finite();
const lat = coordinate.min(-90).max(90);
const lon = coordinate.min(-180).max(180);

export async function searchPlacesController(req: Request, res: Response) {
  const query = z.object({
    q: z.string().trim().min(2).max(150),
    limit: z.coerce.number().int().min(1).max(8).default(5)
  }).parse(req.query);

  const places = await searchPlaces(query.q, query.limit);
  res.json({ count: places.length, places });
}

export async function reverseGeocodeController(req: Request, res: Response) {
  const query = z.object({ lat, lon }).parse(req.query);
  const place = await reverseGeocode(query.lat, query.lon);
  res.json({ place });
}

export async function nearbyPlacesController(req: Request, res: Response) {
  const query = z.object({
    lat,
    lon,
    radius: z.coerce.number().int().min(100).max(3000).default(800),
    category: z.enum(["all", "shops", "pharmacies", "food", "healthcare"]).default("all")
  }).parse(req.query);

  const result = await findNearbyPlaces({
    latitude: query.lat,
    longitude: query.lon,
    radiusMeters: query.radius,
    category: query.category
  });
  res.json(result);
}
