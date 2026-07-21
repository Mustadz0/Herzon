import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/user_list_tile.dart';
import '../../core/theme/app_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final trimmed = q.trim();
      if (trimmed.isEmpty) return;
      if (!mounted) return;
      ref.read(searchProvider.notifier).search(trimmed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SearchBar(
            controller: _ctrl,
            focusNode: _focus,
            hintText: 'Rechercher personnes, posts...',
            hintStyle: WidgetStatePropertyAll(
              tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            leading: Icon(Icons.search, color: cs.onSurfaceVariant),
            trailing: [
              if (_ctrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    ref.read(searchProvider.notifier).clear();
                  },
                ),
            ],
            onChanged: _onSearch,
            onSubmitted: _onSearch,
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerLow),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Personnes'),
          ],
          indicatorColor: cs.primary,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          dividerColor: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      body: state.isLoading
          ? Center(
              child: CircularProgressIndicator(color: cs.primary))
          : state.query.isEmpty
              ? _EmptyHint(cs: cs, tt: tt)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Posts tab
                    state.posts.isEmpty
                        ? _NoResults(
                            query: state.query, cs: cs, tt: tt)
                        : ListView.builder(
                            itemCount: state.posts.length,
                            itemBuilder: (_, i) =>
                                PostCard(post: state.posts[i]),
                          ),
                    // People tab
                    state.users.isEmpty
                        ? _NoResults(
                            query: state.query, cs: cs, tt: tt)
                        : ListView.builder(
                            itemCount: state.users.length,
                            itemBuilder: (_, i) =>
                                UserListTile(user: state.users[i]),
                          ),
                  ],
                ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _EmptyHint({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_rounded,
                size: 36, color: cs.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text('Commencez à taper...',
              style: tt.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Recherchez des posts ou des personnes',
            style:
                tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final ColorScheme cs;
  final TextTheme tt;
  const _NoResults(
      {required this.query, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Aucun résultat pour "$query"',
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
