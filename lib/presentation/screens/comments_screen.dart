import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/comment_repository.dart';
import '../../core/theme/app_theme.dart';

final commentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, postId) {
  return ref.watch(commentRepositoryProvider).getComments(postId);
});

class CommentsScreen extends ConsumerStatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await ref.read(commentRepositoryProvider).addComment(widget.postId, user.id, content);
      _controller.clear();
      ref.invalidate(commentsProvider(widget.postId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.stars, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 12),
            const Text('+5 XP !', style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1, milliseconds: 500),
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              data: (comments) => comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('Aucun commentaire', style: t.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('Soyez le premier Ã  commenter', style: TextStyle(color: t.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: comments.length,
                      itemBuilder: (_, i) {
                        final c = comments[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: c.avatarUrl == null ? AppTheme.brandGradient : null,
                                ),
                                child: c.avatarUrl != null
                                    ? ClipRRect(borderRadius: BorderRadius.circular(19),
                                        child: Image.network(c.avatarUrl!, fit: BoxFit.cover))
                                    : const Icon(Icons.person, color: Colors.white, size: 20),
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
                                            Text(_formatTime(c.createdAt!),
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
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err', style: TextStyle(color: t.colorScheme.error))),
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
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ã‰crire...',
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
                  decoration: BoxDecoration(gradient: AppTheme.brandGradient, shape: BoxShape.circle),
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
