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
import '../widgets/post_card.dart';
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
                      height: 300,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: post.mediaUrls.length,
                        itemBuilder: (_, i) => Image.network(post.mediaUrls[i], fit: BoxFit.cover),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => UserProfileScreen(userId: post.userId),
                          )),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: post.userAvatarUrl != null
                                    ? NetworkImage(post.userAvatarUrl!)
                                    : null,
                                child: post.userAvatarUrl == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.userDisplayName ?? post.userUsername ?? 'Anonyme',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (post.createdAt != null)
                                    Text(_formatTime(post.createdAt!), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                              if (post.contextTag != null) ...[
                                const Spacer(),
                                Chip(label: Text(post.contextTag!, style: const TextStyle(fontSize: 11))),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(post.content, style: const TextStyle(fontSize: 16, height: 1.5)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('${_formatDistance(post.distanceMeters)}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                  text: '${post.userDisplayName ?? "Quelqu\'un"} a partage: ${post.content}',
                                ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copie !'), duration: Duration(seconds: 2)),
                                );
                              },
                              icon: const Icon(Icons.share, size: 16),
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
                                child: Column(
                                  children: [
                                    Text(reaction, style: const TextStyle(fontSize: 28)),
                                    if (count > 0)
                                      Text('$count', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                              label: Text(followState.isFollowing ? 'Abonne' : 'Suivre'),
                            ),
                          ),
                        const Divider(height: 32),
                        const Text('Commentaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        commentsAsync.when(
                          data: (comments) => comments.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: Text('Aucun commentaire', style: TextStyle(color: Colors.grey[500]))),
                                )
                              : Column(
                                  children: comments.map((c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                                          child: c.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(c.displayName ?? c.username ?? 'Anonyme',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  const Spacer(),
                                                  if (c.createdAt != null)
                                                    Text(_formatShortTime(c.createdAt!),
                                                      style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(c.content, style: const TextStyle(fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(child: Text('Erreur: $err')),
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
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2))],
            ),
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Ecrire...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
