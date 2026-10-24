
type NearbyCategory =
  | "all"
  | "shops"
  | "pharmacies"
  | "food"
  | "healthcare";

interface NearbyPlacesParams {
  latitude: number;
  longitude: number;
  radiusMeters: number;
  category: NearbyCategory;
}

interface FoursquarePlace {
  fsq_place_id: string;
  name: string;
  latitude: number;
  longitude: number;
  distance?: number;
  location?: {
    formatted_address?: string;
    address?: string;
  };
  categories?: Array<{ name: string }>;
  tel?: string;
  website?: string;
}

const categoryQueries: Record<Exclude<NearbyCategory, "all">, string> = {
  shops: "shop",
  pharmacies: "pharmacy",
  food: "restaurant",
  healthcare: "hospital",
};

export async function findNearbyPlaces({
  latitude,
  longitude,
  radiusMeters,
  category,
}: NearbyPlacesParams) {
  console.log("\n========== FOURSQUARE DEBUG ==========");
  console.log("[Foursquare] Starting nearby search");
  console.log("[Foursquare] Coordinates:", { latitude, longitude });
  console.log("[Foursquare] Radius:", radiusMeters);
  console.log("[Foursquare] Category:", category);

  const apiKey = process.env.FOURSQUARE_API_KEY;

  console.log("[Foursquare] API key exists:", Boolean(apiKey));

  if (!apiKey) {
    console.error("[Foursquare] ERROR: API key missing");
    throw new Error("FOURSQUARE_API_KEY is missing from .env");
  }

  const params = new URLSearchParams({
    ll: `${latitude},${longitude}`,
    radius: String(radiusMeters),
    limit: "20",
    sort: "DISTANCE",
    fields:
      "fsq_place_id,name,latitude,longitude,distance,location,categories,tel,website",
  });

  if (category !== "all") {
    params.set("query", categoryQueries[category]);
  }

  const url =
    `https://places-api.foursquare.com/places/search?${params.toString()}`;

  console.log("[Foursquare] Request URL:", url);
  console.log("[Foursquare] Sending request...");

  let response: Response;

  try {
    response = await fetch(url, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "X-Places-Api-Version": "2025-06-17",
        Accept: "application/json",
      },
      signal: AbortSignal.timeout(10000),
    });
  } catch (error) {
    console.error("[Foursquare] FETCH ERROR:", error);
    throw error;
  }

  console.log("[Foursquare] HTTP status:", response.status);
  console.log("[Foursquare] Response OK:", response.ok);

  const responseText = await response.text();

  if (!response.ok) {
    console.error("[Foursquare] ERROR BODY:", responseText);
    throw new Error(`Foursquare API returned status ${response.status}`);
  }

  let data: { results?: FoursquarePlace[] };

  try {
    data = JSON.parse(responseText) as {
      results?: FoursquarePlace[];
    };
  } catch (error) {
    console.error("[Foursquare] Invalid JSON:", responseText);
    throw error;
  }

  console.log("[Foursquare] Results received:", data.results?.length ?? 0);

  const places = (data.results ?? []).map((place) => ({
    id: place.fsq_place_id,
    name: place.name,
    latitude: place.latitude,
    longitude: place.longitude,
    distance: place.distance ?? null,
    address:
  place.location?.formatted_address?.trim() ||
  place.location?.address?.trim() ||
  "Address unavailable",
    categories: (place.categories ?? []).map((item) => item.name),
    phone: place.tel ?? null,
    website: place.website ?? null,
  }));

  console.log("[Foursquare] Mapped places:", places.length);
  console.log("========== END FOURSQUARE DEBUG ==========\n");

  return {
    count: places.length,
    radiusMeters,
    category,
    places,
  };
}
