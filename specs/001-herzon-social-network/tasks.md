# Tasks: Herzon Social Network v1.1.0+2

## Phase 1 — Core Auth & Feed (P1)
- [x] T-001: Google Sign-In integration (native google_sign_in + supabase signInWithIdToken)
- [x] T-002: AuthRepository + AuthNotifier with state management
- [x] T-003: Post data model with PostGIS location support
- [x] T-004: PostRepository with proximity RPC queries
- [x] T-005: Feed screen with paginated post list
- [x] T-006: Post creation with media upload
- [x] T-007: Location service (GPS permission + initialization)

## Phase 2 — Real-time & Social (P2)
- [x] T-008: Real-time messaging via Supabase Realtime
- [x] T-009: Stories (24h ephemeral posts)
- [x] T-010: Follow/unfollow functionality
- [x] T-011: Notifications (FCM push)
- [x] T-012: Comments on posts
- [x] T-013: Reactions (likes/reactions)

## Phase 3 — Extended Features (P3)
- [x] T-014: Ride sharing (offer/request)
- [x] T-015: Marketplace (buy/sell items)
- [x] T-016: Gamification (XP, levels, leaderboard)
- [x] T-017: Check-in system
- [x] T-018: Admin dashboard (stats, moderation)

## Phase 4 — Quality & Infrastructure
- [x] T-019: Firebase Crashlytics + App Check + Performance
- [x] T-020: Hive offline cache
- [x] T-021: Feature flags + A/B experiments
- [x] T-022: 30 unit tests (repositories + providers)
- [x] T-023: MapLibre GL map integration
- [ ] T-024: Fix Gradle OOM for APK building
- [ ] T-025: Fix Firebase.initializeApp() missing (DONE in latest)
- [ ] T-026: Fix Google Sign-In cancel loading state (DONE)
- [ ] T-027: Fix duplicate authRepositoryProvider (DONE)
- [ ] T-028: Fix gamification maybeSingle() (DONE)
- [ ] T-029: Fix TrendingNotifier/SuggestionNotifier PostModel.fromJson (DONE)
- [ ] T-030: Fix admin missing _verifyAdmin() (DONE)
