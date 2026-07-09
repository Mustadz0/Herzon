import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/comment_repository.dart';
import '../providers/post_provider.dart';
import '../providers/follow_provider.dart';
import 'user_profile_screen.dart';

final _detailCommentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(commentRepositoryProvider).getComments(postId);
});

class PostDetailScreen extends ConsumerStatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await ref.read(commentRepositoryProvider).addComment(widget.post.id, user.id, content);
      _commentController.clear();
      ref.invalidate(_detailCommentsProvider(widget.post.id));
      ref.read(postProvider.notifier).loadFeed();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final post = widget.post;
    final user = Supabase.instance.client.auth.currentUser;
    final isOwnPost = user != null && user.id == post.userId;
    final followState = ref.watch(followProvider(post.userId));
    final commentsAsync = ref.watch(_detailCommentsProvider(post.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Publication')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.mediaUrls.isNotEmpty)
                    SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: post.mediaUrls.length,
                        itemBuilder: (_, i) => Image.network(post.mediaUrls[i], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 40)))),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.userId))),
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
                                    ? ClipRRect(borderRadius: BorderRadius.circular(22),
                                        child: Image.network(post.userAvatarUrl!, fit: BoxFit.cover))
                                    : const Icon(Icons.person, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.userDisplayName ?? post.userUsername ?? 'Anonyme',
                                      style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                    if (post.createdAt != null)
                                      Text(_formatTime(post.createdAt!), style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              if (post.contextTag != null)
                                Chip(label: Text(post.contextTag!, style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(post.content, style: t.textTheme.bodyLarge?.copyWith(height: 1.6)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me, size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text(_formatDistance(post.distanceMeters),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: '${post.userDisplayName ?? "Quelqu'un"} a partage: ${post.content}'));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Copié !'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
                              },
                              icon: const Icon(Icons.ios_share, size: 16),
                              label: const Text('Partager'),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ...AppConstants.reactions.map((reaction) {
                              final count = post.reactionCounts[reaction] ?? 0;
                              return InkWell(
                                onTap: () => ref.read(postProvider.notifier).reactToPost(post.id, reaction),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(reaction, style: const TextStyle(fontSize: 24)),
                                      if (count > 0)
                                        Text('$count', style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!isOwnPost)
                          Center(
                            child: TextButton.icon(
                              onPressed: followState.isLoading ? null : () {
                                if (followState.isFollowing) {
                                  ref.read(followProvider(post.userId).notifier).unfollow();
                                } else {
                                  ref.read(followProvider(post.userId).notifier).follow();
                                }
                              },
                              icon: Icon(followState.isFollowing ? Icons.favorite : Icons.person_add,
                                color: followState.isFollowing ? Colors.red : null),
                              label: Text(followState.isFollowing ? 'Dans mon Cercle' : 'Rejoindre le Cercle',
                                style: TextStyle(color: followState.isFollowing ? Colors.red : null)),
                            ),
                          ),
                        const Divider(height: 32),
                        Text('Commentaires', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        commentsAsync.when(
                          data: (comments) => comments.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.chat_bubble_outline, size: 32, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                                        const SizedBox(height: 8),
                                        Text('Aucun commentaire', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: comments.map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: c.avatarUrl == null ? AppTheme.brandGradient : null,
                                          ),
                                          child: c.avatarUrl != null
                                              ? ClipRRect(borderRadius: BorderRadius.circular(18),
                                                  child: Image.network(c.avatarUrl!, fit: BoxFit.cover))
                                              : const Icon(Icons.person, color: Colors.white, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(c.displayName ?? c.username ?? 'Anonyme',
                                                      style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                                                    const Spacer(),
                                                    if (c.createdAt != null)
                                                      Text(_formatShortTime(c.createdAt!),
                                                        style: t.textTheme.bodySmall?.copyWith(fontSize: 10)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(c.content, style: t.textTheme.bodyMedium),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
                          error: (err, _) => Center(child: Text('Erreur: $err', style: TextStyle(color: t.colorScheme.error))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: t.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
            ),
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Écrire un commentaire...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(gradient: AppTheme.brandGradient, shape: BoxShape.circle),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18, color: Colors.white),
                    onPressed: _isSending ? null : _sendComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  String _formatShortTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
