import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/comment_repository.dart';

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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: Column(
        children: [
          Expanded(
            child: commentsAsync.when(
              data: (comments) => comments.isEmpty
                  ? const Center(child: Text('Aucun commentaire'))
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) => _CommentTile(comment: comments[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err')),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 8, top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ecrire un commentaire...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: comment.avatarUrl != null
            ? NetworkImage(comment.avatarUrl!)
            : null,
        child: comment.avatarUrl == null ? const Icon(Icons.person, size: 18) : null,
      ),
      title: Text(
        comment.displayName ?? comment.username ?? 'Anonyme',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(comment.content),
      trailing: comment.createdAt != null
          ? Text(
              _formatTime(comment.createdAt!),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            )
          : null,
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
