import { env } from "../config/env";
import { fetchJson } from "./http.service";

export interface NearbyPlaceQuery {
  latitude: number;
  longitude: number;
  radiusMeters: number;
  category: "all" | "shops" | "pharmacies" | "food" | "healthcare";
}

interface OverpassElement {
  type: string;
  id: number;
  lat?: number;
  lon?: number;
  center?: { lat: number; lon: number };
  tags?: Record<string, string>;
}

interface OverpassResponse {
  elements: OverpassElement[];
}


const categoryFilters: Record<NearbyPlaceQuery["category"], string[]> = {
  all: [
    'node["shop"]',
    'way["shop"]',
    'node["amenity"~"pharmacy|cafe|restaurant|fast_food|hospital|clinic"]',
    'way["amenity"~"pharmacy|cafe|restaurant|fast_food|hospital|clinic"]'
  ],
  shops: [
    'node["shop"]',
    'way["shop"]'
  ],
  pharmacies: [
    'node["amenity"="pharmacy"]',
    'way["amenity"="pharmacy"]'
  ],
  food: [
    'node["amenity"~"cafe|restaurant|fast_food"]',
    'way["amenity"~"cafe|restaurant|fast_food"]'
  ],
  healthcare: [
    'node["amenity"~"hospital|clinic"]',
    'way["amenity"~"hospital|clinic"]'
  ]
};


export async function findNearbyPlaces(query: NearbyPlaceQuery) {
  const filters = categoryFilters[query.category]
    .map(
  (filter) =>
    `${filter.replace(/^(node|way)/, `$1(around:${query.radiusMeters},${query.latitude},${query.longitude})`)};`
)
    .join("\n");

  const overpassQuery = `[out:json][timeout:8];(${filters});out center tags;`;
  const response = await fetchJson<OverpassResponse>(
    "https://overpass.kumi.systems/api/interpreter",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
        "User-Agent": env.appUserAgent
      },
      body: new URLSearchParams({ data: overpassQuery }).toString()
    }
  );

  const places = response.elements.map((element) => {
    const latitude = element.lat ?? element.center?.lat;
    const longitude = element.lon ?? element.center?.lon;
    const tags = element.tags ?? {};
    if (latitude === undefined || longitude === undefined) return null;

    const name = tags.name ?? tags.brand ?? tags.operator ?? "Unnamed place";
    const amenity = tags.amenity ?? tags.shop ?? "place";

    return {
      id: `${element.type}/${element.id}`,
      name,
      category: amenity,
      latitude,
      longitude,
      address: [
        tags["addr:housenumber"],
        tags["addr:street"],
        tags["addr:suburb"],
        tags["addr:city"]
      ].filter(Boolean).join(", ") || null,
      openingHours: tags.opening_hours ?? null,
      phone: tags.phone ?? tags["contact:phone"] ?? null,
      website: tags.website ?? tags["contact:website"] ?? null,
      // OSM opening_hours values are raw tags, not verified live opening status.
      openingStatus: "unknown" as const
    };
  }).filter((place): place is NonNullable<typeof place> => place !== null);

  return {
    provider: "OpenStreetMap Overpass",
    disclaimer: "Map data may be incomplete or outdated. Opening status is not verified in real time.",
    count: places.length,
    places
  };
}
