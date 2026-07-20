// Fix: SearchNotifier استدعى Supabase مباشرة — الآن يستخدم repository.
// Fix: debounce مُضاف لمنع طلب لكل حرف مكتوب.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';

// ── Repository ────────────────────────────────────────────────────────────
abstract class ISearchRepository {
  Future<Map<String, dynamic>> searchAll(String query);
}

class SupabaseSearchRepository implements ISearchRepository {
  final SupabaseClient _supabase;
  SupabaseSearchRepository(this._supabase);

  @override
  Future<Map<String, dynamic>> searchAll(String query) async {
    final results = await _supabase
        .rpc('search_all', params: {'search_query': query});
    return results as Map<String, dynamic>;
  }
}

final searchRepositoryProvider = Provider<ISearchRepository>((ref) {
  return SupabaseSearchRepository(Supabase.instance.client);
});

// ── State ─────────────────────────────────────────────────────────────────
class SearchState {
  final String query;
  final List<PostModel> posts;
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.posts = const [],
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<PostModel>? posts,
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      posts: posts ?? this.posts,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────
class SearchNotifier extends StateNotifier<SearchState> {
  final ISearchRepository _repo;
  Timer? _debounce;

  SearchNotifier(this._repo) : super(const SearchState());

  // Debounce 400ms لمنع طلب لكل حرف
  void onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => search(q));
  }

  Future<void> search(String q) async {
    if (q.trim().isEmpty) return;
    state = state.copyWith(query: q, isLoading: true, error: null);
    try {
      final results = await _repo.searchAll(q.trim());

      final rawPosts = (results['posts'] as List<dynamic>?) ?? [];
      final posts = rawPosts.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        map.putIfAbsent('latitude', () => 0.0);
        map.putIfAbsent('longitude', () => 0.0);
        return PostModel.fromJson(map);
      }).toList();

      final users = (results['users'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      if (mounted) {
        state = state.copyWith(posts: posts, users: users, isLoading: false);
      }
    } catch (e) {
      debugPrint('SearchNotifier.search error: \$e');
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(searchRepositoryProvider));
});
