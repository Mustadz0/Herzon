import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/story_provider.dart';
import '../providers/follow_provider.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'comments_screen.dart';
import 'user_profile_screen.dart';
import 'story_viewer_screen.dart';
import 'create_story_screen.dart';

extension _ThemeDark on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(postProvider.notifier).loadFeed();
      ref.read(storyProvider.notifier).loadStories();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final postState = ref.watch(postProvider);
    final storyState = ref.watch(storyProvider);
    // FIX: FirebaseAuth بدل Supabase.auth
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(postProvider.notifier).loadFeed();
        await ref.read(storyProvider.notifier).loadStories();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Stories Row
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: storyState.stories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AddStoryButton(onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
                    ));
                  }
                  final story = storyState.stories[index - 1];
                  return _StoryAvatar(
                    story: story,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StoryViewerScreen(story: story)),
                    ),
                  );
                },
              ),
            ),
          ),

          // Posts
          if (postState.isLoading && postState.posts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (postState.error != null && postState.posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: t.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Impossible de charger le fil', style: t.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => ref.read(postProvider.notifier).loadFeed(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (postState.posts.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.near_me_disabled, size: 48, color: t.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('Aucune publication à proximité', style: t.textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text('Soyez le premier à publier !', style: t.textTheme.bodySmall),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = postState.posts[index];
                  return _PostCard(
                    post: post,
                    currentUid: currentUid,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
                    ),
                    onComment: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CommentsScreen(postId: post.id)),
                    ),
                    onReact: (reaction) =>
                        ref.read(postProvider.notifier).reactToPost(post.id, reaction),
                    onDelete: (currentUid != null &&
                            (post.userId == currentUid ||
                                post.userId.contains(currentUid.substring(0, 8))))
                        ? () => ref.read(postProvider.notifier).deletePost(post.id)
                        : null,
                    onProfile: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.userId)),
                    ),
                  );
                },
                childCount: postState.posts.length,
              ),
            ),

          // FAB space
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ─── Add Story Button ──────────────────────────────────────────────────────────
class _AddStoryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: t.colorScheme.outlineVariant,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.add, size: 24),
            ),
            const SizedBox(height: 4),
            Text('Story', style: t.textTheme.bodySmall?.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Story Avatar ──────────────────────────────────────────────────────────────
class _StoryAvatar extends StatelessWidget {
  final dynamic story;
  final VoidCallback onTap;
  const _StoryAvatar({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.brandGradient,
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.scaffoldBackgroundColor,
                ),
                padding: const EdgeInsets.all(2),
                child: story.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(story.avatarUrl!, fit: BoxFit.cover,
                          width: 48, height: 48),
                      )
                    : const Icon(Icons.person, size: 24),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story.username ?? 'User',
              style: t.textTheme.bodySmall?.copyWith(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Post Card ─────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final PostModel post;
  final String? currentUid;
  final VoidCallback onTap;
  final VoidCallback onComment;
  final VoidCallback? onDelete;
  final VoidCallback onProfile;
  final void Function(String reaction) onReact;

  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.onTap,
    required this.onComment,
    required this.onReact,
    this.onDelete,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onProfile,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: post.userAvatarUrl == null ? AppTheme.brandGradient : null,
                      ),
                      child: post.userAvatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(post.userAvatarUrl!, fit: BoxFit.cover))
                          : const Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userDisplayName ?? post.userUsername ?? 'Anonyme',
                          style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Row(
                          children: [
                            if (post.createdAt != null)
                              Text(_formatTime(post.createdAt!),
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: t.colorScheme.onSurfaceVariant, fontSize: 11)),
                            if (post.distanceMeters > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 3, height: 3,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: t.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.near_me, size: 11, color: AppTheme.primary),
                              const SizedBox(width: 2),
                              Text(_formatDistance(post.distanceMeters),
                                style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (post.contextTag != null)
                    Chip(
                      label: Text(post.contextTag!, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 18),
                      onPressed: () => _showMenu(context),
                    ),
                ],
              ),
            ),

            // Content
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text(
                  post.content,
                  style: t.textTheme.bodyMedium?.copyWith(height: 1.5),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Media
            if (post.mediaUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: Image.network(
                    post.mediaUrls.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  ...AppConstants.reactions.take(4).map((r) {
                    final count = post.reactionCounts[r] ?? 0;
                    return InkWell(
                      onTap: () => onReact(r),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(r, style: const TextStyle(fontSize: 16)),
                            if (count > 0) ...[
                              const SizedBox(width: 2),
                              Text('$count', style: t.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600, fontSize: 11)),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  InkWell(
                    onTap: onComment,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16,
                            color: t.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${post.commentCount ?? 0}',
                            style: t.textTheme.bodySmall?.copyWith(
                              color: t.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
