# Proximite

A real-time proximity-based social network mobile application built with Flutter and Supabase.

## Overview

**Proximite** lets users discover and interact with people within a **500-meter radius** around them in real-time. The app features two modes: an **Active Mode** ("Je suis l\u00e0") for posting and interacting when physically present, and an **Explorer Mode** ("Explorer") for browsing locations remotely with read-only access.

## Features (MVP)

- **Real-time feed** based on geolocation (500m radius)
- **Google & Anonymous authentication**
- **Interactive map** with OpenStreetMap (Explorer Mode)
- **Text & photo posts** with context tags
- **Reactions** (\ud83d\udd25, \u26a1, \ud83d\udc40, \u23f3)
- **Real-time atmosphere scoring** for zones
- **Basic messaging** (Active Mode)
- **Content reporting**

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x |
| Backend | Supabase (PostgreSQL + PostGIS) |
| Maps | flutter_map + OpenStreetMap |
| Auth | Supabase Auth (OAuth + Anonymous) |
| State | Riverpod |

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- A Supabase project (create one at [supabase.com](https://supabase.com))

### Installation

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd proximite-mobile
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your Supabase credentials.

4. Run database migrations on your Supabase project using the SQL file in `supabase/migrations/`.

5. Run the app:
   ```bash
   flutter run
   ```

## Architecture

```
lib/
\u251c\u2500\u2500 main.dart              # Entry point
\u251c\u2500\u2500 core/                  # Shared utilities
\u2502   \u251c\u2500\u2500 constants/
\u2502   \u251c\u2500\u2500 theme/
\u2502   \u2514\u2500\u2500 utils/
\u251c\u2500\u2500 data/                  # Repositories & models
\u2502   \u251c\u2500\u2500 models/
\u2502   \u2514\u2500\u2500 repositories/
\u251c\u2500\u2500 services/             # Business logic
\u251c\u2500\u2500 presentation/          # UI & State
    \u251c\u2500\u2500 providers/
    \u251c\u2500\u2500 screens/
    \u2514\u2500\u2500 widgets/
```

## Core Geospatial Query

The app uses PostGIS's `ST_DWithin` for efficient proximity queries:

```sql
SELECT *
FROM posts
WHERE ST_DWithin(
  location::geography,
  ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
  500  -- meters
);
```

## Development

### Generating Freezed Models

After changing models, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Code Style

- Follow the [Effective Dart](https://dart.dev/effective-dart) guidelines.
- Use `const` constructors for widgets whenever possible.
- Prefer `StateNotifier` or `AsyncNotifier` over `setState` for shared state.

## License

This project is proprietary and confidential.
