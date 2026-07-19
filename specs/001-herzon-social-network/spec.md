# Feature Specification: Herzon — Proximity Social Network

**Feature Branch**: `001-herzon-social-network`
**Created**: 2026-07-15
**Status**: Implementation Phase (v1.1.0+2)

## User Scenarios & Testing

### User Story 1 — Google Sign-In & Profile (Priority: P1)
User opens the app, signs in with Google, and their profile is auto-created.

**Acceptance Scenarios**:
1. **Given** fresh install, **When** user taps "Continuer avec Google", **Then** native Google account picker opens.
2. **Given** user selects account, **When** sign-in succeeds, **Then** user lands on Home screen.
3. **Given** existing user, **When** they reopen the app, **Then** they see Home screen immediately (no login).

### User Story 2 — Proximity Feed (Priority: P1)
User sees posts from people near them, sorted by relevance/distance.

**Acceptance Scenarios**:
1. **Given** user on feed, **When** scrolling, **Then** posts within proximity radius (configurable) appear.
2. **Given** a post with media, **When** user taps it, **Then** media viewer opens.
3. **Given** stale content, **When** user pulls to refresh, **Then** new posts load.

### User Story 3 — Create Post (Priority: P1)
User creates a text/image post with their current location.

**Acceptance Scenarios**:
1. **Given** user taps create, **When** they type + optionally attach image, **Then** post appears in feed.
2. **Given** post with image, **When** uploaded, **Then** image displays in post card.
3. **Given** user without location, **When** they try to post, **Then** location permission prompt appears.

### User Story 4 — Real-time Messaging (Priority: P2)
User can send and receive direct messages in real-time.

**Acceptance Scenarios**:
1. **Given** user A opens conversation with user B, **When** A sends message, **Then** B receives it instantly.
2. **Given** unread messages, **When** user opens app, **Then** badge count shows on messages tab.
3. **Given** user is offline, **When** message is sent, **Then** it arrives when user comes online.

### User Story 5 — Stories (Priority: P2)
User can post ephemeral stories visible to nearby users for 24h.

**Acceptance Scenarios**:
1. **Given** user captures photo story, **When** posted, **Then** it appears in stories tray for 24h.
2. **Given** expired story, **When** 24h passes, **Then** story auto-deletes.

### User Story 6 — Ride Sharing (Priority: P3)
User can find nearby ride offers/requests.

**Acceptance Scenarios**:
1. **Given** user needs a ride, **When** they post a request, **Then** nearby drivers see it.
2. **Given** driver offers ride, **When** passenger accepts, **Then** contact info is shared.

### User Story 7 — Marketplace (Priority: P3)
User can buy/sell items with nearby users.

**Acceptance Scenarios**:
1. **Given** user lists an item, **When** they post with photo + price, **Then** it appears in marketplace feed.
2. **Given** buyer is interested, **When** they contact seller, **Then** chat opens.

### User Story 8 — Admin Dashboard (Priority: P3)
Admin can moderate content and view analytics.

**Acceptance Scenarios**:
1. **Given** admin user, **When** they navigate to admin panel, **Then** they see stats (users/posts/reports).
2. **Given** flagged post, **When** admin deletes it, **Then** post is removed from all feeds.

## Requirements

### Functional Requirements
- **FR-001**: System MUST authenticate users via Google Sign-In (native Android SDK).
- **FR-002**: System MUST determine user location via GPS on every content interaction.
- **FR-003**: System MUST store posts with PostGIS geography points for proximity queries.
- **FR-004**: System MUST show posts within a configurable proximity radius (default 500m, per `AppConstants.proximityRadiusMeters`).
- **FR-005**: System MUST support media uploads (images) to Supabase Storage.
- **FR-006**: System MUST deliver messages in real-time via Supabase Realtime.
- **FR-007**: System MUST support stories with 24h auto-expiry.
- **FR-008**: System MUST support anonymous browsing + sign-in.
- **FR-009**: System MUST have admin moderation tools (delete posts, manage reports).
- **FR-010**: System MUST track crashes via Firebase Crashlytics.
- **FR-011**: System MUST verify app integrity via Firebase App Check.
- **FR-012**: System MUST support push notifications via Firebase Cloud Messaging.

### Key Entities
- **User (profiles)**: id, username, display_name, bio, avatar_url, is_admin, privacy_settings, location, last_active_at
- **Post (posts)**: id, user_id, content, media_urls, media_type, location (PostGIS POINT), zone_id, context_tag, reaction_counts, created_at
- **Story (stories)**: id, user_id, media_url, media_type, expires_at, created_at
- **Message (messages)**: id, conversation_id, sender_id, content, media_url, created_at, read
- **Conversation (conversations)**: id, participant_ids, last_message, last_message_at
- **Ride (ride_shares)**: id, user_id, type (offer/request), from_location, to_location, seats, price, status
- **MarketplaceItem (marketplace_items)**: id, user_id, title, description, price, currency, category, images, location, status
- **Report (reports)**: id, reporter_id, reported_user_id, post_id, reason, status, created_at
- **CheckIn (check_ins)**: id, user_id, location, zone, created_at
- **DeviceToken (device_tokens)**: id, user_id, fcm_token, platform
- **FeatureFlag (feature_flags)**: id, key, value, enabled
- **UserExperiment (user_experiments)**: id, user_id, experiment_id, variant

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                      │
│  ┌─────────────────────────────────────────────────────┐│
│  │  Screens (Login, Home, Feed, Explorer, Admin...)    ││
│  │  Widgets (PostCard, XPBadge, ConversationList...)   ││
│  └──────────────────────┬──────────────────────────────┘│
│                         │ ref.watch()                    │
│  ┌──────────────────────▼──────────────────────────────┐│
│  │  Providers (Riverpod StateNotifier)                  ││
│  │  Auth | Post | Story | Message | Ride | Admin...    ││
│  └──────────────────────┬──────────────────────────────┘│
├─────────────────────────┼───────────────────────────────┤
│                   Data Layer                             │
│  ┌──────────────────────▼──────────────────────────────┐│
│  │  Repositories (Supabase queries + RPC calls)         ││
│  │  Auth | Post | Follow | Ride | Story | Gamification ││
│  └──────────────────────┬──────────────────────────────┘│
│                         │                                │
│  ┌──────────────────────▼──────────────────────────────┐│
│  │  Supabase (PostgreSQL + PostGIS + Realtime)          ││
│  │  Firebase (Crashlytics + Messaging + AppCheck)      ││
│  │  Hive (Local cache)                                  ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

## Success Criteria
- **SC-001**: User can sign in with Google in < 5 seconds on a standard connection.
- **SC-002**: Feed loads 20 posts within 2 seconds of opening.
- **SC-003**: Message delivery latency < 500ms (same session).
- **SC-004**: APK size < 40MB.
- **SC-005**: Crash-free session rate > 99.5%.

## Assumptions
- Users have stable internet connectivity (Algeria 4G/WiFi).
- GPS location is available (users have granted location permission).
- Google Play Services are installed on all target devices.
- App is distributed as signed APK (not Play Store) for initial launch.
