import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/post_model.dart';
import '../../core/constants/sticker_constants.dart';
import '../providers/post_provider.dart';
import '../screens/comments_screen.dart';
import '../screens/user_profile_screen.dart';

class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  const PostCard({super.key, required this.post});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInit = false;

  // ── Vignette state ──────────────────────────
  OverlayEntry? _vignetteOverlay;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    final mediaUrls = widget.post.mediaUrls;
    if (widget.post.mediaType == MediaType.video &&
        mediaUrls.isNotEmpty &&
        !_isVideoInit) {
      _isVideoInit = true;
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(mediaUrls.first));
      _videoController!.initialize().then((_) {
        if (mounted) {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: false,
            looping: true,
            aspectRatio: 16 / 9,
            showControls: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: const Color(0xFF4F46E5),
              handleColor: const Color(0xFF4F46E5),
              backgroundColor: Colors.white24,
              bufferedColor: Colors.white12,
            ),
          );
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _removeVignette();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Vignette popup ───────────────────────────
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

  // ── Is New (< 5 min) ────────────────────────
  bool get _isNewPost {
    final createdAt = widget.post.createdAt ?? DateTime.now();
    final diff = DateTime.now().difference(createdAt);
    return diff.inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final user = Supabase.instance.client.auth.currentUser;
    final isOwnPost = user != null && post.userId == user.id;
    final feed = ref.watch(postProvider);
    final userReactions = feed.userReactions;
    final isHerzed = userReactions[post.id]?.contains('herz') ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        // Glow subtil si nouveau post
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
          // Media section
          _buildMediaSection(post, isOwnPost, isHerzed),

          // Action row outside media
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                _actionIcon(Icons.chat_bubble_outline, post.commentCount.toString(), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(postId: post.id),
                    ),
                  );
                }),
                const SizedBox(width: 16),
                _actionIcon(Icons.send_outlined, 'Partager', () {}),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (val) {},
                  color: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  itemBuilder: (_) => [
                    _popupItem('Interesser', Icons.favorite_border),
                    _popupItem('Masquer', Icons.visibility_off_outlined),
                    _popupItem('Signaler', Icons.flag_outlined),
                    if (isOwnPost) ...[
                      const PopupMenuDivider(),
                      _popupItem('Supprimer', Icons.delete_outline,
                          color: Colors.red),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Description
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

  Widget _buildMediaSection(
      PostModel post, bool isOwnPost, bool isHerzed) {
    if (post.mediaType == MediaType.video && post.mediaUrls.isNotEmpty) {
      return _buildVideoCard(post, isHerzed);
    } else if (post.mediaUrls.isNotEmpty) {
      return _buildPhotoMosaic(post);
    } else if (post.stickerId != null) {
      return _buildStickerCard(post);
    } else {
      return const SizedBox.shrink();
    }
  }

  // ── Video card ───────────────────────────────
  Widget _buildVideoCard(PostModel post, bool isHerzed) {
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            _chewieController != null &&
                    _chewieController!
                        .videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),

            // Dark gradient top
            Positioned(
              top: 0, left: 0, right: 0,
              height: 120,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Profile at top-left
            Positioned(
              top: 12, left: 12,
              child: GestureDetector(
                onTap: () => _showProfilePopup(post),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: post.userAvatarUrl != null
                              ? NetworkImage(post.userAvatarUrl!)
                              : null,
                          backgroundColor:
                              const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          child: post.userAvatarUrl == null
                              ? Text(
                                  post.userDisplayName?.isNotEmpty == true
                                      ? post.userDisplayName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        // 🟢 Nqta khadra — seulement si < 5 min
                        if (_isNewPost)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userDisplayName ??
                              post.userUsername ??
                              'Inconnu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (_isNewPost)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Nouveau',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Text(
                              'La Zone',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions at top-right
            Positioned(
              top: 12, right: 8,
              child: Column(
                children: [
                  _overlayIcon(Icons.favorite, isHerzed,
                      () => _toggleReaction('herz')),
                  const SizedBox(height: 4),
                  Text(
                    getReactionCount(post, 'herz'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _overlayIcon(Icons.send_outlined, false, () {}),
                  const SizedBox(height: 8),
                  _overlayIcon(Icons.bookmark_border, false, () {}),
                  const SizedBox(height: 12),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.music_note,
                        color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 12, right: 8,
              child: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'like') _toggleReaction('herz');
                },
                color: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                itemBuilder: (_) => [
                  _popupItem('Interesser', Icons.favorite_border),
                  _popupItem('Masquer', Icons.visibility_off_outlined),
                  _popupItem('Signaler', Icons.flag_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo mosaic ────────────────────────────
  Widget _buildPhotoMosaic(PostModel post) {
    final urls = post.mediaUrls;
    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _showVignette(urls[0]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            urls[0],
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            errorBuilder: (_, __, ___) => Container(
              height: 300,
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white24),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showVignette(urls[0]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  urls[0],
                  fit: BoxFit.cover,
                  height: 300,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: urls.length > 1
                        ? () => _showVignette(urls[1])
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        urls.length > 1 ? urls[1] : '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey[900]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: urls.length > 2
                        ? () => _showVignette(urls[2])
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: urls.length > 2
                          ? Image.network(
                              urls[2],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[900]),
                            )
                          : Container(color: Colors.grey[900]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  void _showProfilePopup(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: post.userAvatarUrl != null
                        ? NetworkImage(post.userAvatarUrl!)
                        : null,
                    backgroundColor:
                        const Color(0xFF4F46E5).withValues(alpha: 0.3),
                    child: post.userAvatarUrl == null
                        ? Text(
                            post.userDisplayName?.isNotEmpty == true
                                ? post.userDisplayName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userDisplayName ??
                              post.userUsername ??
                              'Inconnu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.near_me,
                                color: Color(0xFF4F46E5), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'La Zone',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    itemBuilder: (_) => [
                      _popupItem('Ajouter a la zone', Icons.add_circle_outline),
                      _popupItem('Rejoindre sa zone', Icons.group_add_outlined),
                    ],
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _sheetButton('Visiter le profil', Icons.person_outline,
                        () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: post.userId),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _sheetButton(
                        'Envoyer message', Icons.message_outlined, () {
                      Navigator.pop(ctx);
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _sheetButton(
                        'Emplacement', Icons.location_on_outlined, () {
                      Navigator.pop(ctx);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _toggleReaction(String type) async {
    final notifier = ref.read(postProvider.notifier);
    final feed = ref.read(postProvider);
    final isActive =
        feed.userReactions[widget.post.id]?.contains(type) ?? false;
    if (isActive) {
      await notifier.removeReaction(widget.post.id, type);
    } else {
      await notifier.reactToPost(widget.post.id, type);
    }
  }

  String getReactionCount(PostModel post, String type) {
    final count = post.reactionCounts[type] ?? 0;
    if (count > 999) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Widget _overlayIcon(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF4F46E5).withValues(alpha: 0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active
              ? const Color(0xFF4F46E5)
              : Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
      ),
    );
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

  PopupMenuItem<String> _popupItem(String label, IconData icon,
      {Color? color}) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetButton(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vignette Popup — Overlay plein écran avec zoom + effet vignette
// ─────────────────────────────────────────────────────────────────────────────
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
                // Vignette radiale sombre sur les bords
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

                // Image zoomable
                ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: () {}, // empêche fermeture sur l'image
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
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white24,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bouton fermer
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
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
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
