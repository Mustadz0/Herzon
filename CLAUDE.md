# Claude Context — Herzon Mobile App

## Project Summary
You are building **Herzon**, a real-time proximity-based social network mobile app for Algeria.

### Core Concept
Users open the app and see real-time profiles and content from people within a **500m radius**. They can also explore any area of their city remotely without being physically there.

### Two Modes
- **"Je suis là" (Active)**: User is physically in the zone. Can post, react, message, follow, go live, and rate the vibe.
- **"Explorer" (Passive)**: User browses the city map. Read-only for non-premium users. Limited to 3 zones/day without Premium. The main engine of addiction.

---

## Tech Stack

| Layer | Technology | Description |
|-------|-----------|-------------|
| Mobile | Flutter 3.x | Primary framework for iOS & Android |
| Language | Dart | Null-safe, modern syntax |
| Backend | Supabase | Auth, PostgreSQL, Realtime, Storage |
| Geospatial | PostGIS | `ST_DWithin` for 500m queries |
| Maps | **MapLibre GL** (`maplibre_gl`) + OpenStreetMap tiles | Single map library — `latlong2` removed, use `maplibre_gl`'s own `LatLng` |
| State Management | **Riverpod** | `flutter_riverpod` + `riverpod_generator` — BLoC NOT used |
| Architecture | Clean Architecture | Presentation / Domain / Data layers |

---

## Architecture (Clean Architecture)

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp setup
├── core/
│   ├── config/
│   │   └── app_config.dart   # Compile-time secrets via --dart-define
│   ├── constants/
│   ├── theme/
│   ├── errors/
│   └── utils/
├── features/              # One folder per feature (target architecture)
│   ├── auth/
│   ├── feed/
│   ├── explorer/
│   ├── profile/
│   └── messaging/
├── data/                  # Repositories & data sources
│   ├── models/
│   ├── repositories/
│   └── datasources/
└── presentation/          # UI & State
    ├── providers/
    ├── screens/
    └── widgets/
```

---

## Environment Variables — IMPORTANT

Secrets are **NOT** stored in `.env` files bundled as assets.
They are injected at compile time via `--dart-define` and read via `AppConfig`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

For CI/CD use GitHub Actions secrets. Never commit real keys.

---

## Database (Supabase / PostgreSQL + PostGIS)

### Tables
- `profiles` (extends auth.users)
- `posts` (content, media, geolocation, context_tag)
- `reactions` (🔥, ⚡, 👀, ⏳)
- `messages` (DMs, only in Active mode or Premium)
- `follows` (self-referencing)
- `zones` (for atmosphere scoring)
- `reports` (content moderation)

### Key Geospatial Queries
- `ST_DWithin(location, current_location, 500)` for the 500m radius feed.
- `ST_SetSRID(ST_MakePoint(long, lat), 4326)` for point creation.

---

## Features (MVP)

### V1
- Google Auth + Anonymous mode
- Real-time 500m geofencing feed
- Text/Photo posts
- Basic Explorer map (read-only, 3 zones/day limit)
- Reactions (🔥, ⚡, 👀, ⏳)
- Basic user profiles & follow system
- Content reporting

### V2+
- Vibes (short videos)
- Live streaming + virtual gifts
- Premium subscription (unlimited explorer, profile views, etc.)
- Advanced notifications
- Pro accounts for businesses

---

## Map Usage Rules

- **ONLY** use `maplibre_gl` for maps — no `flutter_map`, no `latlong2`.
- Use `maplibre_gl`'s own `LatLng(lat, lng)` type everywhere.
- OSM tiles via `https://demotiles.maplibre.org/style.json` (free).
- For production: self-host tiles or use a paid tile provider (Maptiler, etc.).
- Cluster markers when > 10 points visible (performance rule).
- Never load all DB posts as markers — always limit to viewport bbox.

---

## Rules For AI
- Do NOT start from scratch if a file can be reused.
- ALWAYS write `const` constructors for widgets.
- Use `async/await` with `Result<T, E>` for error handling in the domain layer.
- Prioritize performance for the map (clustering, limiting markers).
- Ensure all geospatial queries use PostGIS indexes.
- Keep UI reactive with Riverpod, avoid setState for shared state.
- Follow Clean Architecture: Domain -> Data -> Presentation.
- Use `AppConfig.supabaseUrl` / `AppConfig.supabaseAnonKey` — never dotenv.
- State management: **Riverpod only** (no BLoC).
