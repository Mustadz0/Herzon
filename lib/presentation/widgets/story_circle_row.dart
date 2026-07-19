import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/story_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/story_model.dart';
import '../../core/utils/firebase_uuid.dart';
import '../screens/story_viewer_screen.dart';

class StoryCircleRow extends ConsumerStatefulWidget {
  const StoryCircleRow({super.key});

  @override
  ConsumerState<StoryCircleRow> createState() => _StoryCircleRowState();
}

class _StoryCircleRowState extends ConsumerState<StoryCircleRow> {
  bool _canUseVibes = false;

  @override
  void initState() {
    super.initState();
    _checkVibesPermission();
  }

  Future<void> _checkVibesPermission() async {
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('can_use_vibes, is_admin')
          .eq('id', FirebaseUuid.toUuid(fbUser.uid))
          .single();
      if (mounted) {
        setState(() {
          _canUseVibes = profile['can_use_vibes'] == true || profile['is_admin'] == true;
        });
      }
        } catch (e) { debugPrint('StoryCircleRow: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyProvider);


    final stories = storyState.stories;

    if (storyState.isLoading) {
      return SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: _StoryShimmer(),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: stories.length + (_canUseVibes ? 1 : 0),
        itemBuilder: (context, index) {
          if (_canUseVibes && index == 0) return const _AddStoryCircle();
          final story = _canUseVibes ? stories[index - 1] : stories[index];
          final hasUnviewed = !storyState.viewedStoryIds.contains(story.id);
          return _StoryCircle(story: story, hasUnviewed: hasUnviewed,
            onTap: () {
              ref.read(storyProvider.notifier).viewStory(story.id);
              Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(story: story)));
            });
        },
      ),
    );
  }
}

class _AddStoryCircle extends StatelessWidget {
  const _AddStoryCircle();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/create_story'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.08),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside),
              ),
              child: const Icon(Icons.add, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(height: 6),
            Text('Story', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final StoryModel story;
  final bool hasUnviewed;
  final VoidCallback onTap;

  const _StoryCircle({required this.story, required this.hasUnviewed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68, height: 68,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed ? AppTheme.warmGradient : LinearGradient(colors: [Colors.grey[400]!, Colors.grey[400]!]),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.isDark ? AppTheme.cardDark : Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: story.avatarUrl != null
                      ? Image.network(story.avatarUrl!, fit: BoxFit.cover, width: 68, height: 68,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey, size: 28))
                      : const Icon(Icons.person, color: Colors.grey, size: 28),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(story.displayName?.split(' ').first ?? 'User',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: t.colorScheme.onSurfaceVariant),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StoryShimmer extends StatelessWidget {
  const _StoryShimmer();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 68, height: 68, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
        const SizedBox(height: 6),
        Container(width: 40, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
      ],
    );
  }
}
