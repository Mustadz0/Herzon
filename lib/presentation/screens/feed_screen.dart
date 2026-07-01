import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(postProvider.notifier).loadFeed());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pres de moi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(postProvider.notifier).loadFeed(),
          ),
        ],
      ),
      body: _buildBody(state),
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

  Widget _buildBody(FeedState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.near_me_disabled, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Rien dans un rayon de 2 km',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soyez le premier a poster!',
              style: TextStyle(color: Colors.grey),
            ),
            TextButton(
              onPressed: () => ref.read(postProvider.notifier).loadFeed(),
              child: const Text('Rafraichir'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.posts.length,
      itemBuilder: (context, index) => PostCard(post: state.posts[index]),
    );
  }
}
