import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';

class SearchState {
  final String query;
  final List<PostModel> posts;
  final List<Map<String, dynamic>> users;
  final bool isLoading;

  const SearchState({
    this.query = '', this.posts = const [], this.users = const [], this.isLoading = false,
  });

  SearchState copyWith({String? query, List<PostModel>? posts, List<Map<String, dynamic>>? users, bool? isLoading}) {
    return SearchState(
      query: query ?? this.query,
      posts: posts ?? this.posts,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  Future<void> search(String q) async {
    state = state.copyWith(query: q, isLoading: true);
    try {
      final results = await Supabase.instance.client.rpc('search_all', params: {'search_query': q});
      final posts = (results['posts'] as List<dynamic>?)?.map((e) => PostModel.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      final users = (results['users'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      state = state.copyWith(posts: posts, users: users, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});
