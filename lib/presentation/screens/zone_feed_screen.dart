import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/firebase_uuid.dart';
import '../../data/models/zone_model.dart';
import '../providers/post_provider.dart';
import '../providers/zone_provider.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

extension _ThemeDark on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}

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
      ref.read(postProvider.notifier).loadZonePosts(widget.zone.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final postState = ref.watch(postProvider);
    // FIX: FirebaseAuth + UUID
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final currentUid = firebaseUid != null ? FirebaseUuid.toUuid(firebaseUid) : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.zone.emoji,
              style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(widget.zone.zoneName),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _heatColor(widget.zone.heatScore).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department,
                  size: 14,
                  color: _heatColor(widget.zone.heatScore)),
                const SizedBox(width: 4),
                Text(
                  widget.zone.heatLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _heatColor(widget.zone.heatScore),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(postProvider.notifier).loadZonePosts(widget.zone.id),
        child: postState.isLoading && postState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : postState.posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.zone.emoji,
                          style: const TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune publication dans cette zone',
                          style: t.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Soyez le premier à publier !',
                          style: t.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: postState.posts.length,
                    itemBuilder: (_, i) {
                      final post = postState.posts[i];
                      return PostCard(
                        post: post,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePostScreen(zoneId: widget.zone.id),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Publier ici'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _heatColor(double score) {
    if (score >= 80) return Colors.red;
    if (score >= 50) return Colors.orange;
    if (score >= 20) return Colors.amber;
    return Colors.blue;
  }
}
