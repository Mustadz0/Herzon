import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';

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

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  Future<void> search(String q) async {
    state = state.copyWith(query: q, isLoading: true, error: null);
    try {
      final results = await Supabase.instance.client
          .rpc('search_all', params: {'search_query': q});

      // Safely parse posts — the search RPC may not return lat/lng,
      // so we inject 0.0 as fallback to avoid null errors in PostModel.
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

      state = state.copyWith(posts: posts, users: users, isLoading: false);
    } catch (e) {
      debugPrint('SearchNotifier.search error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});
