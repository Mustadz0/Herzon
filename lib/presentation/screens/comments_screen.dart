import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/comment_repository.dart';
import '../../core/theme/app_theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
extension _ThemeDark on ThemeData {
  // Fix #1: ThemeData has no .isDark — use brightness instead.
  bool get isDark => brightness == Brightness.dark;
}

// ── StateNotifier with Realtime ───────────────────────────────────────────────
class _CommentsNotifier extends StateNotifier<AsyncValue<List<CommentModel>>> {
  final ICommentRepository _repo;
  final String postId;
  RealtimeChannel? _channel;

  _CommentsNotifier(this._repo, this.postId)
      : super(const AsyncValue.loading()) {
    _load();
    _subscribeRealtime();
  }

  Future<void> _load() async {
    try {
      final comments = await _repo.getComments(postId);
      if (mounted) state = AsyncValue.data(comments);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('comments:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (_) => _load(),
        )
        .subscribe();
  }

  Future<void> addComment(String userId, String content,
      {String? parentId}) async {
    await _repo.addComment(postId, userId, content, parentId: parentId);
    // Realtime will trigger _load() automatically.
  }

  Future<void> deleteComment(String commentId) async {
    await _repo.deleteComment(commentId);
    // Optimistic removal while Realtime confirms.
    final current = state.valueOrNull ?? [];
    if (mounted) {
      state = AsyncValue.data(
        current
            .where((c) => c.id != commentId && c.parentId != commentId)
            .toList(),
      );
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final commentsNotifierProvider = StateNotifierProvider.family<
    _CommentsNotifier, AsyncValue<List<CommentModel>>, String>(
  (ref, postId) =>
      _CommentsNotifier(ref.watch(commentRepositoryProvider), postId),
);

// Fix #2: legacy alias now delegates to the Realtime-aware notifier so
// any file that still reads commentsProvider also gets live updates.
final commentsProvider = FutureProvider.family<List<CommentModel>, String>(
  (ref, postId) async {
    final async = ref.watch(commentsNotifierProvider(postId));
    return async.maybeWhen(
      data: (list) => list,
      orElse: () => ref.read(commentRepositoryProvider).getComments(postId),
    );
  },
);

// ── Screen ────────────────────────────────────────────────────────────────────
class CommentsScreen extends ConsumerStatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _controller = TextEditingController();
  // Fix #3: ScrollController for auto-scroll after send.
  final _scrollController = ScrollController();
  bool _isSending = false;
  CommentModel? _replyingTo;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls to the bottom of the list after a short delay so
  /// the new comment has time to render.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await ref
          .read(commentsNotifierProvider(widget.postId).notifier)
          .addComment(user.id, content, parentId: _replyingTo?.id);
      _controller.clear();
      setState(() => _replyingTo = null);
      _scrollToBottom(); // Fix #3: auto-scroll
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: AppTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.stars, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 12),
            const Text('+5 XP !',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1, milliseconds: 500),
          backgroundColor: AppTheme.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final commentsAsync = ref.watch(commentsNotifierProvider(widget.postId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: Column(
        children: [
          // ── Comments list ────────────────────────────────────────────────
          Expanded(
            child: commentsAsync.when(
              data: (all) {
                final roots = all.where((c) => c.parentId == null).toList();
                if (roots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: t.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text('Aucun commentaire',
                            style: t.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Soyez le premier à commenter',
                          style: TextStyle(
                              color: t.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController, // Fix #3: attach controller
                  padding: const EdgeInsets.all(16),
                  itemCount: roots.length,
                  itemBuilder: (_, i) {
                    final c = roots[i];
                    final replies =
                        all.where((r) => r.parentId == c.id).toList();
                    return _CommentTile(
                      comment: c,
                      replies: replies,
                      currentUserId: currentUserId,
                      onReply: () => setState(() => _replyingTo = c),
                      onDelete: (id) => ref
                          .read(commentsNotifierProvider(widget.postId)
                              .notifier)
                          .deleteComment(id),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Erreur: $err',
                  style: TextStyle(color: t.colorScheme.error),
                ),
              ),
            ),
          ),

          // ── Reply banner ─────────────────────────────────────────────────
          if (_replyingTo != null)
            Container(
              color: AppTheme.primary.withValues(alpha: 0.1),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Répondre à '
                      '${_replyingTo!.displayName ?? _replyingTo!.username ?? 'Anonyme'}',
                      style: const TextStyle(
                          color: AppTheme.primary, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingTo = null),
                    child: const Icon(Icons.close,
                        size: 16, color: AppTheme.primary),
                  ),
                ],
              ),
            ),

          // ── Input bar ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: t.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  // Fix #1: use isDark extension instead of t.isDark
                  color: t.isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? 'Répondre...'
                          : 'Écrire un commentaire...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      // Fix #1: use isDark extension
                      fillColor: t.isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send,
                            size: 18, color: Colors.white),
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
}

// ── Comment tile ──────────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final String? currentUserId;
  final VoidCallback onReply;
  final Future<void> Function(String) onDelete;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBubble(context, t, comment, isReply: false),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 8),
              child: Column(
                children: replies
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildBubble(context, t, r, isReply: true),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    ThemeData t,
    CommentModel c, {
    required bool isReply,
  }) {
    final isOwn = c.userId == currentUserId;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: isReply ? 30 : 38,
          height: isReply ? 30 : 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: c.avatarUrl == null ? AppTheme.brandGradient : null,
          ),
          child: c.avatarUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(isReply ? 15 : 19),
                  child: Image.network(c.avatarUrl!, fit: BoxFit.cover),
                )
              : const Icon(Icons.person, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  // Fix #1: use isDark extension
                  color: t.isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          c.displayName ?? c.username ?? 'Anonyme',
                          style: t.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        if (c.createdAt != null)
                          Text(
                            _formatTime(c.createdAt!),
                            style: t.textTheme.bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(c.content, style: t.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (!isReply)
                    GestureDetector(
                      onTap: onReply,
                      child: Row(
                        children: [
                          Icon(Icons.reply,
                              size: 14,
                              color: t.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            'Répondre',
                            style: TextStyle(
                                fontSize: 11,
                                color: t.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  if (isOwn) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => onDelete(c.id),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 3),
                          Text(
                            'Supprimer',
                            style: TextStyle(
                                fontSize: 11, color: Colors.red.shade400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
