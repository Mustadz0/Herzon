import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/post_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_circle_row.dart';
import 'create_post_screen.dart';
import 'search_screen.dart';
import 'messages_screen.dart';
import 'explorer_screen.dart';
import '../../core/theme/app_theme.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(postProvider.notifier).loadFeed();
      ref.read(storyProvider.notifier).loadStories();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(postProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(postProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(postProvider.notifier).loadFeed();
              await ref.read(storyProvider.notifier).loadStories();
            },
            child: ListView(
              controller: _scrollController,
              children: [
            // Herzon logo centered
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
                  child: const Text(
                    'Herzon',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Hot + Zone Name + Je suis la
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Hot button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.whatshot, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text('Hot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Zone name + people count
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me, color: Color(0xFF4F46E5), size: 14),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'La Zone',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('12', style: TextStyle(color: const Color(0xFF4F46E5), fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Je suis la button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, color: const Color(0xFF4F46E5), size: 14),
                        const SizedBox(width: 4),
                        const Text('Je suis la', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent/Top toggle + Search + Notifications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  // Recent/Top toggle pills
                  _buildPillToggle(),
                  const Spacer(),
                  _smallActionButton(Icons.search, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
                  const SizedBox(width: 6),
                  _smallActionButton(Icons.notifications_outlined, () {}),
                ],
              ),
            ),

            // Stories
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 8),
              child: StoryCircleRow(),
            ),

            // Section: Ce qui se passe
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 18,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ce qui se passe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Feed posts
            if (feedState.isLoading)
              ...List.generate(3, (_) => _shimmerCard())
            else if (feedState.error != null)
              _errorState(feedState.error!)
            else if (feedState.posts.isEmpty)
              _emptyState()
            else
              ...feedState.posts.map((post) => PostCard(post: post)),

            if (feedState.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4F46E5)))),
              ),
          ],
        ),
      ),
        Positioned(
          right: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationsListScreen())),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildPillToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pillOption('Recent', true),
          _pillOption('Top', false),
        ],
      ),
    );
  }

  Widget _pillOption(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: selected ? AppTheme.brandGradient : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _smallActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _errorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text('Erreur', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: () => ref.read(postProvider.notifier).loadFeed(), child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppTheme.brandGradient.colors.map((c) => c.withValues(alpha: 0.15)).toList()),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.near_me_disabled, size: 44, color: AppTheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text('Rien dans la zone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Soyez le premier a publier !', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () async {
              final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
              if (created == true) ref.read(postProvider.notifier).loadFeed();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Creer un post'),
          ),
        ],
      ),
    );
  }
}
