# Implementation Plan: Herzon v1.1.0+2

## Tech Stack
- **Runtime**: Flutter 3.44.6 · Dart 3.12.2
- **State**: Riverpod 2.x (StateNotifier + StateNotifierProvider)
- **Backend**: Supabase (PostgreSQL 15 + PostGIS 3.3 + Realtime)
- **Auth**: google_sign_in ^6.2.0 + supabase_flutter signInWithIdToken
- **Maps**: MapLibre GL ^0.26.2 + OSM tiles
- **Crash/Perf**: Firebase Crashlytics + App Check + Performance + Messaging
- **Cache**: Hive 2.x + hive_flutter
- **Build**: Gradle 8.13, NDK 28.2, compileSdk 36, minSdk 24, targetSdk 36
- **Signing**: D:\herzon-key.jks (alias: proximite, password: prox@2026Secure)
- **ABI**: arm64-v8a only

## Project Structure
```
lib/
├── main.dart              # Entry: Firebase → Crashlytics → Supabase → App Check → runApp
├── core/                  # Config, Theme, Design tokens, Constants
├── data/
│   ├── models/            # 12+ data classes with fromJson/toJson
│   └── repositories/      # 12+ repositories (abstract interface + Supabase impl)
├── services/              # Location, Notification, Crashlytics, Cache, Media Upload, Feature Flags
└── presentation/
    ├── providers/         # 15+ StateNotifier providers
    ├── screens/           # 20+ screens
    └── widgets/           # Shared widgets
```

## Supabase Schema (Key Tables)
- `profiles` — users with PostGIS geography(Point) location
- `posts` — content with PostGIS geography(Point), media URLs, reactions JSONB
- `stories` — ephemeral 24h content
- `messages` + `conversations` — realtime chat
- `ride_shares` — ride offers/requests
- `marketplace_items` — buy/sell listings
- `reports` — content moderation
- `check_ins` — location history
- `device_tokens` — FCM push tokens
- `feature_flags` + `user_experiments` — rollout control

## RPC Functions (PostGIS spatial queries)
- `get_trending_posts` — proximity + engagement sorting
- `get_nearby_leaderboard` — gamification ranking
- `get_nearby_marketplace_items` — marketplace by distance
- `get_user_gamification` — XP/level stats
- `admin_update_report_status` — moderation
- `admin_delete_post` — content removal

## Build Command
```
flutter build apk --release --split-per-abi --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Deployment Checklist
- [x] Google Cloud OAuth client (SHA-1: FE:A7:64:FE:3F:55:08:63:F4:01:63:F7:27:E7:DB:B3:99:1B:64:A5)
- [x] Supabase Google redirect URI (com.heron.app://login-callback)
- [x] Android deep link intent filter in AndroidManifest.xml
- [x] Firebase google-services.json with Web OAuth client ID
- [x] Release keystore at D:\herzon-key.jks
- [ ] Fix Gradle OOM for APK build
- [ ] Enable RLS on spatial_ref_sys exclusion in Supabase Dashboard
- [ ] ANPDP declaration (Algeria law 18-07)
