# Claude Context — Proximité Mobile App

## Project Summary
You are building **Proximité**, a real-time proximity-based social network mobile app for Algeria.

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
| Maps | flutter_map + OpenStreetMap | Free, open-source, self-hosted tiles if needed |
| State Management | Riverpod / BLoC | Complex state (TBD with team) |
| Architecture | Clean Architecture | Presentation / Domain / Data layers |

---

## Architecture (Clean Architecture)

```
lib/
├── main.dart              # Entry point
├── app.dart               # MaterialApp setup
├── core/                  # Shared utilities
│   ├── constants/
│   ├── theme/
│   ├── errors/
│   └── utils/
├── features/              # One folder per feature
│   ├── auth/
│   ├── feed/
│   ├── explorer/
│   ├── profile/
│   └── messaging/
├── data/                  # Repositories & data sources
│   ├── models/
│   ├── repositories/
│   └── datasources/
└── presentation/          # UI & State (Riverpod/BLoC)
    ├── providers/
    ├── blocs/
    ├── screens/
    └── widgets/
```

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

## Rules For AI
- Do NOT start from scratch if a file can be reused.
- ALWAYS write `const` constructors for widgets.
- Use `async/await` with `Result<T, E>` for error handling in the domain layer.
- Prioritize performance for the map (clustering, limiting markers).
- Ensure all geospatial queries use PostGIS indexes.
- Keep UI reactive with Riverpod/BLoC, avoid setState for shared state.
- Follow Clean Architecture: Domain -> Data -> Presentation.

---

## Environment Variables
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_MAPS_API_KEY` (if switching to Google Maps later, for now use OSM)
