# Herzon

A real-time proximity-based social network mobile application built with Flutter and Supabase.

## Overview

Herzon lets users discover and interact with people within a **500-meter radius** around them in real-time. The app features two modes:
- **Active Mode ("Je suis là")**: Post and interact when physically present in a zone.
- **Explorer Mode**: Browse the city map in read-only mode (3 zones/day for free users).

## Features (MVP)

- Real-time feed based on geolocation (500m radius)
- Google / Anonymous authentication
- Interactive map with OpenStreetMap (MapLibre GL)
- Text & photo posts with context tags
- Reactions (🔥, ⚡, 👀, ⏳)
- Real-time atmosphere scoring for zones
- Basic messaging (Active Mode)
- Content reporting
- Polls on posts
- Check-ins & Badges
- Gamification (XP / Leaderboard)
- Ride sharing
- Pages (organisations / events)
- AB Testing / Feature Flags

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3.x |
| Backend | Supabase (PostgreSQL + PostGIS) |
| Maps | **MapLibre GL** + OpenStreetMap tiles |
| Auth | Supabase Auth (OAuth + Anonymous) |
| State | **Riverpod** (flutter_riverpod) |
| Architecture | Clean Architecture |

## Architecture

```
lib/
├── main.dart
├── core/
│   ├── config/         # AppConfig — compile-time secrets via --dart-define
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   └── repositories/
├── services/           # Cross-cutting concerns (cache, crashlytics, notifications…)
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- A Supabase project (create one at [supabase.com](https://supabase.com))

### Installation

```bash
git clone https://github.com/Mustadz0/Herzon.git
cd Herzon
flutter pub get
```

### Environment Variables

Secrets are **NOT** stored in `.env` files. They are injected at compile time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

For CI/CD, use GitHub Actions secrets and pass them via `--dart-define`.

### Database Migrations

Run the SQL files in `supabase/migrations/` on your Supabase project in order.

### Run

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

## Core Geospatial Query

```sql
SELECT * FROM posts
WHERE ST_DWithin(
  location::geography,
  ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
  500  -- meters
);
```

## Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.
- Use `const` constructors for widgets whenever possible.
- Prefer `StateNotifier` / `AsyncNotifier` over `setState` for shared state.
- **State management: Riverpod only** — no BLoC.
- **Maps: MapLibre GL only** — no `flutter_map`, no `latlong2`.

## License

This project is proprietary and confidential.
