import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/post_model.dart';
import '../../data/models/poll_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sticker_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/post_provider.dart';
import '../providers/follow_provider.dart';
import '../providers/poll_provider.dart';
import '../screens/comments_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/edit_post_screen.dart';
import '../screens/user_profile_screen.dart';
import 'poll_widget.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _openProfile(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.post.userId)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final post = widget.post;
    final user = Supabase.instance.client.auth.currentUser;
    final isOwnPost = user != null && user.id == post.userId;
    final followState = ref.watch(followProvider(post.userId));

    return GestureDetector(
      onTapDown: (_) => _animCtrl.forward(),
      onTapUp: (_) => _animCtrl.reverse(),
      onTapCancel: () => _animCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: t.isDark ? AppTheme.cardDark : AppTheme.cardGlassLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000)),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: t.isDark ? 0.06 : 0.08), blurRadius: 24, offset: const Offset(0, 6)),
              BoxShadow(color: Colors.black.withValues(alpha: t.isDark ? 0.08 : 0.03), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, t, post, isOwnPost),
                const SizedBox(height: 12),
                _buildContent(context, t, post),
                if (post.mediaUrls.isNotEmpty) ...[const SizedBox(height: 12), _buildMedia(context, post)],
                if (post.pollOptions != null && post.pollOptions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPoll(context, post),
                ],
                const SizedBox(height: 14),
                _buildActions(context, t, post, isOwnPost, followState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData t, PostModel post, bool isOwnPost) {
    return InkWell(
      onTap: () => _openProfile(context),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: post.userAvatarUrl == null ? AppTheme.brandGradient : null,
            ),
            child: post.userAvatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(post.userAvatarUrl!, fit: BoxFit.cover, width: 44, height: 44,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 22)),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.userDisplayName ?? post.userUsername ?? 'Anonyme',
                  style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (post.contextTag != null)
                  Text(post.contextTag!, style: t.textTheme.bodySmall?.copyWith(color: AppTheme.accent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me, size: 10, color: AppTheme.primary),
                    const SizedBox(width: 3),
                    Text(_formatDistance(post.distanceMeters),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              if (post.createdAt != null)
                Text(_formatTime(post.createdAt!), style: t.textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (val) async {
              switch (val) {
                case 'edit':
                  final r = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => EditPostScreen(postId: post.id, currentContent: post.content)));
                  if (r == true) ref.read(postProvider.notifier).loadFeed();
                case 'delete':
                  final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                    title: const Text('Supprimer'),
                    content: const Text('Voulez-vous vraiment supprimer cette publication ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
                    ],
                  ));
                  if (ok == true) ref.read(postProvider.notifier).deletePost(post.id);
              }
            },
            itemBuilder: isOwnPost
                ? (_) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
                  ]
                : (_) => [
                    const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 18), SizedBox(width: 8), Text('Signaler')])),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData t, PostModel post) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
      borderRadius: BorderRadius.circular(12),
      child: Text(post.content, style: t.textTheme.bodyMedium?.copyWith(height: 1.6)),
    );
  }

  Widget _buildMedia(BuildContext context, PostModel post) {
    // Sticker display
    if (post.stickerId != null) {
      final sticker = AppStickers.getStickerById(post.stickerId!);
      if (sticker != null) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(sticker.emoji, style: const TextStyle(fontSize: 64)),
          ),
        );
      }
    }

    // Video display
    if (post.mediaType == MediaType.video && post.mediaUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _VideoPlayerWidget(url: post.mediaUrls.first),
      );
    }

    // Image display
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: PageView.builder(
          itemCount: post.mediaUrls.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
            child: Image.network(post.mediaUrls[i], fit: BoxFit.cover, width: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 40)))),
          ),
        ),
      ),
    );
  }

  Widget _buildPoll(BuildContext context, PostModel post) {
    final pollModel = PollModel(
      options: (post.pollOptions ?? []).map((o) => PollOptionItem(text: o.text, votes: o.votes, percentage: 0)).toList(),
      totalVotes: post.pollTotalVotes ?? 0,
      userVoteIndex: post.userPollVoteIndex,
    );
    final pollState = ref.watch(pollProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.poll_rounded, size: 18, color: AppTheme.primary),
              SizedBox(width: 6),
              Text('Sondage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          PollWidget(
            poll: pollModel,
            onVote: (idx) async {
              await ref.read(pollProvider.notifier).vote(post.id, idx);
              ref.read(postProvider.notifier).loadFeed();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData t, PostModel post, bool isOwnPost, FollowState followState) {
    final user = Supabase.instance.client.auth.currentUser;
    const reactions = AppConstants.reactions;
    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        ...reactions.map((reaction) {
          final count = post.reactionCounts[reaction] ?? 0;
          return _ReactionChip(
            emoji: reaction, count: count,
            onTap: () async {
              final xp = await ref.read(postProvider.notifier).reactToPost(post.id, reaction);
              if (xp > 0 && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.stars, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Text('+$xp XP', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1, milliseconds: 500),
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
          );
        }),
        _ActionChip(
          icon: Icons.chat_bubble_outline, count: post.commentCount,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(postId: post.id))),
        ),
        if (!isOwnPost)
          IconButton(
            icon: Icon(followState.isFollowing ? Icons.favorite : Icons.favorite_border, size: 20,
              color: followState.isFollowing ? Colors.red : t.colorScheme.onSurfaceVariant),
            onPressed: followState.isLoading ? null : () {
              if (user == null) return;
              if (followState.isFollowing) {
                ref.read(followProvider(post.userId).notifier).unfollow();
              } else {
                ref.read(followProvider(post.userId).notifier).follow();
              }
            },
            style: IconButton.styleFrom(backgroundColor: followState.isFollowing ? Colors.red.withValues(alpha: 0.1) : null),
          ),
        IconButton(
          icon: const Icon(Icons.ios_share, size: 20),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '${post.userDisplayName ?? 'Quelqu\'un'} a partagÃ© prÃ¨s de vous: ${post.content}'));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lien copiÃ©'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
          },
          style: IconButton.styleFrom(foregroundColor: t.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final VoidCallback onTap;
  const _ReactionChip({required this.emoji, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: t.isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: t.isDark ? const Color(0x0AFFFFFF) : const Color(0x0A000000)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            if (count > 0) const SizedBox(width: 3),
            if (count > 0) Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: t.isDark ? const Color(0x1AFFFFFF) : const Color(0x0A000000),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: t.isDark ? const Color(0x0AFFFFFF) : const Color(0x0A000000)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: t.colorScheme.onSurfaceVariant),
            if (count > 0) const SizedBox(width: 3),
            if (count > 0) Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,
        showControls: true,
        placeholder: Container(color: Colors.black12),
        errorBuilder: (_, msg) => Center(
          child: Text(msg, style: const TextStyle(color: Colors.white)),
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 220,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }
    if (_error != null || _chewieController == null) {
      return Container(
        height: 220,
        color: Colors.black12,
        child: const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 40)),
      );
    }
    return AspectRatio(
      aspectRatio: _videoController.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }
}
