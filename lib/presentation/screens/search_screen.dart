import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/search_provider.dart';
import 'user_profile_screen.dart';
import 'post_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      ref.read(searchProvider.notifier).clear();
      return;
    }
    ref.read(searchProvider.notifier).search(query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clear();
                    },
                  )
                : null,
          ),
          onChanged: _onSearch,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personnes'),
            Tab(text: 'Publications'),
            Tab(text: 'Zones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users tab
          _buildList(
            isLoading: searchState.isLoading,
            items: searchState.users,
            emptyMessage: 'Aucun utilisateur trouvé',
            builder: (user) => ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: user.avatarUrl == null ? AppTheme.brandGradient : null,
                ),
                child: user.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(user.avatarUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(user.displayName ?? user.username ?? 'Anonyme'),
              subtitle: user.username != null ? Text('@${user.username}') : null,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)),
              ),
            ),
          ),
          // Posts tab
          _buildList(
            isLoading: searchState.isLoading,
            items: searchState.posts,
            emptyMessage: 'Aucune publication trouvée',
            builder: (post) => ListTile(
              title: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(post.userDisplayName ?? post.userUsername ?? 'Anonyme'),
              leading: const Icon(Icons.article_outlined),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
              ),
            ),
          ),
          // Zones tab
          _buildList(
            isLoading: searchState.isLoading,
            items: searchState.zones,
            emptyMessage: 'Aucune zone trouvée',
            builder: (zone) => ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.brandGradient,
                ),
                child: Center(
                  child: Text(zone.emoji ?? '📍',
                    style: const TextStyle(fontSize: 20)),
                ),
              ),
              title: Text(zone.name ?? 'Zone'),
              subtitle: Text(zone.heatLabel ?? ''),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList<T>({
    required bool isLoading,
    required List<T> items,
    required String emptyMessage,
    required Widget Function(T) builder,
  }) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return Center(
        child: Text(emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => builder(items[i]),
    );
  }
}
