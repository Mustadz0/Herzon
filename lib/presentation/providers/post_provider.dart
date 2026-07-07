import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import '../../services/location_service.dart';
import '../../services/media_upload_service.dart';
import '../../core/constants/app_constants.dart';

class FeedState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

class PostNotifier extends StateNotifier<FeedState> {
  final IPostRepository _repo;
  final LocationService _locationService;
  final MediaUploadService _mediaUpload;
  RealtimeChannel? _realtimeChannel;
  int _currentPage = 1;

  PostNotifier(this._repo, this._locationService, this._mediaUpload) : super(const FeedState());

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final posts = await _repo.getNearbyPosts(pos, AppConstants.proximityRadiusMeters, page: 1);
      final total = await _repo.getNearbyPostsCount(pos, AppConstants.proximityRadiusMeters);
      _currentPage = 1;
      state = FeedState(posts: posts, hasMore: posts.length < total);
      _subscribeRealtime();
    } catch (e) {
      state = FeedState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final pos = await _locationService.initializeLocation();
      _currentPage++;
      final newPosts = await _repo.getNearbyPosts(pos, AppConstants.proximityRadiusMeters, page: _currentPage);
      final total = await _repo.getNearbyPostsCount(pos, AppConstants.proximityRadiusMeters);
      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: state.posts.length + newPosts.length < total,
      );
    } catch (e, stackTrace) {
      debugPrint('PostProvider loadMore error: $e\n$stackTrace');
      _currentPage--;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void _subscribeRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('public:posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) async {
            try {
              await loadFeed();
            } catch (e) {
              // Log using debugPrint for development; consider a proper logger for production.
              debugPrint('Realtime feed refresh error: $e');
            }
          },
        )
        .subscribe();
  }

  /// Returns the XP earned by the post author (+10 XP per DB trigger).
  Future<int> createPost(String content, String? contextTag, {List<File>? mediaFiles}) async {
    final pos = await _locationService.initializeLocation();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    List<String> mediaUrls = [];
    String mediaType = 'text';

    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      // Check if first file is video
      final firstFile = mediaFiles.first.path.toLowerCase();
      if (firstFile.endsWith('.mp4') || firstFile.endsWith('.mov') || firstFile.endsWith('.avi')) {
        mediaType = 'video';
      } else {
        mediaType = 'image';
      }
      mediaUrls = await _mediaUpload.uploadPostMedia(files: mediaFiles, userId: user.id);
    }

    final post = PostModel(
      id: '',
      userId: user.id,
      content: content,
      latitude: pos.latitude,
      longitude: pos.longitude,
      mediaUrls: mediaUrls,
      mediaType: mediaType == 'video' ? MediaType.video : (mediaUrls.isNotEmpty ? MediaType.image : MediaType.text),
      contextTag: contextTag,
    );
    await _repo.createPost(post);
    await loadFeed();
    return 10; // matches DB `award_xp(p_user_id, 10, 'post_created', ...)` trigger
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repo.deletePost(postId);
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
    } catch (e) {
      debugPrint('PostProvider deletePost error: $e');
    }
  }

  Future<void> editPost(String postId, String content) async {
    try {
      await _repo.updatePost(postId, content);
      state = state.copyWith(
        posts: state.posts.map((p) =>
          p.id == postId ? p.copyWith(content: content) : p
        ).toList(),
      );
    } catch (e) {
      debugPrint('PostProvider editPost error: $e');
    }
  }

  /// Returns XP earned by the post owner (+2 XP per DB trigger on `reactions` insert).
  Future<int> reactToPost(String postId, String reactionType) async {
    _optimisticallyUpdateReaction(postId, reactionType, 1);
    try {
      await _repo.reactToPost(postId, reactionType);
      return 2;
    } catch (_) {
      _optimisticallyUpdateReaction(postId, reactionType, -1);
      return 0;
    }
  }

  Future<void> removeReaction(String postId, String reactionType) async {
    _optimisticallyUpdateReaction(postId, reactionType, -1);
    try {
      await _repo.removeReaction(postId, reactionType);
    } catch (_) {
      _optimisticallyUpdateReaction(postId, reactionType, 1);
    }
  }

  void _optimisticallyUpdateReaction(String postId, String reactionType, int delta) {
    state = state.copyWith(
      posts: state.posts.map((p) {
        if (p.id != postId) return p;
        final newCounts = Map<String, int>.from(p.reactionCounts);
        newCounts[reactionType] = (newCounts[reactionType] ?? 0) + delta;
        if (newCounts[reactionType]! <= 0) newCounts.remove(reactionType);
        return p.copyWith(reactionCounts: newCounts);
      }).toList(),
    );
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

final postProvider = StateNotifierProvider<PostNotifier, FeedState>((ref) {
  return PostNotifier(
    ref.watch(postRepositoryProvider),
    ref.watch(locationServiceProvider),
    ref.watch(mediaUploadServiceProvider),
  );
});
