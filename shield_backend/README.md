# SHIELD Backend

Initial API for the SHIELD Flutter safety app.

## Requirements

- Node.js 20 or later
- npm

## Setup (Windows PowerShell)

From the `shield_backend` directory:

```powershell
npm install
Copy-Item .env.example .env
```

Edit `.env` and replace the placeholder contact in `APP_USER_AGENT` with a descriptive app name and a real contact address. Do not commit `.env`.

Start development server:

```powershell
npm run dev
```

Check `http://localhost:3000/api/health`.

## API endpoints

### Health
`GET /api/health`

### Search places
`GET /api/places/search?q=Hirapur%20Bus%20Stand&limit=5`

Uses Nominatim. Follow the Nominatim usage policy; do not autocomplete on every keystroke or send bulk/high-volume requests.

### Reverse geocode
`GET /api/places/reverse?lat=23.795&lon=86.430`

### Driving route
`GET /api/routes?startLat=23.795&startLon=86.430&endLat=23.800&endLon=86.440&alternatives=true`

Returns route geometry as GeoJSON coordinates in `[longitude, latitude]` order, plus estimated distance and duration. The public OSRM demo server is best-effort and has no production SLA.

### Nearby places
`GET /api/places/nearby?lat=23.795&lon=86.430&radius=800&category=all`

Categories: `all`, `shops`, `pharmacies`, `food`, `healthcare`.

Overpass/OpenStreetMap data may be incomplete or outdated. The API deliberately returns `openingStatus: "unknown"` rather than claiming that a place is open now.

## Production notes

- Replace `CORS_ORIGINS=*` with the exact web origins you use. Native Flutter requests may not send an Origin header.
- Public Nominatim, OSRM and Overpass instances have usage limits and are not guaranteed production infrastructure. Review current policies before launch; consider a commercial provider or self-hosting.
- Do not present the fastest route as the safest route. Real safety scoring needs trustworthy, current safety data and a documented ranking method.
- SOS delivery, accounts, trusted contacts, evidence storage, and push notifications are not implemented by these initial endpoints.
- Add integration tests, authentication/authorization, monitoring, and a persistent cache before production use.
