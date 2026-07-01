import 'dart:io';
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
  final String? error;

  const FeedState({this.posts = const [], this.isLoading = false, this.error});

  FeedState copyWith({List<PostModel>? posts, bool? isLoading, String? error}) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PostNotifier extends StateNotifier<FeedState> {
  final IPostRepository _repo;
  final LocationService _locationService;
  final MediaUploadService _mediaUpload;
  RealtimeChannel? _realtimeChannel;

  PostNotifier(this._repo, this._locationService, this._mediaUpload) : super(const FeedState());

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final posts = await _repo.getNearbyPosts(pos, AppConstants.proximityRadiusMeters);
      state = FeedState(posts: posts);
      _subscribeRealtime();
    } catch (e) {
      state = FeedState(error: e.toString());
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
            await loadFeed();
          },
        )
        .subscribe();
  }

  Future<void> createPost(String content, String? contextTag, {List<File>? mediaFiles}) async {
    final pos = await _locationService.initializeLocation();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    List<String> mediaUrls = [];

    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      mediaUrls = await _mediaUpload.uploadPostMedia(files: mediaFiles, userId: user.id);
    }

    final post = PostModel(
      id: '',
      userId: user.id,
      content: content,
      latitude: pos.latitude,
      longitude: pos.longitude,
      mediaUrls: mediaUrls,
      mediaType: mediaUrls.isNotEmpty ? MediaType.image : MediaType.text,
      contextTag: contextTag,
    );
    await _repo.createPost(post);
    await loadFeed();
  }

  Future<void> deletePost(String postId) async {
    try {
      await _repo.deletePost(postId);
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
      );
    } catch (_) {}
  }

  Future<void> editPost(String postId, String content) async {
    try {
      await _repo.updatePost(postId, content);
      state = state.copyWith(
        posts: state.posts.map((p) =>
          p.id == postId ? PostModel(id: p.id, userId: p.userId, content: content, latitude: p.latitude, longitude: p.longitude, mediaUrls: p.mediaUrls, mediaType: p.mediaType, contextTag: p.contextTag, reactionCounts: p.reactionCounts, createdAt: p.createdAt, userUsername: p.userUsername, userDisplayName: p.userDisplayName, userAvatarUrl: p.userAvatarUrl, distanceMeters: p.distanceMeters, commentCount: p.commentCount) : p
        ).toList(),
      );
    } catch (_) {}
  }

  Future<void> reactToPost(String postId, String reactionType) async {
    try {
      await _repo.reactToPost(postId, reactionType);
    } catch (_) {}
  }

  Future<void> removeReaction(String postId, String reactionType) async {
    try {
      await _repo.removeReaction(postId, reactionType);
    } catch (_) {}
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
