import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/story_model.dart';
import '../../core/theme/app_theme.dart';
import '../providers/story_provider.dart';
import '../screens/story_viewer_screen.dart';
import '../screens/create_story_screen.dart';

class StoryCircleRow extends ConsumerWidget {
  const StoryCircleRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyProvider);
    final stories = state.stories;

    if (state.isLoading && stories.isEmpty) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (stories.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: TextButton.icon(
            onPressed: () => _createStory(context, ref),
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            label: const Text('Ajouter une story'),
          ),
        ),
      );
    }

    final user = Supabase.instance.client.auth.currentUser;
    final myStories = stories.where((s) => s.userId == user?.id).toList();
    final otherStories = stories.where((s) => s.userId != user?.id).toList();

    final groupedUsers = <String, List<StoryModel>>{};
    for (final s in otherStories) {
      groupedUsers.putIfAbsent(s.userId, () => []).add(s);
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: 1 + groupedUsers.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _MyStoryCircle(
              stories: myStories,
              onAddTap: () => _createStory(context, ref),
              onViewTap: (story) => _viewStory(context, ref, story),
            );
          }
          final entry = groupedUsers.entries.elementAt(index - 1);
          final userStories = entry.value;
          final firstStory = userStories.first;
          final hasUnviewed = userStories.any(
            (s) => !state.viewedStoryIds.contains(s.id),
          );
          return _UserStoryCircle(
            story: firstStory,
            hasUnviewed: hasUnviewed,
            storyCount: userStories.length,
            onTap: () => _viewStory(context, ref, firstStory),
          );
        },
      ),
    );
  }

  void _createStory(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
    );
    if (created == true) ref.read(storyProvider.notifier).loadStories();
  }

  void _viewStory(BuildContext context, WidgetRef ref, StoryModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(story: story),
      ),
    );
  }
}

class _MyStoryCircle extends StatelessWidget {
  final List<StoryModel> stories;
  final VoidCallback onAddTap;
  final void Function(StoryModel) onViewTap;

  const _MyStoryCircle({
    required this.stories,
    required this.onAddTap,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: stories.isNotEmpty ? () => onViewTap(stories.first) : onAddTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                  backgroundImage: stories.isNotEmpty
                      ? NetworkImage(stories.first.mediaUrl)
                      : null,
                  child: stories.isEmpty
                      ? const Icon(Icons.add, size: 32, color: AppTheme.primaryColor)
                      : null,
                ),
                if (stories.isEmpty)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ma story',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UserStoryCircle extends StatelessWidget {
  final StoryModel story;
  final bool hasUnviewed;
  final int storyCount;
  final VoidCallback onTap;

  const _UserStoryCircle({
    required this.story,
    required this.hasUnviewed,
    required this.storyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: hasUnviewed ? AppTheme.primaryColor : Colors.grey[400],
              child: CircleAvatar(
                radius: 28,
                backgroundImage: story.avatarUrl != null
                    ? NetworkImage(story.avatarUrl!)
                    : null,
                child: story.avatarUrl == null
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story.displayName ?? story.username ?? 'User',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
