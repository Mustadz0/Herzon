import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../core/utils/safe_error.dart';

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
  final AdminRepository _repo;

  AdminPostsNotifier(this._repo) : super(AdminPostsState()) {
    loadPosts();
  }

  Future<void> loadPosts({String? search}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _repo.getAllPosts(search: search);
      state = state.copyWith(posts: posts, isLoading: false, searchQuery: search);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: safeErrorMessage(e));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repo.deletePost(postId);
      state = state.copyWith(posts: state.posts.where((p) => p.id != postId).toList());
    } catch (e) {
      state = state.copyWith(error: safeErrorMessage(e));
    }
  }
}

final adminPostsProvider =
    StateNotifierProvider<AdminPostsNotifier, AdminPostsState>((ref) {
  return AdminPostsNotifier(ref.watch(adminRepositoryProvider));
});
