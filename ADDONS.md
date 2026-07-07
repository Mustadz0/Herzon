# ADDONS — Proximité Extended Features

This document catalogs all 8 add-on features built on top of the core Proximité social network (posts, feed, auth, stories, trending, comments, reactions, follow, marketplace, notifications, onboarding, user search).

The pattern for every addon is **backend-first**: SQL migration (tables + RPCs + triggers) → Dart model → repository → provider → Flutter screens/widgets → navigation wire-up.

---

## 1. Polls 🗳️

**Migration:** `008_polls.sql`

Enables inline polls on posts. Users create a post with multiple choice options; other users vote once per post. Results shown as percentage bars.

### Database
- `posts` extended with `poll_options jsonb` column
- `poll_votes` table: `post_id`, `option_index`, `user_id` (unique per post+user)
- RPCs: `vote_poll(post_id, option_index)`, `get_poll_results(post_id)`

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/poll_model.dart` — `PollModel`, `PollOptionItem` |
| Model | `lib/data/models/post_model.dart` — `PollOptionData`, `pollOptions`, `userPollVoteIndex`, `pollTotalVotes` |
| Repository | `lib/data/repositories/poll_repository.dart` — `IPollRepository`, `SupabasePollRepository` |
| Provider | `lib/presentation/providers/poll_provider.dart` — `PollNotifier` |
| Widget | `lib/presentation/widgets/poll_widget.dart` — inline vote UI with bars |
| Widget | `lib/presentation/widgets/poll_creation_widget.dart` — poll builder in post creation |
| Widget | `lib/presentation/widgets/post_card.dart` — `_buildPoll()` renders inline poll |

### Integration
- Rendered inline in `PostCard` via `_buildPoll()`
- Voting triggers `pollProvider.vote()` → refreshes feed
- XP **auto-earned** by post author via DB trigger on `reactions` (2 XP per reaction)

### Status ✅ Complete

---

## 2. Blocked Users 🚫

**Migration:** `009_blocked_users.sql`

Allows users to block/unblock others. Blocked users' posts and content are excluded from feed, search, and leaderboard queries.

### Database
- `blocks` table: `blocker_id`, `blocked_id`, `reason`, `created_at`
- RPC: `get_blocked_user_ids(p_current_user_uuid)` used by all spatial RPCs to filter results

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/blocked_user_model.dart` |
| Repository | `lib/data/repositories/block_repository.dart` — `IBlockRepository`, `SupabaseBlockRepository` |
| Provider | `lib/presentation/providers/block_provider.dart` — `BlockNotifier` (load, block, unblock) |
| Screen | `lib/presentation/screens/settings_screen.dart` — blocked users list with unblock |
| Screen | `lib/presentation/screens/user_profile_screen.dart` — Block/Débloquer button with undo toast |
| Screen | `lib/presentation/screens/home_screen.dart` — settings icon in profile tab |

### Integration
- **Profile screen**: button "Bloquer" on other users' profiles with snackbar + undo
- **Settings screen**: view all blocked users, unblock with one tap
- **All spatial queries**: `get_nearby_posts`, `get_nearby_leaderboard`, etc. call `get_blocked_user_ids()` internally

### Status ✅ Complete

---

## 3. Interest-Based Suggestions 💡

**Migration:** `010_user_interests.sql`

Tracks user interests and interaction history to suggest relevant users, posts, and pages. Uses interest overlap scoring.

### Database
- `user_interests` table: `user_id`, `interest_tag`, `weight`
- `interactions` table: `user_id`, `target_id`, `interaction_type`, `context_tag`
- RPC: `get_suggestions_for_user(p_user_id, p_limit)` — returns ranked suggestions by interest similarity

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/user_interest_model.dart` — `UserInterestModel` |
| Repository | `lib/data/repositories/user_interest_repository.dart` — `IUserInterestRepository` |
| Provider | `lib/presentation/providers/suggestion_provider.dart` — `SuggestionNotifier` |

### Status ✅ Complete
- Explorer tab has a toggle button (💡) that opens a suggestion panel
- Panel shows suggested posts ranked by relevance (location × interest match)
- Suggestion posts render as `PostCard` widgets (reactions, comments, polls fully supported)
- Refresh button reloads suggestions from the `get_suggested_posts` RPC

---

## 4. Pages / Multi-Accounts 📄

**Migration:** `011_pages.sql`

Users can create organisation/event/commerce pages separate from their personal profile. Pages have dedicated feeds, members, and discovery on the map.

### Database
- `pages` table: `owner_id`, `name`, `slug`, `category`, `description`, `avatar_url`, `banner_url`, `contact_email`, `phone`, `website`, `lat/lng`, `address`, `is_active`
- `page_members` table: `page_id`, `user_id`, `role`
- RPC: `get_nearby_pages(p_user_lat, p_user_lng, p_radius_meters, p_category)`

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/page_model.dart` — `PageModel`, `PageMemberModel` |
| Repository | `lib/data/repositories/page_repository.dart` — `IPageRepository`, `SupabasePageRepository` |
| Provider | `lib/presentation/providers/page_provider.dart` — `PageNotifier` |
| Screen | `lib/presentation/screens/page_list_screen.dart` — browse + create page (bottom sheet form) |
| Screen | `lib/presentation/screens/page_detail_screen.dart` — page profile with banner, avatar, contact info |

### Integration
- Profile tab → "Pages" menu tile → `PageListScreen`
- Page list page has FAB "+" → create page bottom sheet with name, slug, description, category dropdown
- Tap page → `PageDetailScreen` with banner, avatar, bio, contact, website

### Status ✅ Complete

---

## 5. Check-ins & Badges 🏅

**Migration:** `012_checkins_badges.sql`

Users can check in at their current location to earn badges and XP. Badges are awarded automatically based on milestones.

### Database
- `checkins` table: `user_id`, `place_name`, `latitude`, `longitude`
- `badges` table: `id`, `name`, `description`, `icon_url`, `category`, `criteria_description`
- `user_badges` table: `user_id`, `badge_id`, `awarded_at`
- **Trigger**: auto-awards a "Premier Check-in" badge on first check-in; "Explorateur" badge on 10 check-ins
- RPC: `get_user_badges(p_user_id)`, `get_available_badges()`

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/checkin_model.dart` — `CheckinModel` |
| Model | `lib/data/models/badge_model.dart` — `BadgeModel`, `UserBadgeModel` |
| Repository | `lib/data/repositories/checkin_repository.dart` — `ICheckinRepository` |
| Provider | `lib/presentation/providers/checkin_provider.dart` — `CheckinNotifier` |
| Screen | `lib/presentation/screens/badges_screen.dart` — badge grid (earned/locked) |
| Sheet | `lib/presentation/screens/home_screen.dart` — `_CheckInSheet` bottom sheet |

### Integration
- Profile tab → "Check-in" menu tile → opens bottom sheet → "Check-in maintenant" button
- Triggers `checkinProvider.checkin(placeName, lat, lng)` + immediately reloads gamification
- Badges screen accessible via "Badges" menu tile shows earned badges with shiny effect, locked badges greyed out

### Status ✅ Complete

---

## 6. Ride Sharing 🚗

**Migration:** `013_ride_shares.sql`

Users can offer and book rides within the proximity radius. Drivers post routes; passengers can book seats.

### Database
- `ride_shares` table: `driver_id`, `origin_lat/lng`, `destination_lat/lng`, `origin_address`, `destination_address`, `departure_time`, `available_seats`, `price_per_seat`, `status`
- `ride_passengers` table: `ride_share_id`, `passenger_id`, `status` (pending/accepted/rejected/cancelled)
- RPCs: `get_nearby_rides(p_user_lat, p_user_lng, p_radius_meters)`, `book_ride(p_ride_id, p_passenger_id)`

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/ride_model.dart` — `RideModel`, `RidePassengerModel` |
| Repository | `lib/data/repositories/ride_repository.dart` — `IRideRepository`, `SupabaseRideRepository` |
| Provider | `lib/presentation/providers/ride_provider.dart` — `RideNotifier` |
| Screen | `lib/presentation/screens/ride_sharing_screen.dart` — nearby ride list |
| Widget | `lib/presentation/widgets/ride_card.dart` — origin→destination card |

### Integration
- Profile tab → "Covoiturage" menu tile → `RideSharingScreen`
- Ride cards show origin/destination, departure time, seats, price
- Pull-to-refresh loads nearby rides from `get_nearby_rides` RPC

### Status ✅ Complete

---

## 7. Gamification / XP / Leaderboard 🏆

**Migration:** `014_gamification.sql`

Full XP and level system. Users earn XP automatically via DB triggers on posts, reactions, comments, and check-ins. Leaderboard shows top users by XP within proximity.

### Database
- `user_levels` table: `user_id`, `xp`, `level`, `total_posts`, `total_reactions_received`, `total_comments_received`, `total_checkins`
- `xp_transactions` table: audit trail of every XP earn
- **DB triggers**: post created → +10 XP, reaction received → +2 XP, comment received → +5 XP, check-in → +10 XP
- RPCs: `get_user_gamification(p_user_id)` — returns xp, level, next_level_xp, progress_percent, stats
- RPCs: `get_nearby_leaderboard(p_user_lat, p_user_lng, p_radius_meters, p_limit)` — ranked by XP

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/gamification_model.dart` — `UserLevelModel`, `XpTransactionModel`, `LeaderboardEntryModel` |
| Repository | `lib/data/repositories/gamification_repository.dart` — `IGamificationRepository` |
| Provider | `lib/presentation/providers/gamification_provider.dart` — `GamificationNotifier` |
| Widget | `lib/presentation/widgets/xp_level_badge.dart` — `XpLevelBadge` widget (full + compact), `_BadgeCircle`, `showXpSnackBar()` helper |
| Screen | `lib/presentation/screens/leaderboard_screen.dart` — podium + level tab + rank list + achievements |
| Screen | `lib/presentation/screens/user_profile_screen.dart` — XP card (level badge + progress bar) |

### XP Toast Integration
| Action | XP | Toast |
|--------|----|-------|
| Réaction | +2 XP | `post_card.dart` after `reactToPost()` |
| Commentaire | +5 XP | `comments_screen.dart` after `addComment()` |
| Publication | +10 XP | `post_provider.dart` `createPost()` returns 10 (caller handles toast) |
| Check-in | +10 XP | `_CheckInSheet` after successful check-in |

### Integration
- **Own profile**: XP card with level badge, progress bar, level-up milestone text (home screen profile tab)
- **Other profile**: XP card when viewing other users (user_profile_screen.dart)
- **Reaction chip**: "+2 XP" snackbar toast on every reaction
- **Comment send**: "+5 XP !" snackbar toast
- **Leaderboard**: profile menu → "Classement" → podium UI (gold/silver/bronze) + rank list + level tab + achievements grid

### Status ✅ Complete

---

## 8. A/B Testing & Feature Flags 🎛️

**Migration:** `015_ab_testing.sql`

Remote toggle of features without app store updates. A/B experiments with variant assignment. Used by admins to roll out features gradually.

### Database
- `experiments` table: `name`, `description`, `variants jsonb`, `targeting_rules`, `is_active`
- `experiment_assignments` table: `experiment_id`, `user_id`, `variant`
- `feature_config` table: `flag_key`, `is_enabled`, `targeting_rules`, `updated_at` (upsert-based)
- RPCs: `assign_user_to_experiment(p_experiment_id, p_user_id)`, `get_user_feature_flags(p_user_id)`, `get_user_experiments(p_user_id)`

### Files
| Layer | File |
|-------|------|
| Model | `lib/data/models/experiment_model.dart` — `ExperimentModel`, `ExperimentVariant`, `ExperimentAssignmentModel`, `FeatureConfigModel` |
| Repository | `lib/data/repositories/feature_flag_repository.dart` — `IFeatureFlagRepository`, `SupabaseFeatureFlagRepository` |
| Provider | `lib/presentation/providers/feature_flag_provider.dart` — `FeatureFlagNotifier` (loadFlags, getFlagValue, loadExperiments) |
| Service | `lib/services/feature_flag_service.dart` — Hive-backed caching layer for offline-first flag resolution |
| Screen | `lib/presentation/screens/admin_feature_flags_screen.dart` — toggle each flag on/off, experiment info panel |

### Integration
- Admin only (requires `is_admin = true` on profile)
- Profile tab → "Feature Flags" menu tile (hidden from non-admin users)
- Flags state loaded via `featureFlagProvider` and consumed via `getFlagValue<T>(key, default)`
- Feature flags are consumed in app code via the `FeatureFlagService` singleton

### Status ✅ Complete

---

## Architecture Pattern

Every addon follows the same layering:

```
SQL Migration (supabase/migrations/0XX_*.sql)
  ├── Tables + Indexes + RLS
  ├── Functions / RPCs (SECURITY DEFINER, SET search_path = 'public')
  └── Triggers (auto-XP, auto-badges)

Dart Model (lib/data/models/*_model.dart)
  └── Plain Dart class with fromJson / toJson

Repository (lib/data/repositories/*_repository.dart)
  ├── Abstract interface (I*Repository)
  └── Supabase implementation (Supabase*Repository)

Provider (lib/presentation/providers/*_provider.dart)
  └── StateNotifier with copyWith pattern

Screen / Widget (lib/presentation/screens/*.dart / widgets/*.dart)
  └── ConsumerWidget / ConsumerStatefulWidget

Navigation (lib/presentation/screens/home_screen.dart + lib/main.dart routes)
  └── MenuTile in profile tab + route registration
```

## Key Decisions

- **No Freezed / build_runner** — all models are handwritten to avoid build_runner dependency issues
- **Offline-first** — `CacheService` (Hive) caches posts/stories/user data; `FeatureFlagService` has Hive fallback
- **XP hardcoded client-side** — toast values match DB trigger values: post=10, reaction=2, comment=5, check-in=10
- **Admin-only flags** — feature flags UI hidden behind `is_admin` gate
- **No pagination on lists yet** — profile posts, comments, and most lists fetch all at once (future optimization)
- **Suggestions backend complete, no UI** — models, repo, provider exist but Explorer tab hasn't been extended with suggestion cards yet

## File Inventory

### New Models (9)
| File | Classes |
|------|---------|
| `poll_model.dart` | `PollModel`, `PollOptionItem` |
| `blocked_user_model.dart` | — |
| `badge_model.dart` | `BadgeModel`, `UserBadgeModel` |
| `checkin_model.dart` | `CheckinModel` |
| `page_model.dart` | `PageModel`, `PageMemberModel` |
| `ride_model.dart` | `RideModel`, `RidePassengerModel` |
| `gamification_model.dart` | `UserLevelModel`, `XpTransactionModel`, `LeaderboardEntryModel` |
| `experiment_model.dart` | `ExperimentModel`, `ExperimentVariant`, `ExperimentAssignmentModel`, `FeatureConfigModel` |
| `user_interest_model.dart` | `UserInterestModel` |

### New Repositories (8)
| File | Interface |
|------|-----------|
| `poll_repository.dart` | `IPollRepository` |
| `block_repository.dart` | `IBlockRepository` |
| `checkin_repository.dart` | `ICheckinRepository` |
| `ride_repository.dart` | `IRideRepository` |
| `page_repository.dart` | `IPageRepository` |
| `gamification_repository.dart` | `IGamificationRepository` |
| `feature_flag_repository.dart` | `IFeatureFlagRepository` |
| `suggestion_repository.dart` | `ISuggestionRepository` |

### New Providers (8)
| File | Notifier |
|------|----------|
| `poll_provider.dart` | `PollNotifier` |
| `block_provider.dart` | `BlockNotifier` |
| `checkin_provider.dart` | `CheckinNotifier` |
| `ride_provider.dart` | `RideNotifier` |
| `page_provider.dart` | `PageNotifier` |
| `gamification_provider.dart` | `GamificationNotifier` |
| `feature_flag_provider.dart` | `FeatureFlagNotifier` |
| `suggestion_provider.dart` | `SuggestionNotifier` |

### New Screens (8)
| File | Route / Entry |
|------|---------------|
| `settings_screen.dart` | Profile tab → gear icon |
| `page_list_screen.dart` | Profile tab → "Pages" |
| `page_detail_screen.dart` | Page list → tap page |
| `badges_screen.dart` | Profile tab → "Badges" |
| `leaderboard_screen.dart` | Profile tab → "Classement" |
| `ride_sharing_screen.dart` | Profile tab → "Covoiturage" |
| `admin_feature_flags_screen.dart` | Profile tab → "Feature Flags" (admin only) |
| — | Explorer tab → 💡 toggle (inline sheet, no new route) |

### New Widgets (4)
| File | Description |
|------|-------------|
| `xp_level_badge.dart` | `XpLevelBadge` (full/compact), `_BadgeCircle`, `showXpSnackBar()` |
| `poll_widget.dart` | `PollWidget` — option cards + progress bars + vote button |
| `ride_card.dart` | `RideCard` — origin→destination, departure time, seats, price |
| `poll_creation_widget.dart` | `PollCreationWidget` — poll builder in post creation |

### Existing Files Updated (6)
| File | Change |
|------|--------|
| `post_model.dart` | Added `PollOptionData`, `pollOptions`, `userPollVoteIndex`, `pollTotalVotes` |
| `post_card.dart` | Added `_buildPoll()` + `_buildActions()` uses `Wrap`, XP toast on reaction |
| `post_provider.dart` | `reactToPost()`/`createPost()` return `Future<int>` (XP earned) |
| `comments_screen.dart` | XP toast after comment (+5 XP) |
| `user_profile_screen.dart` | XP card, block button, share button, gamification + block provider integration |
| `home_screen.dart` | Profile tab: `ConsumerStatefulWidget`, live stats, `XpLevelBadge`, settings icon, 6 menu tiles + check-in sheet |

### SQL Migrations (8 new)
| File | Tables Created |
|------|---------------|
| `008_polls.sql` | `poll_votes` |
| `009_blocked_users.sql` | `blocks` |
| `010_user_interests.sql` | `user_interests`, `interactions` |
| `011_pages.sql` | `pages`, `page_members` |
| `012_checkins_badges.sql` | `checkins`, `badges`, `user_badges` |
| `013_ride_shares.sql` | `ride_shares`, `ride_passengers` |
| `014_gamification.sql` | `user_levels`, `xp_transactions` + triggers |
| `015_ab_testing.sql` | `experiments`, `experiment_assignments`, `feature_config` |
| `016_user_posts_count.sql` | RPC `get_user_posts_count` |
