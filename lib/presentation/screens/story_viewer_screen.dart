import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/story_model.dart';
import '../providers/story_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryModel story;

  const StoryViewerScreen({super.key, required this.story});

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(storyProvider.notifier).viewStory(widget.story.id);
  }

  Future<void> _showViewers() async {
    final data = await Supabase.instance.client
        .from('story_views')
        .select('viewed_at, profiles!inner(username, display_name, avatar_url)')
        .eq('story_id', widget.story.id)
        .order('viewed_at', ascending: false);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        itemCount: data.length,
        itemBuilder: (_, i) {
          final view = data[i];
          final profile = view['profiles'] as Map?;
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: profile?['avatar_url'] != null
                  ? NetworkImage(profile!['avatar_url'] as String)
                  : null,
              child: profile?['avatar_url'] == null ? const Icon(Icons.person, size: 20) : null,
            ),
            title: Text((profile?['display_name'] ?? profile?['username'] ?? 'Anonyme') as String),
            trailing: view['viewed_at'] != null
                ? Text(_formatTime(DateTime.parse(view['viewed_at'] as String)), style: const TextStyle(fontSize: 12, color: Colors.grey))
                : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              story.mediaUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                );
              },
            ),
            if (story.textOverlay != null)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Text(
                  story.textOverlay!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: story.avatarUrl != null
                        ? NetworkImage(story.avatarUrl!)
                        : null,
                    child: story.avatarUrl == null
                        ? const Icon(Icons.person, size: 20, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.displayName ?? story.username ?? 'Anonyme',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (story.createdAt != null)
                        Text(
                          _formatTime(story.createdAt!),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.white70),
                    onPressed: _showViewers,
                    tooltip: 'Vues',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Appuyer pour fermer',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}
