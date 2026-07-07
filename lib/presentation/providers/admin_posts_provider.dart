import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';

class AdminPostsState {
  final List<PostModel> posts;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  AdminPostsState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  AdminPostsState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return AdminPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AdminPostsNotifier extends StateNotifier<AdminPostsState> {
  final SupabaseClient _supabase;

  AdminPostsNotifier(this._supabase) : super(AdminPostsState()) {
    loadPosts();
  }

  Future<void> loadPosts({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      var query = _supabase.from('posts').select('*, profiles(display_name, username, avatar_url)');
      if (search != null && search.isNotEmpty) {
        query = query.ilike('content', '%$search%');
      }
      final data = await query.order('created_at', ascending: false).limit(100);
      final posts = data.map((json) => PostModel.fromJson(json)).toList();
      state = state.copyWith(posts: posts, isLoading: false, searchQuery: search);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _supabase.from('posts').delete().eq('id', postId);
      state = state.copyWith(posts: state.posts.where((p) => p.id != postId).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminPostsProvider = StateNotifierProvider<AdminPostsNotifier, AdminPostsState>((ref) {
  return AdminPostsNotifier(Supabase.instance.client);
});
