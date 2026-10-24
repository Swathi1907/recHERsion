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

interface GeoapifyFeature {
  properties?: {
    place_id?: string;
    name?: string;
    lat?: number;
    lon?: number;
    distance?: number;
    formatted?: string;
    address_line1?: string;
    address_line2?: string;
    categories?: string[];
    datasource?: {
      raw?: Record<string, unknown>;
    };
  };
}

const categoryFilters: Record<NearbyCategory, string> = {
  all: [
    "commercial",
    "healthcare",
    "catering",
    "service",
  ].join(","),

  shops: "commercial",
  pharmacies: "healthcare.pharmacy",
  food: "catering.restaurant,catering.cafe,catering.fast_food",
  healthcare: "healthcare",
};

function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const radians = (value: number) => value * Math.PI / 180;
  const dLat = radians(lat2 - lat1);
  const dLon = radians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(radians(lat1)) *
      Math.cos(radians(lat2)) *
      Math.sin(dLon / 2) ** 2;

  return Math.round(
    6371000 *
      2 *
      Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)),
  );
}

export async function findNearbyPlaces({
  latitude,
  longitude,
  radiusMeters,
  category,
}: NearbyPlacesParams) {
  const apiKey = process.env.GEOAPIFY_API_KEY;

  if (!apiKey) {
    throw new Error("GEOAPIFY_API_KEY is missing from .env");
  }

  if (
    !Number.isFinite(latitude) ||
    latitude < -90 ||
    latitude > 90 ||
    !Number.isFinite(longitude) ||
    longitude < -180 ||
    longitude > 180
  ) {
    throw new Error("Invalid latitude or longitude.");
  }

  if (
    !Number.isFinite(radiusMeters) ||
    radiusMeters < 1 ||
    radiusMeters > 5000
  ) {
    throw new Error("radiusMeters must be between 1 and 5000.");
  }

  const categories = categoryFilters[category];

const params = new URLSearchParams({
  categories,
  filter: `circle:${longitude},${latitude},${radiusMeters}`,
  bias: `proximity:${longitude},${latitude}`,
  limit: "20",
  details: "details",
  apiKey,
});
  const response = await fetch(
    `https://api.geoapify.com/v2/places?${params.toString()}`,
    { signal: AbortSignal.timeout(15000) },
  );

  if (!response.ok) {
    const body = await response.text();

    console.error("[Geoapify] HTTP status:", response.status);
    console.error("[Geoapify] Error body:", body);

    throw new Error(
      `Geoapify API returned status ${response.status}: ${body.slice(0, 300)}`,
    );
  }

  const data = await response.json() as {
    features?: GeoapifyFeature[];
  };

  const places = (data.features ?? [])
    .map((feature) => {
      const p = feature.properties;

      if (
        !p ||
        typeof p.lat !== "number" ||
        typeof p.lon !== "number"
      ) {
        return null;
      }

      const raw = p.datasource?.raw ?? {};
      console.log("[Geoapify] Place properties:", JSON.stringify(p, null, 2));
      const distance = p.distance ??
        calculateDistance(latitude, longitude, p.lat, p.lon);

      return {
        id: p.place_id ?? `${p.lat},${p.lon}`,
        name: p.name ?? p.address_line1 ?? "Unnamed place",
        latitude: p.lat,
        longitude: p.lon,
        distance,
        address:
          p.formatted ??
          [p.address_line1, p.address_line2]
            .filter(Boolean)
            .join(", ") ??
          "Address unavailable",
        categories: p.categories ?? [],
        phone:
          typeof raw.phone === "string" ? raw.phone : null,
        website:
          typeof raw.website === "string" ? raw.website : null,
        // Geoapify's basic Places result doesn't guarantee live status.
        openNow: null,
        hoursDisplay:
          typeof raw.opening_hours === "string"
            ? raw.opening_hours
            : null,
      };
    })
    .filter((place) => place !== null)
    .sort((a, b) => a.distance - b.distance);

  return {
    count: places.length,
    radiusMeters,
    category,
    places,
    source: "Geoapify",
    attribution: "Data © OpenStreetMap contributors",
  };
}