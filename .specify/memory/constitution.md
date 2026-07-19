# Herzon Constitution — Project Principles & Development Guidelines

## Core Identity
Herzon is a real-time proximity-based social network for Algeria. It connects users based on physical proximity, enabling local discovery, interaction, and community building.

## Architecture Principles
1. **Proximity-first**: All content discovery is location-based using PostGIS spatial queries.
2. **Real-time by default**: Feeds, messaging, and notifications update without manual refresh (Supabase Realtime).
3. **Offline resilience**: Core features degrade gracefully; cached data via Hive for offline browsing.
4. **Native authentication**: Google Sign-In via native SDK (`google_sign_in`), not browser OAuth popups.

## Code Quality Standards
1. **Repositories over direct DB access**: All Supabase queries go through repository classes. Providers never access Supabase directly.
2. **StateNotifier pattern**: All state uses Riverpod `StateNotifier` with immutable state classes and `copyWith`.
3. **Error handling**: Every async operation has try-catch. Catch blocks must at minimum `debugPrint` the error — empty catches are forbidden.
4. **Type safety**: Never use `dynamic`. All JSON parsing uses typed `fromJson` factories with explicit `as String`/`as int` casts.
5. **No secrets in code**: Supabase URL/anon key are compile-time `--dart-define`. No `.env` at runtime.

## Testing Standards
1. **Unit tests for all repositories**: Mock Supabase client, test each method.
2. **Provider tests**: Test state transitions (loading → data, loading → error).
3. **Min 80% coverage** for data layer and providers.

## Performance Requirements
1. **APK size < 40MB**: Tree-shake unused fonts/icons. Single ABI (arm64-v8a).
2. **Cold start < 3s**: Lazy-load non-critical services (Hive, feature flags after auth).
3. **Feed render < 500ms**: Paginate at 20 posts, virtualized list.
