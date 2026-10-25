# 🛡️ SafeHer: Women's Safety App

> **Prevent. Respond. Recover.**
> A mobile app that helps women stay safe in the physical and digital world with one-tap SOS, safest-route navigation, a tamper-proof evidence vault, and online protection tools.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express-000000?logo=express&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)

---

## 📌 Problem Statement

**PS2: Women's Safety**
Women face safety challenges in both physical and digital spaces: harassment, unsafe routes, privacy breaches, online threats and identity misuse. SafeHer is a practical, privacy-first solution that helps women protect themselves, seek help quickly and keep proof when something goes wrong.

---

## ✨ Features

### 🚨 Emergency response
| Feature | Description |
|---|---|
| **One-tap SOS** | Big SOS button with a 3-second countdown to avoid false alarms |
| **Shake to trigger** | Shake the phone 3 times to send SOS without looking at the screen |
| **Live location sharing** | Contacts see real-time movement on a map (Supabase Realtime) |
| **Auto-recording** | Audio/video starts automatically when SOS is active |
| **Siren** | Loud alarm to attract attention |
| **PIN to end SOS** | Prevents anyone else from switching it off |

### 🧭 Safest route vs shortest route
- Fetches multiple route alternatives for a trip.
- The Node.js backend gives each route a **safety score (0 to 100)** based on:
  - Street lighting
  - Open shops and places nearby
  - Crowd level
  - CCTV coverage
  - Community-reported incidents
  - Time of day
- Shows the trade-off clearly, for example *"Safest route: +5 min, score 92 vs Fastest: score 58"*.
- Starts navigation with live sharing turned on.

### 🔐 Evidence vault
- Save **audio, video, photos, screenshots and notes**.
- Files are **encrypted on the device** before upload.
- Each file gets a **SHA-256 hash, timestamp and GPS location**, so any later edit can be detected.
- Stored in a **private Supabase Storage bucket**.
- **Disguise mode**: the app can look like a calculator.
- **Case pack export**: one-tap PDF with evidence list and timeline for police, lawyers or NGOs.

### 👭 Trusted circle
- Add guardians and friends who receive SOS alerts.
- Live sharing stops automatically after a set time.
- Check-in timer: if you don't confirm arrival, your circle is alerted.
- Nearby help: police stations, hospitals and helplines.

### 📞 Extras
- **Fake call** to leave uncomfortable situations.
- **Community hazard reports** to improve route safety scores.

### 🌐 Digital shield
- Privacy health check
- Stalkerware / suspicious app awareness
- Image misuse reporting guide
- Save online abuse screenshots straight to the vault
- Draft complaint for the cybercrime portal

---

## 🏗️ Architecture

```
┌──────────────────┐        REST / JWT        ┌─────────────────────┐
│  Flutter App     │ ───────────────────────▶ │  Node.js + Express  │
│  (Android / iOS) │ ◀─────────────────────── │  (business logic)   │
└────────┬─────────┘                          └──────────┬──────────┘
         │  Auth, Realtime, Storage                      │ service role
         ▼                                               ▼
┌────────────────────────────────────────────────────────────────────┐
│                           Supabase                                 │
│   Auth (Phone OTP) · Postgres (+ PostGIS) · RLS · Realtime · Storage│
└────────────────────────────────────────────────────────────────────┘
```

**Responsibilities**
- **Flutter:** UI, sensors (shake), recording, encryption, maps, background location.
- **Express:** SOS alert dispatch, safe-route scoring, case pack generation, notifications.
- **Supabase:** user auth, database, file storage, realtime location, row-level security.

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Dart) |
| State management | Riverpod / Provider *(update to what you used)* |
| Backend API | Node.js, Express |
| Database & Auth | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| Maps & routing | Google Maps / OSRM *(update to what you used)* |
| Notifications / SMS | FCM, Twilio *(update to what you used)* |

---

## 📁 Project Structure

> Adjust to match your repository.

```
safeher/
├── mobile/                 # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/        # home, route, vault, circle, shield
│   │   ├── services/       # api, supabase, location, encryption
│   │   ├── widgets/
│   │   └── theme/
│   └── pubspec.yaml
├── backend/                # Node.js + Express API
│   ├── src/
│   │   ├── routes/         # sos, routes, vault, contacts, reports
│   │   ├── controllers/
│   │   ├── services/       # safetyScore, alerts, casePack
│   │   ├── middleware/     # auth (Supabase JWT)
│   │   └── server.js
│   ├── .env.example
│   └── package.json
├── supabase/
│   └── schema.sql          # tables, RLS policies
└── README.md
```

---

## 🗄️ Database Overview

| Table | Purpose |
|---|---|
| `profiles` | User details and settings |
| `contacts` | Trusted circle members |
| `sos_events` | SOS history, status and location |
| `live_shares` | Active live location sessions |
| `evidence` | Vault metadata: storage path, hash, GPS, timestamp |
| `incident_reports` | Community hazard reports (geo point) |
| `safety_pois` | Lighting, CCTV, open places for route scoring |

**Security:** Row Level Security (RLS) is enabled so every user can only read and write her own data.

---

## 🔌 API Endpoints


| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/sos/start` | Start SOS and alert contacts |
| `POST` | `/api/sos/end` | End SOS (PIN verified) |
| `GET` | `/api/routes?from=&to=` | Get routes with safety scores |
| `POST` | `/api/evidence` | Save evidence metadata and hash |
| `GET` | `/api/evidence/casepack` | Generate case pack PDF |
| `GET/POST` | `/api/contacts` | List / add trusted contacts |
| `POST` | `/api/reports` | Submit a hazard report |



---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x or later)
- Node.js 18+
- A Supabase project
- Android Studio / Xcode, or a physical device

### 1. Clone
```bash
git clone https://github.com/<your-username>/safeher.git
cd safeher
```

### 2. Set up Supabase
1. Create a project at [supabase.com](https://supabase.com).
2. Run `supabase/schema.sql` in the SQL editor.
3. Enable **Phone auth** under Authentication → Providers.
4. Create a **private** storage bucket named `evidence`.
5. Copy your **Project URL**, **anon key** and **service role key**.

### 3. Run the backend
```bash
cd backend
npm install
cp .env.example .env     # then fill in the values
npm run dev
```

`.env` example:
```env
PORT=5000
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_JWT_SECRET=your_jwt_secret
GOOGLE_MAPS_API_KEY=your_maps_key
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE=your_number
```

> ⚠️ Never put the service role key in the Flutter app or commit `.env` to Git.

### 4. Run the Flutter app
```bash
cd mobile
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=API_BASE_URL=http://<your-ip>:5000
```

Use your computer's local IP (not `localhost`) when testing on a real device.

### 5. Android permissions
Make sure the app requests: location (including background), camera, microphone, notifications and phone/SMS if used.

---

## 🔄 User Flow

```
Plan trip ─▶ Pick safest route ─▶ Live share ON
                                      │
                        Danger? Shake / Tap SOS
                                      │
              3s countdown ─▶ Alerts + Live location + Recording
                                      │
                  Evidence encrypted, hashed, stored in vault
                                      │
                  Case pack PDF ─▶ Police / Lawyer / NGO
```

---

## 🔒 Privacy & Security

- Phone OTP login, no passwords
- Row Level Security on all user tables
- Evidence encrypted on-device; the key stays in secure storage
- SHA-256 hashing to prove files were not changed
- Location shared only with chosen contacts, with automatic expiry
- Disguise mode for discreet use
- Secrets kept only on the server



---

## 📄 License

This project is built for a hackathon. Licensed under the [MIT License](LICENSE).

---

Demo Video Drive link: https://drive.google.com/file/d/10Peuzeu07TX_nvXRGkbap-5okpcGD7EH/view?usp=sharing
---
Ppt Drive link: https://drive.google.com/file/d/1kC15rZ6jGQ3lxPqK-bKR6_vr-86H1cn-/view?usp=sharing
<p align="center"><b>Safety should be one tap away. 💜</b></p>

