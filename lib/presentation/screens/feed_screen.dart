import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/post_provider.dart';
import '../providers/story_provider.dart';
import '../providers/trending_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_circle_row.dart';
import 'create_post_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../services/location_service.dart';

enum FeedMode { latest, trending }

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  FeedMode _mode = FeedMode.latest;
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

  Future<void> _jeSuisLa(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final loc = await ref.read(locationServiceProvider).initializeLocation();
      final zoneName = '${loc.latitude.toStringAsFixed(2)}, ${loc.longitude.toStringAsFixed(2)}';
      final displayName = user.userMetadata?['display_name'] as String? ?? user.email ?? 'Quelqu\'un';
      await Supabase.instance.client.functions.invoke('je-suis-la', body: {
        'userId': user.id,
        'userName': displayName,
        'zoneName': zoneName,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Je suis lÃ  ! Vos Fans et votre Cercle ont Ã©tÃ© notifiÃ©s.'),
          ]),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final feedState = ref.watch(postProvider);
    final trendingState = ref.watch(trendingProvider);

    return Scaffold(
      appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_new.png',
                width: 28, height: 28,
              ),
              const SizedBox(width: 10),
              const Text('Herzon', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_rounded, color: AppTheme.primary),
            tooltip: 'Je suis lÃ ',
            onPressed: () => _jeSuisLa(context),
          ),
          _ModeToggle(
            mode: _mode,
            onChanged: (m) {
              setState(() => _mode = m);
              if (m == FeedMode.trending) ref.read(trendingProvider.notifier).loadTrending();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(postProvider.notifier).loadFeed();
              ref.read(storyProvider.notifier).loadStories();
              if (_mode == FeedMode.trending) ref.read(trendingProvider.notifier).loadTrending();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(postProvider.notifier).loadFeed();
          await ref.read(storyProvider.notifier).loadStories();
        },
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          children: [
            const StoryCircleRow(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.linear_scale, size: 16, color: t.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(_mode == FeedMode.latest ? 'Fil d\'actualitÃ©' : 'Tendances',
                    style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (_mode == FeedMode.latest) ..._buildFeedList(feedState, t)
            else ..._buildTrendingList(trendingState, t),
            if (feedState.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
          if (created == true) ref.read(postProvider.notifier).loadFeed();
        },
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }

  List<Widget> _buildFeedList(FeedState state, ThemeData t) {
    if (state.isLoading) return [_ShimmerLoading()];
    if (state.error != null) {
      return [Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Erreur: ${state.error}', style: t.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(onPressed: () => ref.read(postProvider.notifier).loadFeed(),
              icon: const Icon(Icons.refresh, size: 18), label: const Text('RÃ©essayer')),
          ],
        )),
      )];
    }
    if (state.posts.isEmpty) {
      return [Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.near_me_disabled, size: 36, color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text('Rien dans un rayon de 2 km', style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Soyez le premier Ã  publier !', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
        )),
      )];
    }
    return state.posts.map((post) => PostCard(post: post)).toList();
  }

  List<Widget> _buildTrendingList(TrendingState state, ThemeData t) {
    if (state.isLoading) return [_ShimmerLoading()];
    if (state.error != null) {
      return [Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Column(
          children: [
            Icon(Icons.trending_down, size: 48, color: t.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Erreur: ${state.error}', style: t.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(onPressed: () => ref.read(trendingProvider.notifier).loadTrending(),
              icon: const Icon(Icons.refresh, size: 18), label: const Text('RÃ©essayer')),
          ],
        )),
      )];
    }
    if (state.posts.isEmpty) {
      return [
      Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Text('Aucune tendance pour le moment', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant))),
      )
    ];
    }
    return state.posts.map((post) => PostCard(post: post)).toList();
  }
}

class _ModeToggle extends StatelessWidget {
  final FeedMode mode;
  final ValueChanged<FeedMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(mode == FeedMode.latest ? FeedMode.trending : FeedMode.latest),
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: t.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToggleOption(icon: Icons.access_time, label: 'RÃ©cent', selected: mode == FeedMode.latest),
            _ToggleOption(icon: Icons.trending_up, label: 'Top', selected: mode == FeedMode.trending),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _ToggleOption({required this.icon, required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
      )),
    );
  }
}
