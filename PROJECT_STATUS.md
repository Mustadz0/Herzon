# Herzon — Project Status

## Last Updated: 2026-07-11
## Version: 1.3.0

---

## ✅ Overall Health

| Layer | Status | Count |
|-------|--------|-------|
| Supabase Migrations | ✅ Applied | 041 migrations |
| Models (Dart) | ✅ Complete | 19 models |
| Repositories | ✅ Complete | 19 repositories |
| Providers (Riverpod) | ✅ Complete | 25 providers |
| Screens | ✅ Complete | See below |
| Widgets | ✅ Complete | See below |

---

## 🗄️ Supabase Migrations (041 total — all applied)

| Range | Description |
|-------|-------------|
| 001–021 | Core schema: users, posts, feed, reactions, marketplace, polls, blocks, interests, pages, checkins, badges, rides, gamification, A/B testing, security |
| 022 | Privacy settings + invisible mode |
| 023 | Verified accounts |
| 024 | Messages system |
| 025–027 | Pages fixes + nearby queries |
| 028–033 | Security constraints, admin functions, crash reports |
| 034–038 | Conversation fix, reactions trigger, push notification trigger, admin RPC hardening, sticker_id fix |
| 039–041 | **Explorer Zones**: zone_snapshots, zones tables, get_nearby_zones RPC, get_zone_posts RPC with block filter, refresh_zone_heat() + pg_cron, RLS authenticated-only, anon EXECUTE revoked |

---

## 📦 Models (`lib/data/models/`)

- `user_model.dart` · `post_model.dart` · `message_model.dart` · `story_model.dart`
- `comment_model.dart` · `notification_model.dart` · `poll_model.dart` · `checkin_model.dart`
- `badge_model.dart` · `blocked_user_model.dart` · `user_interest_model.dart`
- `marketplace_item_model.dart` · `page_model.dart` · `ride_model.dart`
- `gamification_model.dart` · `experiment_model.dart`
- `zone_model.dart` · `zone_post_model.dart` ✅ **NEW**

---

## 🔌 Repositories (`lib/data/repositories/`)

- `auth_repository.dart` · `post_repository.dart` · `comment_repository.dart`
- `story_repository.dart` · `follow_repository.dart` · `block_repository.dart`
- `notification_repository.dart` · `message_repository.dart` · `marketplace_repository.dart`
- `poll_repository.dart` · `checkin_repository.dart` · `ride_repository.dart`
- `gamification_repository.dart` · `page_repository.dart` · `suggestion_repository.dart`
- `feature_flag_repository.dart` · `admin_repository.dart`
- `zone_repository.dart` · `zone_feed_repository.dart` ✅ **NEW**

---

## 🎛️ Providers (`lib/presentation/providers/`)

- `auth_provider.dart` · `post_provider.dart` · `story_provider.dart`
- `notification_provider.dart` · `messenger_provider.dart` · `messages_provider.dart`
- `follow_provider.dart` · `block_provider.dart` · `poll_provider.dart`
- `checkin_provider.dart` · `ride_provider.dart` · `gamification_provider.dart`
- `marketplace_provider.dart` · `page_provider.dart` · `profile_provider.dart`
- `privacy_provider.dart` · `suggestion_provider.dart` · `trending_provider.dart`
- `feature_flag_provider.dart` · `admin_provider.dart` · `admin_posts_provider.dart`
- `admin_reports_provider.dart` · `admin_stats_provider.dart` · `admin_users_provider.dart`
- `zone_provider.dart` · `zone_feed_provider.dart` ✅ **NEW**

---

## 📱 Feature Completion

| Feature | Status | Notes |
|---------|--------|-------|
| Auth (Google/Anonymous) | ✅ Done | Riverpod + Supabase Auth |
| Proximity Feed (500m) | ✅ Done | PostGIS ST_DWithin |
| Stories | ✅ Done | 24h expiry, views tracking |
| Comments | ✅ Done | Nested, RLS secured |
| Reactions | ✅ Done | Multiple types |
| Follow/Unfollow | ✅ Done | |
| Block Users | ✅ Done | Feed + messages filtered |
| Notifications | ✅ Done | Push + in-app |
| Messaging (DM) | ✅ Done | Realtime via Supabase |
| Marketplace | ✅ Done | Buy/sell items |
| Polls | ✅ Done | |
| Check-ins + Badges | ✅ Done | Gamification layer |
| Ride Share | ✅ Done | |
| Pages (Business) | ✅ Done | |
| A/B Testing | ✅ Done | Feature flags |
| Privacy / Invisible Mode | ✅ Done | |
| Verified Accounts | ✅ Done | |
| Admin Dashboard | ✅ Done | Stats, reports, user mgmt |
| **Explorer Zones (Heat Map)** | ✅ Done | Migrations 039-041, ZoneProvider, ZoneFeedProvider |
| Trending Posts | ✅ Done | |
| Premium Paywall | 🔄 Planned | Next sprint |
| Live Streaming | 🔄 Planned | |

---

## 🏗️ Architecture

- **State Management**: Riverpod (StateNotifierProvider, FutureProvider, family)
- **Database**: Supabase + PostgreSQL 17 + PostGIS (extensions schema)
- **Auth**: Supabase Auth (Google OAuth + Anonymous)
- **Maps**: MapLibre GL (`maplibre_gl`) + OpenStreetMap (no API key needed)
- **Models**: Freezed (immutable + JSON serializable)
- **Pattern**: Clean Architecture — Model → Repository → Provider → Screen

---

## 🔒 Security Posture

- RLS enabled on **all** tables
- All RPCs: `SECURITY DEFINER` with explicit `search_path`
- `anon` role: **no EXECUTE** on sensitive RPCs (zones, admin, spatial)
- PostGIS moved to `extensions` schema (no `public` schema leak)
- All `SECURITY DEFINER` views dropped and recreated with proper ownership
- Crash reports + admin audit logs in place

---

## 🚀 Next Steps

### Sprint 1 (Current)
- [ ] Premium paywall / subscription tiers
- [ ] Zone feed UI polish (animations, empty states)

### Sprint 2
- [ ] Live streaming (WebRTC or Supabase Realtime broadcast)
- [ ] Pro accounts for businesses
- [ ] Analytics dashboard (DAU, MAU, retention)

### Deployment
```bash
# Development
flutter run

# Release APK
flutter build apk --release

# Google Play
flutter build appbundle --release
```

---

## 📊 KPIs

- **Primary**: DAU (Daily Active Users)
- **Target**: 100–500 users — Algeria school launch
- **Expansion**: National → MENA region

---

## 🔗 Resources

- [Flutter Docs](https://docs.flutter.dev)
- [Supabase Docs](https://supabase.com/docs)
- [Riverpod Docs](https://riverpod.dev)
- [PostGIS Docs](https://postgis.net/documentation/)
- [flutter_map](https://docs.fleaflet.dev)
