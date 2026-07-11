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
  final Map<String, Set<String>> userReactions;
  final Set<String> hiddenPostIds;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.userReactions = const {},
    this.hiddenPostIds = const {},
  });

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    Map<String, Set<String>>? userReactions,
    Set<String>? hiddenPostIds,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      userReactions: userReactions ?? this.userReactions,
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
    );
  }

  /// Returns visible posts (not hidden)
  List<PostModel> get visiblePosts =>
      posts.where((p) => !hiddenPostIds.contains(p.id)).toList();
}

class PostNotifier extends StateNotifier<FeedState> {
  final IPostRepository _repo;
  final LocationService _locationService;
  final MediaUploadService _mediaUpload;
  RealtimeChannel? _realtimeChannel;
  int _currentPage = 1;
  bool _isReacting = false;

  PostNotifier(this._repo, this._locationService, this._mediaUpload)
      : super(const FeedState());

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final posts = await _repo.getNearbyPosts(
          pos, AppConstants.proximityRadiusMeters,
          page: 1);
      final total = await _repo
          .getNearbyPostsCount(pos, AppConstants.proximityRadiusMeters);
      final userReactions = await _fetchUserReactions();
      final hiddenIds = await _repo.getHiddenPostIds();
      _currentPage = 1;
      state = FeedState(
        posts: posts,
        hasMore: posts.length < total,
        userReactions: userReactions,
        hiddenPostIds: hiddenIds,
      );
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
      final newPosts = await _repo.getNearbyPosts(
          pos, AppConstants.proximityRadiusMeters,
          page: _currentPage);
      final total = await _repo
          .getNearbyPostsCount(pos, AppConstants.proximityRadiusMeters);
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
              debugPrint('Realtime feed refresh error: $e');
            }
          },
        )
        .subscribe();
  }

  Future<int> createPost(String content, String? contextTag,
      {List<File>? mediaFiles, String? stickerId}) async {
    final pos = await _locationService.initializeLocation();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    List<String> mediaUrls = [];
    String mediaType = 'text';

    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      final firstFile = mediaFiles.first.path.toLowerCase();
      if (firstFile.endsWith('.mp4') ||
          firstFile.endsWith('.mov') ||
          firstFile.endsWith('.avi')) {
        mediaType = 'video';
      } else {
        mediaType = 'image';
      }
      mediaUrls = await _mediaUpload.uploadPostMedia(
          files: mediaFiles, userId: user.id);
    }

    final post = PostModel(
      id: '',
      userId: user.id,
      content: content,
      latitude: pos.latitude,
      longitude: pos.longitude,
      mediaUrls: mediaUrls,
      mediaType: mediaType == 'video'
          ? MediaType.video
          : (mediaUrls.isNotEmpty ? MediaType.image : MediaType.text),
      contextTag: contextTag,
      stickerId: stickerId,
    );
    await _repo.createPost(post);
    await loadFeed();
    return 10;
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
        posts: state.posts
            .map((p) => p.id == postId ? p.copyWith(content: content) : p)
            .toList(),
      );
    } catch (e) {
      debugPrint('PostProvider editPost error: $e');
    }
  }

  // ── Hide / Unhide ────────────────────────────────────────────
  void hidePost(String postId) {
    final updated = {...state.hiddenPostIds, postId};
    state = state.copyWith(hiddenPostIds: updated);
    _repo.hidePost(postId).catchError((e) {
      debugPrint('hidePost error: $e');
      final reverted = {...state.hiddenPostIds}..remove(postId);
      state = state.copyWith(hiddenPostIds: reverted);
    });
  }

  void unhidePost(String postId) {
    final updated = {...state.hiddenPostIds}..remove(postId);
    state = state.copyWith(hiddenPostIds: updated);
    _repo.unhidePost(postId).catchError((e) {
      debugPrint('unhidePost error: $e');
      final reverted = {...state.hiddenPostIds, postId};
      state = state.copyWith(hiddenPostIds: reverted);
    });
  }

  // ── Reactions ────────────────────────────────────────────────
  Future<int> reactToPost(String postId, String reactionType) async {
    if (_isReacting) return 0;
    _isReacting = true;

    _optimisticallyUpdateReaction(postId, reactionType, 1);
    state = state.copyWith(
      userReactions:
          _updateUserReaction(state.userReactions, postId, reactionType, true),
    );

    try {
      await _repo.reactToPost(postId, reactionType);
      return 2;
    } catch (_) {
      _optimisticallyUpdateReaction(postId, reactionType, -1);
      state = state.copyWith(
        userReactions: _updateUserReaction(
            state.userReactions, postId, reactionType, false),
      );
      return 0;
    } finally {
      _isReacting = false;
    }
  }

  Future<void> removeReaction(String postId, String reactionType) async {
    if (_isReacting) return;
    _isReacting = true;

    _optimisticallyUpdateReaction(postId, reactionType, -1);
    state = state.copyWith(
      userReactions: _updateUserReaction(
          state.userReactions, postId, reactionType, false),
    );

    try {
      await _repo.removeReaction(postId, reactionType);
    } catch (_) {
      _optimisticallyUpdateReaction(postId, reactionType, 1);
      state = state.copyWith(
        userReactions: _updateUserReaction(
            state.userReactions, postId, reactionType, true),
      );
    } finally {
      _isReacting = false;
    }
  }

  Map<String, Set<String>> _updateUserReaction(
    Map<String, Set<String>> reactions,
    String postId,
    String reactionType,
    bool add,
  ) {
    final updated = Map<String, Set<String>>.from(reactions);
    final existing = updated[postId]?.toSet() ?? <String>{};
    if (add) {
      existing.add(reactionType);
    } else {
      existing.remove(reactionType);
    }
    if (existing.isEmpty) {
      updated.remove(postId);
    } else {
      updated[postId] = existing;
    }
    return updated;
  }

  void _optimisticallyUpdateReaction(
      String postId, String reactionType, int delta) {
    state = state.copyWith(
      posts: state.posts.map((p) {
        if (p.id != postId) return p;
        final newCounts = Map<String, int>.from(p.reactionCounts);
        final current = newCounts[reactionType] ?? 0;
        final newVal = current + delta;
        if (newVal <= 0) {
          newCounts.remove(reactionType);
        } else {
          newCounts[reactionType] = newVal;
        }
        return p.copyWith(reactionCounts: newCounts);
      }).toList(),
    );
  }

  Future<Map<String, Set<String>>> _fetchUserReactions() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.rpc('get_user_reactions');
      final userReactions = <String, Set<String>>{};
      for (final row in response) {
        final postId = row['post_id'] as String;
        final reactionType = row['reaction_type'] as String;
        userReactions.putIfAbsent(postId, () => <String>{}).add(reactionType);
      }
      return userReactions;
    } catch (e) {
      debugPrint('PostProvider _fetchUserReactions error: $e');
      return {};
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

final postProvider =
    StateNotifierProvider<PostNotifier, FeedState>((ref) {
  return PostNotifier(
    ref.watch(postRepositoryProvider),
    ref.watch(locationServiceProvider),
    ref.watch(mediaUploadServiceProvider),
  );
});
