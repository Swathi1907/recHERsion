import { env } from "../config/env";
import { fetchJson } from "./http.service";
import { HttpError } from "../utils/httpError";

export interface PlaceSearchResult {
  id: string;
  name: string;
  displayName: string;
  latitude: number;
  longitude: number;
  category: string;
  type: string;
}

interface NominatimResult {
  place_id: number;
  name?: string;
  display_name: string;
  lat: string;
  lon: string;
  category?: string;
  type?: string;
}

export async function searchPlaces(query: string, limit: number): Promise<PlaceSearchResult[]> {
  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", query);
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("limit", String(limit));
  url.searchParams.set("addressdetails", "1");

  const results = await fetchJson<NominatimResult[]>(url.toString(), {
    headers: { "User-Agent": env.appUserAgent }
  });

  return results.map((item) => ({
    id: String(item.place_id),
    name: item.name?.trim() || item.display_name.split(",")[0],
    displayName: item.display_name,
    latitude: Number(item.lat),
    longitude: Number(item.lon),
    category: item.category ?? "unknown",
    type: item.type ?? "unknown"
  }));
}

export async function reverseGeocode(latitude: number, longitude: number) {
  const url = new URL("https://nominatim.openstreetmap.org/reverse");
  url.searchParams.set("lat", String(latitude));
  url.searchParams.set("lon", String(longitude));
  url.searchParams.set("format", "jsonv2");

  const result = await fetchJson<NominatimResult & { address?: Record<string, string> }>(
    url.toString(),
    { headers: { "User-Agent": env.appUserAgent } }
  );

  if (!result) throw new HttpError(404, "No place was found for these coordinates.");

  return {
    displayName: result.display_name,
    latitude: Number(result.lat),
    longitude: Number(result.lon),
    address: result.address ?? {}
  };
}
