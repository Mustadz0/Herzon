import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../core/constants/sticker_constants.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/comments_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/report_screen.dart';
import '../screens/edit_post_screen.dart';
import '../screens/conversation_screen.dart';
import '../../core/theme/app_theme.dart';
import 'post_video_player.dart';
import 'post_photo_view.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final bool isExplorerMode;
  const PostCard({super.key, required this.post, this.isExplorerMode = false});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  OverlayEntry? _vignetteOverlay;

  @override
  void dispose() {
    _removeVignette();
    super.dispose();
  }

  bool get _isNewPost {
    final createdAt = widget.post.createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(createdAt);
    return diff.inMinutes < 5;
  }

  void _sharePost() {
    final post = widget.post;
    final shareText =
        '${post.userDisplayName ?? post.userUsername ?? "Quelqu\'un"} a partagé sur Herzon:\n${post.content}\nhttps://herzon.app/post/${post.id}';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien copié !'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _hidePost() {
    ref.read(postProvider.notifier).hidePost(widget.post.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Publication masquée'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () => ref.read(postProvider.notifier).unhidePost(widget.post.id),
        ),
      ),
    );
  }

  void _showVignette(String imageUrl) {
    _removeVignette();
    _vignetteOverlay = OverlayEntry(
      builder: (_) => _VignettePopup(
        imageUrl: imageUrl,
        onClose: _removeVignette,
      ),
    );
    Overlay.of(context).insert(_vignetteOverlay!);
  }

  void _removeVignette() {
    _vignetteOverlay?.remove();
    _vignetteOverlay = null;
  }

  void _toggleReaction(String type) async {
    final notifier = ref.read(postProvider.notifier);
    final feed = ref.read(postProvider);
    final isActive = feed.userReactions[widget.post.id]?.contains(type) ?? false;
    if (isActive) {
      await notifier.removeReaction(widget.post.id, type);
    } else {
      await notifier.reactToPost(widget.post.id, type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnPost = currentUserId != null && post.userId == currentUserId;
    final feed = ref.watch(postProvider);
    final userReactions = feed.userReactions;
    final isHerzed = userReactions[post.id]?.contains('herz') ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isNewPost
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaSection(post, isHerzed),
          if (!widget.isExplorerMode)
            _buildActionRow(post, isOwnPost, isHerzed),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: post.content,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (post.content.length > 80)
                      TextSpan(
                        text: ' ...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(PostModel post, bool isHerzed) {
    if (post.mediaType == MediaType.video && post.mediaUrls.isNotEmpty) {
      return PostVideoPlayer(
        post: post,
        isHerzed: isHerzed,
        isNewPost: _isNewPost,
        onToggleReaction: () => _toggleReaction('herz'),
      );
    } else if (post.mediaUrls.isNotEmpty) {
      return PostPhotoView(post: post);
    } else if (post.stickerId != null) {
      return _buildStickerCard(post);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStickerCard(PostModel post) {
    final sticker = AppStickers.getStickerById(post.stickerId!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      color: Colors.grey[900],
      child: Center(
        child: Text(sticker?.emoji ?? '😀',
            style: const TextStyle(fontSize: 64)),
      ),
    );
  }

  Widget _buildActionRow(PostModel post, bool isOwnPost, bool isHerzed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          if (post.mediaType != MediaType.video)
            _HerzButton(
              isHerzed: isHerzed,
              count: _reactionCount(post, 'herz'),
              onTap: () => _toggleReaction('herz'),
            ),
          if (post.mediaType != MediaType.video)
            const SizedBox(width: 12),
          _actionIcon(Icons.chat_bubble_outline, post.commentCount.toString(), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommentsScreen(postId: post.id),
              ),
            );
          }),
          const SizedBox(width: 16),
          _actionIcon(Icons.send_outlined, 'Partager', _sharePost),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') _confirmDelete(context);
              else if (val == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPostScreen(
                      postId: post.id,
                      currentContent: post.content,
                    ),
                  ),
                ).then((updated) {
                  if (updated == true) ref.read(postProvider.notifier).loadFeed();
                });
              } else if (val == 'signaler') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReportScreen(postId: post.id)),
                );
              } else if (val == 'masquer') _hidePost();
              else if (val == 'interesser') _toggleReaction('herz');
            },
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.6), size: 20),
            itemBuilder: (_) => [
              _popupItem('Intéresser', 'interesser', Icons.favorite_border),
              _popupItem('Masquer', 'masquer', Icons.visibility_off_outlined),
              _popupItem('Signaler', 'signaler', Icons.flag_outlined),
              if (isOwnPost) ...[
                const PopupMenuDivider(),
                _popupItem('Modifier', 'edit', Icons.edit_outlined),
                _popupItem('Supprimer', 'delete', Icons.delete_outline, color: Colors.red),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Cette action est irréversible. Confirmer la suppression ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        ref.read(postProvider.notifier).deletePost(widget.post.id);
      }
    });
  }

  String _reactionCount(PostModel post, String type) {
    final count = post.reactionCounts[type] ?? 0;
    if (count > 999) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Widget _actionIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String label, String value, IconData icon, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color ?? Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        ],
      ),
    );
  }
}

class _HerzButton extends StatelessWidget {
  final bool isHerzed;
  final String count;
  final VoidCallback onTap;

  const _HerzButton({
    required this.isHerzed,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isHerzed
              ? AppTheme.primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHerzed
                ? AppTheme.primary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHerzed ? Icons.favorite : Icons.favorite_border,
              color: isHerzed ? AppTheme.primary : Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
            const SizedBox(width: 5),
            Text(
              count,
              style: TextStyle(
                color: isHerzed ? AppTheme.primary : Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VignettePopup extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const _VignettePopup({required this.imageUrl, required this.onClose});

  @override
  State<_VignettePopup> createState() => _VignettePopupState();
}

class _VignettePopupState extends State<_VignettePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _ctrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _close,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            color: Colors.black.withValues(alpha: 0.92),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: () {},
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width,
                          maxHeight: MediaQuery.of(context).size.height * 0.82,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200, height: 200,
                              color: Colors.grey[900],
                              child: const Icon(Icons.broken_image, color: Colors.white24, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
