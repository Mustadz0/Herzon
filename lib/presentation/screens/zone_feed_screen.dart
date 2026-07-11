import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:herzon/core/theme/app_theme.dart';
import '../../data/models/zone_model.dart';
import '../../data/models/zone_post_model.dart';
import '../providers/zone_feed_provider.dart';

/// Read-only zone feed screen.
/// No posting, reactions, or comments — Explorer = passive mode (CLAUDE.md §Two Modes).
class ZoneFeedScreen extends ConsumerStatefulWidget {
  final ZoneModel zone;
  final double userLat;
  final double userLng;

  const ZoneFeedScreen({
    super.key,
    required this.zone,
    required this.userLat,
    required this.userLng,
  });

  @override
  ConsumerState<ZoneFeedScreen> createState() => _ZoneFeedScreenState();
}

class _ZoneFeedScreenState extends ConsumerState<ZoneFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(zoneFeedProvider(widget.zone.zoneKey).notifier).load(
            zoneKey: widget.zone.zoneKey,
            lat: widget.userLat,
            lng: widget.userLng,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zoneFeedProvider(widget.zone.zoneKey));
    final t     = Theme.of(context);
    final cs    = t.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.zone.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              widget.zone.zoneName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          // Read-only badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Lecture seule',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // No FAB — read-only
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(zoneFeedProvider(widget.zone.zoneKey).notifier).load(
                  zoneKey: widget.zone.zoneKey,
                  lat: widget.userLat,
                  lng: widget.userLng,
                ),
        child: _buildBody(state, t, cs),
      ),
    );
  }

  Widget _buildBody(
      ZoneFeedState state, ThemeData t, ColorScheme cs) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(zoneFeedProvider(widget.zone.zoneKey).notifier).load(
                          zoneKey: widget.zone.zoneKey,
                          lat: widget.userLat,
                          lng: widget.userLng,
                        ),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.zone.emoji,
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune activité récente\ndans cette zone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.posts.length,
      itemBuilder: (_, i) => _ZonePostCard(post: state.posts[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// _ZonePostCard — read-only card (no reaction/comment buttons)
// ─────────────────────────────────────────────────────────────────────────
class _ZonePostCard extends StatelessWidget {
  final ZonePostModel post;
  const _ZonePostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final t  = Theme.of(context);
    final cs = t.colorScheme;
    final tt = t.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author row ──────────────────────────────────────────
          Row(
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.brandGradient,
                ),
                child: post.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: CachedNetworkImage(
                          imageUrl: post.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.person,
                        size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.displayName,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDistance(post.distanceMeters),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Timestamp
              Text(
                _formatTime(post.createdAt),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),

          // ── Content ─────────────────────────────────────────────
          if (post.content != null && post.content!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(post.content!, style: tt.bodyMedium),
          ],

          // ── Media ───────────────────────────────────────────────
          if (post.mediaUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: post.mediaUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ],

          // ── Stats row (read-only counters, no tap) ──────────────
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.local_fire_department_outlined,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${post.reactionsCount}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${post.commentsCount}',
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Read-only lock icon
              Icon(Icons.lock_outline_rounded,
                  size: 14, color: cs.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}
