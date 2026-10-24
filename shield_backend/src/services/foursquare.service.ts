
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

  hours?: {
    open_now?: boolean;
    display?: string;
  };
}

const categoryQueries: Record<
  Exclude<NearbyCategory, "all">,
  string
> = {
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
  const apiKey = process.env.FOURSQUARE_API_KEY;

  if (!apiKey) {
    throw new Error("FOURSQUARE_API_KEY is missing from .env");
  }

  const params = new URLSearchParams({
    ll: `${latitude},${longitude}`,
    radius: String(radiusMeters),
    limit: "20",
    sort: "DISTANCE",
    fields:
      "fsq_place_id,name,latitude,longitude,distance,location,categories,tel,website,hours",
  });

  if (category !== "all") {
    params.set("query", categoryQueries[category]);
  }

  const url =
    `https://places-api.foursquare.com/places/search?${params.toString()}`;

  const response = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "X-Places-Api-Version": "2025-06-17",
      Accept: "application/json",
    },
    signal: AbortSignal.timeout(10000),
  });

  const responseText = await response.text();

  if (!response.ok) {
  console.error(
    "[Foursquare] HTTP status:",
    response.status,
  );
  console.error(
    "[Foursquare] Error body:",
    responseText,
  );

  throw new Error(
    `Foursquare API returned status ${response.status}: ${responseText}`,
  );
}

  const data = JSON.parse(responseText) as {
    results?: FoursquarePlace[];
  };

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

    categories: (place.categories ?? []).map(
      (item) => item.name,
    ),

    phone: place.tel ?? null,
    website: place.website ?? null,

    // null means Foursquare did not provide the status.
    openNow: place.hours?.open_now ?? null,

    // May contain the provider's regular-hours display.
    hoursDisplay: place.hours?.display ?? null,
  }));

  return {
    count: places.length,
    radiusMeters,
    category,
    places,
  };
}
