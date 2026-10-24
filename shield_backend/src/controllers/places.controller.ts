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



export async function nearbyPlacesController(
  req: Request,
  res: Response
) {
  const latitude = Number(req.query.latitude);
  const longitude = Number(req.query.longitude);
  const radiusMeters = Number(req.query.radiusMeters ?? 1000);
  const category = String(req.query.category ?? "all");

  const validCategories = [
    "all",
    "shops",
    "pharmacies",
    "food",
    "healthcare",
  ] as const;

  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    latitude < -90 ||
    latitude > 90 ||
    longitude < -180 ||
    longitude > 180
  ) {
    res.status(400).json({
      error: "Valid latitude and longitude are required",
    });
    return;
  }

  if (
    !Number.isFinite(radiusMeters) ||
    radiusMeters < 1 ||
    radiusMeters > 50000
  ) {
    res.status(400).json({
      error: "radiusMeters must be between 1 and 50000",
    });
    return;
  }

  if (!validCategories.includes(category as typeof validCategories[number])) {
    res.status(400).json({ error: "Invalid category" });
    return;
  }

  const result = await findNearbyPlaces({
    latitude,
    longitude,
    radiusMeters,
    category: category as typeof validCategories[number],
  });

  res.json(result);
}

