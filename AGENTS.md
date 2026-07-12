# Codex Context — Herzon Mobile App

## Project Summary
You are building **Herzon**, a real-time proximity-based social network mobile app for Algeria.

### Core Concept
Users open the app and see real-time profiles and content from people within a **500m radius**. They can also explore any area of their city remotely without being physically there.

### Two Modes
- **"Je suis là" (Active)**: User is physically in the zone. Can post, react, message, follow, go live, and rate the vibe.
- **"Explorer" (Passive)**: User browses the city map. Read-only for non-premium users. Limited to 3 zones/day without Premium.

---

## Tech Stack

| Layer | Technology | Description |
|-------|-----------|-------------|
| Mobile | Flutter 3.x | Primary framework for iOS & Android |
| Language | Dart | Null-safe, modern syntax |
| Backend | Supabase | Auth, PostgreSQL, Realtime, Storage |
| Geospatial | PostGIS | `ST_DWithin` for 500m queries |
| Maps | **MapLibre GL** (`maplibre_gl`) + OpenStreetMap | `latlong2` REMOVED — use `maplibre_gl`'s own `LatLng` |
| State Management | **Riverpod** (`flutter_riverpod`) | BLoC NOT used |
| Architecture | Clean Architecture | Presentation / Data / Core / Services |

---

## Architecture

```
lib/
├── main.dart
├── core/
│   ├── config/         # AppConfig — --dart-define secrets
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   └── repositories/
├── services/           # Cache, Crashlytics, Notifications, FeatureFlags…
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

## Environment Variables — CRITICAL

Secrets are injected at **compile time** via `--dart-define`. **No `.env` files.**

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Read values via `AppConfig.supabaseUrl` / `AppConfig.supabaseAnonKey`.

---

## Database (Supabase / PostgreSQL + PostGIS)

### Tables
- `profiles` (extends auth.users)
- `posts` (content, media, geolocation, context_tag, poll_options jsonb)
- `poll_votes` (post_id, option_index, user_id — unique per post/user)
- `reactions` (🔥, ⚡, 👀, ⏳)
- `messages` (DMs — Active mode or Premium only)
- `follows` (self-referencing)
- `zones` (atmosphere scoring)
- `reports` (content moderation)
- `blocks` (blocked users)
- `check_ins`, `badges`, `user_badges`
- `user_levels`, `xp_transactions`
- `ride_shares`, `ride_passengers`
- `pages`, `page_members`
- `experiments`, `experiment_assignments`, `feature_config`

---

## Rules For AI

- Do NOT start from scratch if a file can be reused.
- ALWAYS write `const` constructors for widgets.
- Use `async/await`; handle errors gracefully with try/catch.
- Prioritize map performance: cluster markers, limit to viewport bbox.
- Ensure geospatial queries use PostGIS indexes.
- Keep UI reactive with **Riverpod** — avoid `setState` for shared state.
- Use `AppConfig.supabaseUrl` / `AppConfig.supabaseAnonKey` — never dotenv.
- **Maps: `maplibre_gl` only** — never `flutter_map` or `latlong2`.
- **State: Riverpod only** — never BLoC.
- `SentryService` is a shim over Crashlytics — no `sentry_flutter` package needed.
