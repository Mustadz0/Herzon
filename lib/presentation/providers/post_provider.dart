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

  PostNotifier(this._repo, this._locationService, this._mediaUpload) : super(const FeedState());

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pos = await _locationService.initializeLocation();
      final posts = await _repo.getNearbyPosts(pos, AppConstants.proximityRadiusMeters);
      state = FeedState(posts: posts);
    } catch (e) {
      state = FeedState(error: e.toString());
    }
  }

  Future<void> createPost(String content, String? contextTag, {List<File>? mediaFiles}) async {
    final pos = await _locationService.initializeLocation();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    List<String> mediaUrls = [];
    String mediaType = 'text';

    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      mediaUrls = await _mediaUpload.uploadPostMedia(files: mediaFiles, userId: user.id);
      mediaType = 'image';
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
}

final postProvider = StateNotifierProvider<PostNotifier, FeedState>((ref) {
  return PostNotifier(
    ref.watch(postRepositoryProvider),
    ref.watch(locationServiceProvider),
    ref.watch(mediaUploadServiceProvider),
  );
});


