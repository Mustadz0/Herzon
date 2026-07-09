import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/post_model.dart';
import '../data/repositories/post_repository.dart';
import '../core/constants/app_constants.dart';

class FeedState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

class FeedService {
  final IPostRepository _repo;
  FeedService(this._repo);

  Future<FeedState> fetchNearbyPosts(LatLng location, {double? radius}) async {
    try {
      final posts = await _repo.getNearbyPosts(
        location,
        radius ?? AppConstants.proximityRadiusMeters,
      );
      return FeedState(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= AppConstants.feedPageSize,
      );
    } catch (e) {
      return FeedState(error: e.toString());
    }
  }
}

final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService(ref.watch(postRepositoryProvider));
});
