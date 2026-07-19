import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/post_model.dart';
import '../providers/post_provider.dart';
import '../screens/comments_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/report_screen.dart';
import '../screens/conversation_screen.dart';
import '../../core/theme/app_theme.dart';

class PostVideoPlayer extends ConsumerStatefulWidget {
  final PostModel post;
  final bool isHerzed;
  final bool isNewPost;
  final VoidCallback onToggleReaction;

  const PostVideoPlayer({
    super.key,
    required this.post,
    required this.isHerzed,
    required this.isNewPost,
    required this.onToggleReaction,
  });

  @override
  ConsumerState<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends ConsumerState<PostVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInit = false;

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
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
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
          onPressed: () =>
              ref.read(postProvider.notifier).unhidePost(widget.post.id),
        ),
      ),
    );
  }

  String _reactionCount(PostModel post, String type) {
    final count = post.reactionCounts[type] ?? 0;
    if (count > 999) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
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
            Positioned(
              top: 12, left: 12,
              child: GestureDetector(
                onTap: () => _showProfilePopup(context),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: widget.post.userAvatarUrl != null
                              ? NetworkImage(widget.post.userAvatarUrl!)
                              : null,
                          backgroundColor:
                              const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          child: widget.post.userAvatarUrl == null
                              ? Text(
                                  widget.post.userDisplayName?.isNotEmpty == true
                                      ? widget.post.userDisplayName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                        if (widget.isNewPost)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 1.5),
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
                          widget.post.userDisplayName ??
                              widget.post.userUsername ?? 'Inconnu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (widget.isNewPost)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
            Positioned(
              top: 12, right: 8,
              child: Column(
                children: [
                  _overlayIcon(Icons.favorite, widget.isHerzed,
                      widget.onToggleReaction),
                  const SizedBox(height: 4),
                  Text(
                    _reactionCount(widget.post, 'herz'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _overlayIcon(Icons.chat_bubble_outline, false, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(postId: widget.post.id),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _overlayIcon(Icons.send_outlined, false, _sharePost),
                  const SizedBox(height: 8),
                  _overlayIcon(Icons.bookmark_border, false, () {
                    widget.onToggleReaction();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Publication enregistrée'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }),
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
                  if (val == 'like') widget.onToggleReaction();
                  if (val == 'masquer') _hidePost();
                  if (val == 'signaler') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportScreen(postId: widget.post.id),
                      ),
                    );
                  }
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
                  _popupItem('Intéresser', 'like', Icons.favorite_border),
                  _popupItem('Masquer', 'masquer', Icons.visibility_off_outlined),
                  _popupItem('Signaler', 'signaler', Icons.flag_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfilePopup(BuildContext context) {
    final post = widget.post;
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
                          post.userDisplayName ?? post.userUsername ?? 'Inconnu',
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
                      _popupItem('Signaler', 'signaler', Icons.flag_outlined),
                    ],
                    onSelected: (val) {
                      Navigator.pop(ctx);
                      if (val == 'signaler') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportScreen(postId: post.id),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _sheetButton('Visiter le profil', Icons.person_outline, () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: post.userId),
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
                    child: _sheetButton('Envoyer message', Icons.message_outlined, () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await Supabase.instance.client.rpc(
                          'get_or_create_conversation',
                          params: {'other_user_id': post.userId},
                        );
                        if (mounted && result != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(
                                conversationId: result as String,
                                otherUserId: post.userId,
                                otherUserName: post.userDisplayName ?? post.userUsername ?? 'Utilisateur',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _sheetButton('Emplacement', Icons.location_on_outlined, () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: post.userId),
                        ),
                      );
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

  PopupMenuItem<String> _popupItem(String label, String value, IconData icon, {Color? color}) {
    return PopupMenuItem(
      value: value,
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
