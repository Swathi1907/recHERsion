import { fetchJson } from "./http.service";
import { HttpError } from "../utils/httpError";

export interface Coordinate {
  latitude: number;
  longitude: number;
}

interface OsrmResponse {
  code: string;
  message?: string;
  routes?: Array<{
    distance: number;
    duration: number;
    geometry: { type: "LineString"; coordinates: [number, number][] };
    legs?: Array<{ summary?: string; steps?: unknown[] }>;
  }>;
  waypoints?: Array<{ name: string; location: [number, number] }>;
}

export async function getDrivingRoutes(
  start: Coordinate,
  destination: Coordinate,
  alternatives: boolean
) {
  // OSRM coordinates are longitude,latitude (not latitude,longitude).
  const coordinates = `${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}`;
  const url = new URL(`https://router.project-osrm.org/route/v1/driving/${coordinates}`);
  console.log("osrm call done")
  url.searchParams.set("overview", "full");
  url.searchParams.set("geometries", "geojson");
  url.searchParams.set("steps", "true");
  url.searchParams.set("alternatives", alternatives ? "true" : "false");

  const result = await fetchJson<OsrmResponse>(url.toString());

  if (result.code !== "Ok" || !result.routes?.length) {
    throw new HttpError(404, result.message ?? "No driving route was found between those coordinates.");
  }

  return {
    provider: "OSRM",
    disclaimer: "Estimated driving route. This is not a verified safety ranking or emergency navigation service.",
    routes: result.routes.map((route, index) => ({
      id: `route_${index + 1}`,
      distanceMeters: Math.round(route.distance),
      distanceKm: Number((route.distance / 1000).toFixed(2)),
      durationSeconds: Math.round(route.duration),
      durationMinutes: Math.round(route.duration / 60),
      geometry: route.geometry,
      steps: (route.legs ?? []).flatMap((leg) => leg.steps ?? [])
    })),
    waypoints: result.waypoints ?? []
  };
}
