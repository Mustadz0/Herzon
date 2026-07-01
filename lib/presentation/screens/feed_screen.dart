import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/post_provider.dart';
import '../providers/story_provider.dart';
import '../providers/trending_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_circle_row.dart';
import 'create_post_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(postProvider);
    final trendingState = ref.watch(trendingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pres de moi'),
        actions: [
          _buildModeToggle(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(postProvider.notifier).loadFeed();
              ref.read(storyProvider.notifier).loadStories();
              if (_mode == FeedMode.trending) {
                ref.read(trendingProvider.notifier).loadTrending();
              }
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
          children: [
            StoryCircleRow(),
            const Divider(height: 1),
            if (_mode == FeedMode.latest)
              ..._buildFeedList(feedState)
            else
              ..._buildTrendingList(trendingState),
            if (feedState.isLoadingMore)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (created == true) ref.read(postProvider.notifier).loadFeed();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildModeToggle() {
    return PopupMenuButton<FeedMode>(
      icon: Icon(
        _mode == FeedMode.latest ? Icons.access_time : Icons.trending_up,
      ),
      onSelected: (mode) {
        setState(() => _mode = mode);
        if (mode == FeedMode.trending) {
          ref.read(trendingProvider.notifier).loadTrending();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: FeedMode.latest,
          child: Row(
            children: [
              Icon(Icons.access_time, size: 20),
              SizedBox(width: 8),
              Text('Recent'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: FeedMode.trending,
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20),
              SizedBox(width: 8),
              Text('Tendances'),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeedList(FeedState state) {
    if (state.isLoading) {
      return [const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      )];
    }

    if (state.error != null) {
      return [Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erreur: ${state.error}'),
            TextButton(
              onPressed: () => ref.read(postProvider.notifier).loadFeed(),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      )];
    }

    if (state.posts.isEmpty) {
      return [const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.near_me_disabled, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('Rien dans un rayon de 2 km',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Soyez le premier a poster!',
                style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      )];
    }

    return state.posts.map((post) => PostCard(post: post)).toList();
  }

  List<Widget> _buildTrendingList(TrendingState state) {
    if (state.isLoading) {
      return [const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      )];
    }

    if (state.error != null) {
      return [Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erreur: ${state.error}'),
            TextButton(
              onPressed: () => ref.read(trendingProvider.notifier).loadTrending(),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      )];
    }

    if (state.posts.isEmpty) {
      return [const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Aucune tendance pour le moment',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      )];
    }

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.trending_up, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Tendances a proximite',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      ),
      ...state.posts.map((post) => PostCard(post: post)),
    ];
  }
}
