import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../core/constants/app_constants.dart';
import '../providers/post_provider.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
              ],
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
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 20),
                  onPressed: () {},
                  tooltip: 'Follow',
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: () {},
                  tooltip: 'Repondre',
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
