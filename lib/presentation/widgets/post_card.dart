import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';
import '../../core/constants/app_constants.dart';
import '../providers/post_provider.dart';
import '../providers/follow_provider.dart';
import '../screens/comments_screen.dart';
import '../screens/report_screen.dart';
import '../screens/edit_post_screen.dart';
import '../screens/user_profile_screen.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.userId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final isOwnPost = user != null && user.id == post.userId;
    final followState = ref.watch(followProvider(post.userId));

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openProfile(context),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: post.userAvatarUrl != null
                        ? NetworkImage(post.userAvatarUrl!)
                        : null,
                    child: post.userAvatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userDisplayName ?? post.userUsername ?? 'Anonyme',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (post.contextTag != null)
                        Text(
                          post.contextTag!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDistance(post.distanceMeters),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (post.createdAt != null)
                        Text(
                          _formatTime(post.createdAt!),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                    ],
                  ),
                  if (isOwnPost)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditPostScreen(postId: post.id, currentContent: post.content),
                              ),
                            );
                            if (result == true) ref.read(postProvider.notifier).loadFeed();
                          case 'delete':
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Supprimer'),
                                content: const Text('Voulez-vous vraiment supprimer cette publication ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref.read(postProvider.notifier).deletePost(post.id);
                            }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Modifier')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
                      ],
                    )
                  else
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'report') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(postId: post.id)));
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag, size: 18), SizedBox(width: 8), Text('Signaler')])),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(fontSize: 15)),
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.mediaUrls.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post.mediaUrls[index],
                        height: 200, width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                ...AppConstants.reactions.map((reaction) {
                  final count = post.reactionCounts[reaction] ?? 0;
                  return _ReactionButton(
                    reaction: reaction,
                    count: count,
                    onPressed: () {
                      ref.read(postProvider.notifier).reactToPost(post.id, reaction);
                    },
                  );
                }),
                const Spacer(),
                if (!isOwnPost)
                  IconButton(
                    icon: Icon(
                      followState.isFollowing ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: followState.isFollowing ? Colors.red : null,
                    ),
                    onPressed: followState.isLoading ? null : () {
                      if (user == null) return;
                      if (followState.isFollowing) {
                        ref.read(followProvider(post.userId).notifier).unfollow();
                      } else {
                        ref.read(followProvider(post.userId).notifier).follow();
                      }
                    },
                    tooltip: followState.isFollowing ? 'Ne plus suivre' : 'Suivre',
                  ),
                IconButton(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20),
                      if (post.commentCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '${post.commentCount}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(postId: post.id),
                      ),
                    );
                  },
                  tooltip: 'Commenter',
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '${post.userDisplayName ?? "Quelqu\'un"} a partage pres de vous: ${post.content}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lien copie dans le presse-papier'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Partager',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

class _ReactionButton extends StatelessWidget {
  final String reaction;
  final int count;
  final VoidCallback onPressed;

  const _ReactionButton({
    required this.reaction,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reaction, style: const TextStyle(fontSize: 18)),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
